import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'library_database_service.dart';
import 'recommendation_service.dart';
import 'statistics_service.dart';
import 'storage_service.dart';

/// Non-persistent model representing the progress of a quest instance.
class MusicQuestProgress {
  final double currentValue;
  final double targetValue;
  final bool isCompleted;
  final double percent;

  MusicQuestProgress({
    required this.currentValue,
    required this.targetValue,
  })  : isCompleted = currentValue >= targetValue,
        percent = (targetValue > 0 ? (currentValue / targetValue) : 0.0).clamp(0.0, 1.0).toDouble();
}

/// Represents a period range [start, end).
class MusicQuestPeriodRange {
  final DateTime start;
  final DateTime end;
  MusicQuestPeriodRange(this.start, this.end);
}

class MusicQuestService {
  final LibraryDatabaseService _dbService;
  final RecommendationService _recommendationService;
  final StatisticsService _statsService;

  StreamSubscription? _eventSubscription;
  final _questUpdatedController = StreamController<MusicQuestInstance>.broadcast();

  /// Observable stream of quest updates (progress or completion).
  Stream<MusicQuestInstance> get onQuestUpdated => _questUpdatedController.stream;

  List<MusicQuestInstance> _activeQuests = [];

  /// Static definitions for V1 quêtes.
  static const List<MusicQuestDefinition> _v1Definitions = [
    MusicQuestDefinition(
      id: 'daily_listener',
      title: 'Mélomane quotidien',
      description: 'Écouter 30 minutes de musique aujourd\'hui',
      category: QuestCategory.volume,
      periodType: QuestPeriodType.daily,
      criterion: QuestCriterion.listeningTime,
      targetValue: 1800, // 30 minutes in seconds
    ),
    MusicQuestDefinition(
      id: 'daily_explorer',
      title: 'Explorateur quotidien',
      description: 'Écouter 3 artistes différents aujourd\'hui',
      category: QuestCategory.diversity,
      periodType: QuestPeriodType.daily,
      criterion: QuestCriterion.distinctArtist,
      targetValue: 3,
    ),
    MusicQuestDefinition(
      id: 'daily_finisher',
      title: 'Finisseur quotidien',
      description: 'Terminer 5 morceaux aujourd\'hui',
      category: QuestCategory.discipline,
      periodType: QuestPeriodType.daily,
      criterion: QuestCriterion.completionCount,
      targetValue: 5,
    ),
    MusicQuestDefinition(
      id: 'daily_discovery',
      title: 'Nouveaux Horizons',
      description: 'Découvrir 3 nouveaux morceaux aujourd\'hui',
      category: QuestCategory.discovery,
      periodType: QuestPeriodType.daily,
      criterion: QuestCriterion.discoveryCount,
      targetValue: 3,
    ),
    MusicQuestDefinition(
      id: 'weekly_loyalty',
      title: 'Fidélité hebdo',
      description: 'Écouter de la musique 3 jours différents cette semaine',
      category: QuestCategory.temporal,
      periodType: QuestPeriodType.weekly,
      criterion: QuestCriterion.activeDayCount,
      targetValue: 3,
    ),
  ];

  MusicQuestService(
    this._dbService,
    this._recommendationService,
    this._statsService,
  );

  bool _isInitialized = false;

  /// Returns true if the service has completed its initial load and setup.
  bool get isInitialized => _isInitialized;

  /// Initializes the service: loads instances, manages lifecycle, and starts listening to events.
  Future<void> initialize() async {
    if (_eventSubscription != null) return;

    try {
      // 1. Load active instances from DB
      _activeQuests = await _dbService.getActiveQuestInstances();

      // 2. Lifecycle management: expire past quests and generate current ones
      await _refreshInstances();

      // 3. Initial check for completions
      await _checkAllActiveQuests();

      // 4. Subscribe to playback events for real-time updates
      _eventSubscription = _recommendationService.playbackEvents.listen((event) {
        _handlePlaybackEvent(event);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('MusicQuestService: Initialization failed: $e');
      // Keep _isInitialized as false so UI can show error or retry
    }
  }

  /// Returns the current period range [start, end) for a given type.
  MusicQuestPeriodRange getCurrentPeriodRange(QuestPeriodType type) {
    return _getPeriodRange(type, DateTime.now());
  }

  /// Returns current active quest instances.
  List<MusicQuestInstance> getActiveQuests() => List.unmodifiable(_activeQuests);

  /// Returns recently completed quest instances.
  Future<List<MusicQuestInstance>> getCompletedQuests() async {
    final all = await _dbService.getQuestInstances();
    return all.where((i) => i.status == QuestStatus.completed).toList();
  }

  /// Optimized method to fetch progress for all active quests.
  /// Minimizes database queries by sharing period statistics.
  Future<Map<String, MusicQuestProgress>> getAllActiveProgress() async {
    final Map<String, MusicQuestProgress> results = {};
    final active = List<MusicQuestInstance>.from(_activeQuests);

    // Cache for PeriodStats to avoid redundant queries for quêtes sharing the same range
    final Map<String, PeriodStats> periodStatsCache = {};

    for (final instance in active) {
      final definition =
          _v1Definitions.firstWhere((d) => d.id == instance.definitionId);
      final rangeKey =
          "${instance.periodStart.millisecondsSinceEpoch}_${instance.periodEnd.millisecondsSinceEpoch}";

      double currentValue = 0;

      switch (definition.criterion) {
        case QuestCriterion.listeningTime:
        case QuestCriterion.playCount:
        case QuestCriterion.completionCount:
          final stats = periodStatsCache[rangeKey] ??=
              await _statsService.getPeriodStats(
            start: instance.periodStart,
            end: instance.periodEnd,
          );
          if (definition.criterion == QuestCriterion.listeningTime) {
            currentValue = stats.totalListenTime.toDouble();
          } else if (definition.criterion == QuestCriterion.playCount) {
            currentValue = stats.totalPlayCount.toDouble();
          } else {
            currentValue = stats.totalCompletionCount.toDouble();
          }
          break;
        case QuestCriterion.distinctArtist:
          currentValue = (await _statsService.getDistinctArtistCount(
            start: instance.periodStart,
            end: instance.periodEnd,
          ))
              .toDouble();
          break;
        case QuestCriterion.distinctAlbum:
          currentValue = (await _statsService.getDistinctAlbumCount(
            start: instance.periodStart,
            end: instance.periodEnd,
          ))
              .toDouble();
          break;
        case QuestCriterion.distinctGenre:
          currentValue = (await _statsService.getDistinctGenreCount(
            start: instance.periodStart,
            end: instance.periodEnd,
          ))
              .toDouble();
          break;
        case QuestCriterion.discoveryCount:
          currentValue = (await _statsService.getDiscoveryCount(
            start: instance.periodStart,
            end: instance.periodEnd,
          ))
              .toDouble();
          break;
        case QuestCriterion.activeDayCount:
          currentValue = (await _statsService.getActiveDayCount(
            start: instance.periodStart,
            end: instance.periodEnd,
          ))
              .toDouble();
          break;
      }

      results[instance.definitionId] = MusicQuestProgress(
        currentValue: currentValue,
        targetValue: definition.targetValue,
      );
    }

    return results;
  }

  /// Recalculates the progress of a given quest instance.
  /// Does NOT hit the database, uses [StatisticsService] and [RecommendationService].
  Future<MusicQuestProgress> getQuestProgress(MusicQuestInstance instance) async {
    final definition = _v1Definitions.firstWhere((d) => d.id == instance.definitionId);
    
    double currentValue = 0;
    
    switch (definition.criterion) {
      case QuestCriterion.listeningTime:
        final stats = await _statsService.getPeriodStats(
          start: instance.periodStart,
          end: instance.periodEnd,
        );
        currentValue = stats.totalListenTime.toDouble();
        break;
      case QuestCriterion.playCount:
        final stats = await _statsService.getPeriodStats(
          start: instance.periodStart,
          end: instance.periodEnd,
        );
        currentValue = stats.totalPlayCount.toDouble();
        break;
      case QuestCriterion.completionCount:
        final stats = await _statsService.getPeriodStats(
          start: instance.periodStart,
          end: instance.periodEnd,
        );
        currentValue = stats.totalCompletionCount.toDouble();
        break;
      case QuestCriterion.distinctArtist:
        currentValue = (await _statsService.getDistinctArtistCount(
          start: instance.periodStart,
          end: instance.periodEnd,
        )).toDouble();
        break;
      case QuestCriterion.distinctAlbum:
        currentValue = (await _statsService.getDistinctAlbumCount(
          start: instance.periodStart,
          end: instance.periodEnd,
        )).toDouble();
        break;
      case QuestCriterion.distinctGenre:
        currentValue = (await _statsService.getDistinctGenreCount(
          start: instance.periodStart,
          end: instance.periodEnd,
        )).toDouble();
        break;
      case QuestCriterion.discoveryCount:
        currentValue = (await _statsService.getDiscoveryCount(
          start: instance.periodStart,
          end: instance.periodEnd,
        )).toDouble();
        break;
      case QuestCriterion.activeDayCount:
        currentValue = (await _statsService.getActiveDayCount(
          start: instance.periodStart,
          end: instance.periodEnd,
        )).toDouble();
        break;
    }

    return MusicQuestProgress(
      currentValue: currentValue,
      targetValue: definition.targetValue,
    );
  }

  /// Manages transition between active, completed and expired status.
  bool _isRefreshing = false;
  Future<void> _refreshInstances() async {
    if (_isRefreshing) return;

    // Check if gamification is enabled
    if (!(await StorageService().getGamificationEnabled())) return;

    _isRefreshing = true;
    try {
      final now = DateTime.now();

      // 1. Expire outdated active quests
      final toExpire = _activeQuests
          .where((i) =>
              now.isAtSameMomentAs(i.periodEnd) || now.isAfter(i.periodEnd))
          .toList();
      for (final instance in toExpire) {
        // Final check: maybe it was completed at the last second
        final progress = await getQuestProgress(instance);
        if (progress.isCompleted) {
          await _completeQuest(instance);
        } else {
          await _dbService.updateQuestInstanceStatus(
              instance.id!, QuestStatus.expired);
        }
        _activeQuests.removeWhere((i) => i.id == instance.id);
      }

      // 2. Generate missing instances for the current periods
      for (final def in _v1Definitions) {
        final period = _getPeriodRange(def.periodType, now);

        final exists = _activeQuests.any((i) =>
            i.definitionId == def.id &&
            i.periodStart.isAtSameMomentAs(period.start) &&
            i.periodEnd.isAtSameMomentAs(period.end));

        if (!exists) {
          // Double check DB in case it's already completed or marked expired
          final dbInstances = await _dbService.getQuestInstancesByPeriod(
              period.start, period.end);
          if (!dbInstances.any((i) => i.definitionId == def.id)) {
            final newInstance = MusicQuestInstance(
              definitionId: def.id,
              periodStart: period.start,
              periodEnd: period.end,
              status: QuestStatus.active,
            );
            final id = await _dbService.insertQuestInstance(newInstance);
            _activeQuests.add(newInstance.copyWith(id: id));
          }
        }
      }
    } finally {
      _isRefreshing = false;
    }
  }

  bool _isChecking = false;
  bool _checkPending = false;

  Future<void> _checkAllActiveQuests() async {
    if (_isChecking) {
      _checkPending = true;
      return;
    }
    _isChecking = true;

    try {
      final activeList = List<MusicQuestInstance>.from(_activeQuests);
      for (final instance in activeList) {
        final progress = await getQuestProgress(instance);
        if (progress.isCompleted) {
          await _completeQuest(instance);
        } else {
          // Just notify update if UI needs to know about progress
          _questUpdatedController.add(instance);
        }
      }
    } finally {
      _isChecking = false;
      if (_checkPending) {
        _checkPending = false;
        // Schedule next check for the next microtask to avoid potential stack overflow
        // and allow other async operations to breathe.
        scheduleMicrotask(_checkAllActiveQuests);
      }
    }
  }

  Future<void> _completeQuest(MusicQuestInstance instance) async {
    final now = DateTime.now();
    
    // Optimistic update of local state to avoid double-processing during async DB call
    _activeQuests.removeWhere((i) => i.id == instance.id);
    
    await _dbService.updateQuestInstanceStatus(instance.id!, QuestStatus.completed, completedAt: now);
    
    final updated = instance.copyWith(status: QuestStatus.completed, completedAt: now);
    _questUpdatedController.add(updated);
  }

  Future<void> _handlePlaybackEvent(PlaybackEvent event) async {
    // Check if gamification is enabled
    if (!(await StorageService().getGamificationEnabled())) return;

    // For V1, we simply re-check all active quests on any relevant event.
    // Reliability over micro-optimization.
    _checkAllActiveQuests();
    
    // Periodically refresh instances to handle day/week transitions
    _refreshInstances();
  }

  /// Centralized period logic.
  /// [start, end) convention.
  MusicQuestPeriodRange _getPeriodRange(QuestPeriodType type, DateTime now) {
    switch (type) {
      case QuestPeriodType.daily:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 1));
        return MusicQuestPeriodRange(start, end);
        
      case QuestPeriodType.weekly:
        // DateTime.weekday: 1 = Monday, 7 = Sunday
        final daysToMonday = now.weekday - 1;
        final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToMonday));
        final end = start.add(const Duration(days: 7));
        return MusicQuestPeriodRange(start, end);

      case QuestPeriodType.lifetime:
        return MusicQuestPeriodRange(DateTime(2000), DateTime(2100));
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _questUpdatedController.close();
  }
}
