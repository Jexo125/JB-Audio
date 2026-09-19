import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'library_database_service.dart';
import 'recommendation_service.dart';
import 'music_quest_service.dart';
import 'statistics_service.dart';
import 'storage_service.dart';

/// Service responsible for managing user XP and progression.
/// Follows a passive consumer pattern, listening to playback events.
class XpService extends ChangeNotifier {
  final LibraryDatabaseService _dbService;
  final RecommendationService _recommendationService;
  final MusicQuestService _questService;
  final StatisticsService _statsService;

  StreamSubscription? _playbackSubscription;
  StreamSubscription? _questSubscription;
  final _xpUpdateController = StreamController<UserProgression>.broadcast();
  final _snapshotUpdateController = StreamController<ProgressionSnapshot>.broadcast();

  bool _isEnabled = true;
  bool _isInitialized = false;
  UserProgression _progression = const UserProgression();
  final List<UnlockedTitle> _unlockedTitles = [];

  /// Map to track if a song has been validated in the current session.
  /// This ensures 'completed' XP is only given if 'play_validated' was seen.
  final Set<String> _validatedInSession = {};

  /// Returns true if the service has loaded the initial progression from the database.
  bool get isInitialized => _isInitialized;

  /// Returns true if gamification is enabled.
  bool get isEnabled => _isEnabled;

  /// Returns the current user progression snapshot (raw).
  UserProgression get progression => _progression;

  /// Returns the current user level and progression status.
  ProgressionSnapshot get snapshot => ProgressionSnapshot.fromTotalXp(_progression.totalXp);

  /// Returns all title snapshots (available and unlocked state).
  List<TitleSnapshot> getTitleSnapshots() {
    return TitleDefinition.v1Titles.map((def) {
      final unlocked = _unlockedTitles.firstWhere(
        (t) => t.id == def.id, 
        orElse: () => UnlockedTitle(id: '', unlockedAt: DateTime.now()),
      );
      return TitleSnapshot(
        definition: def,
        isUnlocked: unlocked.id.isNotEmpty,
        unlockedAt: unlocked.id.isNotEmpty ? unlocked.unlockedAt : null,
      );
    }).toList();
  }

  /// Observable stream of progression updates.
  Stream<UserProgression> get onProgressionUpdated => _xpUpdateController.stream;

  /// Observable stream of level and progression snapshot updates.
  Stream<ProgressionSnapshot> get onSnapshotUpdated => _snapshotUpdateController.stream;

  XpService(this._dbService, this._recommendationService, this._questService, this._statsService);

  /// Initializes the service by loading data and subscribing to events.
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 0. Load enabled state
    _isEnabled = await StorageService().getGamificationEnabled();

    // 1. Load current progression from DB
    _progression = await _dbService.getUserProgression();
    
    // 2. Load unlocked titles
    final titleMaps = await _dbService.getUnlockedTitles();
    _unlockedTitles.clear();
    for (final m in titleMaps) {
      _unlockedTitles.add(UnlockedTitle(
        id: m['title_key'] as String,
        unlockedAt: DateTime.parse(m['unlocked_at'] as String),
      ));
    }

    _isInitialized = true;
    
    // Notify initial state
    _xpUpdateController.add(_progression);
    _snapshotUpdateController.add(snapshot);

    // Initial check for titles in case some were missed
    await checkTitles();

    // 3. Subscribe to playback events
    _playbackSubscription = _recommendationService.playbackEvents.listen((event) {
      _handlePlaybackEvent(event);
    });

    // 4. Subscribe to quest updates
    _questSubscription = _questService.onQuestUpdated.listen((quest) {
      _handleQuestEvent(quest);
    });
  }

  /// Entry point for all playback events.
  Future<void> _handlePlaybackEvent(PlaybackEvent event) async {
    if (!_isInitialized || !_isEnabled) return;

    switch (event.eventType) {
      case 'time_added':
        await _processTimeAdded(event.duration);
        break;
      case 'play_validated':
        _validatedInSession.add(event.songId);
        await _processEventXp(
          type: 'val',
          sourceId: "val_${event.songId}_${event.timestamp.millisecondsSinceEpoch}",
          amount: UserProgression.xpPlayValidated,
        );
        if (event.isDiscovery) {
          await _processEventXp(
            type: 'disco',
            sourceId: "disco_${event.songId}",
            amount: UserProgression.xpDiscoveryBonus,
          );
        }
        break;
      case 'completed':
        if (_validatedInSession.contains(event.songId)) {
          await _processEventXp(
            type: 'comp',
            sourceId: "comp_${event.songId}_${event.timestamp.millisecondsSinceEpoch}",
            amount: UserProgression.xpSongCompleted,
          );
          // Check for titles after completion
          unawaited(checkTitles());
        }
        break;
      case 'skipped':
        _validatedInSession.remove(event.songId);
        break;
    }
  }

  /// Handles quest completion events.
  Future<void> _handleQuestEvent(MusicQuestInstance quest) async {
    if (!_isInitialized || quest.status != QuestStatus.completed || !_isEnabled) return;

    // Determine amount based on definition
    // For V1, daily quests are everything except weekly_loyalty
    int amount = UserProgression.xpDailyQuestBonus;
    if (quest.definitionId == 'weekly_loyalty') {
      amount = UserProgression.xpWeeklyQuestBonus;
    }

    await _processEventXp(
      type: 'quest',
      sourceId: "quest_${quest.id}",
      amount: amount,
    );
    
    // Check for titles after quest completion (e.g. active days)
    unawaited(checkTitles());
  }

  /// Sets whether gamification is enabled.
  Future<void> setEnabled(bool value) async {
    if (_isEnabled == value) return;
    _isEnabled = value;
    await StorageService().saveGamificationEnabled(value);
    
    // If re-enabled, trigger a title check to catch up on any milestones
    if (_isEnabled) {
      unawaited(checkTitles());
    }
    
    notifyListeners();
  }

  bool _isCheckingTitles = false;

  /// Manually triggers a check for new titles based on current statistics.
  Future<void> checkTitles() async {
    if (!_isInitialized || _isCheckingTitles || !_isEnabled) return;
    _isCheckingTitles = true;

    try {
      final globalStats = await _statsService.getGlobalStats();
      final activeDays = await _statsService.getActiveDayCount(start: DateTime(2000), end: DateTime(2100));
      final artistCount = await _statsService.getDistinctArtistCount();
      final albumCount = await _statsService.getDistinctAlbumCount();
      final discoveryCount = await _statsService.getDiscoveryCount(start: DateTime(2000), end: DateTime(2100));

      final now = DateTime.now();
      bool newlyUnlocked = false;

      for (final def in TitleDefinition.v1Titles) {
        if (_unlockedTitles.any((t) => t.id == def.id)) continue;

        double currentValue = 0;
        switch (def.type) {
          case TitleType.listenTime:
            currentValue = globalStats.totalListenTime.toDouble();
            break;
          case TitleType.artistCount:
            currentValue = artistCount.toDouble();
            break;
          case TitleType.albumCount:
            currentValue = albumCount.toDouble();
            break;
          case TitleType.completionCount:
            currentValue = globalStats.totalCompleted.toDouble();
            break;
          case TitleType.discoveryCount:
            currentValue = discoveryCount.toDouble();
            break;
          case TitleType.activeDays:
            currentValue = activeDays.toDouble();
            break;
        }

        if (currentValue >= def.threshold) {
          await _dbService.insertUnlockedTitle(def.id, now.toIso8601String());
          _unlockedTitles.add(UnlockedTitle(id: def.id, unlockedAt: now));
          newlyUnlocked = true;
          debugPrint('[XpService] Unlocked title: ${def.id}');
        }
      }

      if (newlyUnlocked) {
        notifyListeners();
      }
    } finally {
      _isCheckingTitles = false;
    }
  }

  /// Processes an event-based XP gain with idempotence.
  Future<void> _processEventXp({
    required String type,
    required String sourceId,
    required int amount,
  }) async {
    final credited = await _dbService.creditEventXp(
      type: type,
      sourceId: sourceId,
      amount: amount,
    );

    if (credited) {
      _progression = _progression.copyWith(
        totalXp: _progression.totalXp + amount,
      );
      _xpUpdateController.add(_progression);
      _snapshotUpdateController.add(snapshot);
      notifyListeners();
    }
  }

  /// Internal logic to apply the 1 XP / 60 seconds rule.
  /// This method is serialized by the execution flow to prevent lost updates.
  Future<void> _processTimeAdded(int seconds) async {
    if (seconds <= 0 || !_isEnabled) return;

    final int totalSeconds = _progression.pendingSeconds + seconds;
    final int xpToAdd = totalSeconds ~/ 60;
    final int remainingSeconds = totalSeconds % 60;

    if (xpToAdd > 0 || remainingSeconds != _progression.pendingSeconds) {
      _progression = _progression.copyWith(
        totalXp: _progression.totalXp + xpToAdd,
        pendingSeconds: remainingSeconds,
      );

      // Persist immediately to avoid data loss on crash
      await _dbService.updateUserProgression(_progression);
      
      // Notify listeners (UI and other services)
      _xpUpdateController.add(_progression);
      _snapshotUpdateController.add(snapshot);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _questSubscription?.cancel();
    _xpUpdateController.close();
    _snapshotUpdateController.close();
    super.dispose();
  }
}
