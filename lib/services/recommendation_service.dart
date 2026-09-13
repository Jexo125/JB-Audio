import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/models.dart';
import 'library_database_service.dart';

abstract class _W {
  static const double artistAffinity = 0.28;
  static const double genreAffinity = 0.18;
  static const double artistRating = 0.11;
  static const double genreRating = 0.07;
  static const double albumAffinity = 0.06;
  static const double completionRate = 0.09;
  static const double hourPreference = 0.05;
  static const double playCountSignal = 0.04;
  static const double userRating = 0.10;
  static const double songLevelRating = 0.06;
  static const double starBonus = 0.20;
  static const double noveltyBonus = 0.08;
  static const double skipPenaltyPerSkip = 0.06;
  static const double maxSkipPenalty = 0.35;
  static const double recencyPenaltyStep = 0.015;
  static const double timePatternsBonus = 0.05;
  static const double randomJitter = 0.12;
}

const _kDecayHalfLifeDays = 30.0;

class RecommendationService extends ChangeNotifier {
  static const _kDataKey = 'rec_data_v3';
  static const _kSkipKey = 'rec_skips_v3';
  static const _kTimeKey = 'rec_time_v3';
  static const _kEnabledKey = 'recommendations_enabled';
  static const _kDecayKey = 'rec_decay_ts';

  bool _enabled = true;

  SharedPreferences? _prefs;
  String? _userSuffix;

  Map<String, SongProfile> _profiles = {};
  Map<String, double> _artistAffinity = {};
  Map<String, double> _genreAffinity = {};
  Map<String, double> _albumAffinity = {};
  Map<String, double> _artistRatingAffinity = {};
  Map<String, double> _genreRatingAffinity = {};
  Map<String, int> _skipCounts = {};
  Map<int, Map<String, double>> _timePatterns = {};
  List<String> _recentlyPlayed = [];
  Set<String> _starredSongs = {};

  final Map<String, int> _recentIndex = {};

  DateTime _lastDecayApplied = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _saveTimer;
  static const _kSaveDebounceMs = 800;

  double? _maxArtistAffinity;
  double? _maxGenreAffinity;
  double? _maxAlbumAffinity;
  double? _maxArtistRating;
  double? _maxGenreRating;

  bool get enabled => _enabled;
  Map<String, SongProfile> get profiles => Map.unmodifiable(_profiles);
  List<String> get recentlyPlayed => List.unmodifiable(_recentlyPlayed);

  final _playbackEventController = StreamController<PlaybackEvent>.broadcast();
  Stream<PlaybackEvent> get playbackEvents => _playbackEventController.stream;
  LibraryDatabaseService _dbService = LibraryDatabaseService();

  @visibleForTesting
  set dbService(LibraryDatabaseService service) => _dbService = service;

  Future<void> initialize({String? serverUrl, String? username}) async {
    _prefs = await SharedPreferences.getInstance();
    
    if (serverUrl != null && username != null) {
      final key = '${serverUrl}_$username';
      _userSuffix = md5.convert(utf8.encode(key)).toString();
      
      // Check for migration
      final migrationKey = 'rec_migrated_$_userSuffix';
      if (!(_prefs!.getBool(migrationKey) ?? false)) {
        await _migrateGlobalToUser();
        await _prefs!.setBool(migrationKey, true);
      }
    } else {
      _userSuffix = null;
    }

    _enabled = _prefs!.getBool(_kEnabledKey) ?? true;
    await _loadAllData();
    _applyDecay();
    notifyListeners();
  }

  Future<void> _migrateGlobalToUser() async {
    if (_userSuffix == null) return;
    
    final globalData = _prefs!.getString(_kDataKey);
    final globalSkips = _prefs!.getString(_kSkipKey);
    final globalTime = _prefs!.getString(_kTimeKey);
    final globalDecay = _prefs!.getInt(_kDecayKey);

    if (globalData != null) {
      final userKey = '${_kDataKey}_$_userSuffix';
      if (!_prefs!.containsKey(userKey)) {
        await _prefs!.setString(userKey, globalData);
      }
    }
    if (globalSkips != null) {
      final userKey = '${_kSkipKey}_$_userSuffix';
      if (!_prefs!.containsKey(userKey)) {
        await _prefs!.setString(userKey, globalSkips);
      }
    }
    if (globalTime != null) {
      final userKey = '${_kTimeKey}_$_userSuffix';
      if (!_prefs!.containsKey(userKey)) {
        await _prefs!.setString(userKey, globalTime);
      }
    }
    if (globalDecay != null) {
      final userKey = '${_kDecayKey}_$_userSuffix';
      if (!_prefs!.containsKey(userKey)) {
        await _prefs!.setInt(userKey, globalDecay);
      }
    }
    
    debugPrint('[Recommendation] Migrated global data to user $_userSuffix');
  }

  String _getKey(String baseKey) => _userSuffix != null ? '${baseKey}_$_userSuffix' : baseKey;

  @override
  void dispose() {
    _saveTimer?.cancel();
    _playbackEventController.close();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Settings
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _prefs?.setBool(_kEnabledKey, value);
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tracking
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> trackSongPlay(
    Song song, {
    int durationPlayed = 0,
    bool completed = false,
  }) async {
    final id = song.id;
    final hour = DateTime.now().hour;
    final now = DateTime.now();

    final profile = _profiles.putIfAbsent(
      id,
      () => SongProfile(
        songId: id,
        title: song.title,
        artist: song.artist,
        artistId: song.artistId,
        albumId: song.albumId,
        genre: song.genre,
        duration: song.duration,
      ),
    );
    profile.addPlay(
        durationPlayed: durationPlayed, completed: completed, hour: hour);

    _recentlyPlayed.remove(id);
    _recentlyPlayed.insert(0, id);
    if (_recentlyPlayed.length > 500) {
      _recentlyPlayed = _recentlyPlayed.sublist(0, 500);
    }
    _rebuildRecentIndex();

    final timestampStr = now.toIso8601String();
    _playbackEventController.add(PlaybackEvent(
      songId: id,
      timestamp: now,
      eventType: 'play_validated',
      duration: durationPlayed,
      completed: completed,
    ));
    _playbackEventController.add(PlaybackEvent(
      songId: id,
      timestamp: now,
      eventType: 'time_added',
      duration: durationPlayed,
      completed: false,
    ));

    // Note: 'play_validated' records the action.
    // We also record 'time_added' for this initial validated block.
    _dbService.insertListeningEvent(
      songId: id,
      eventType: 'play_validated',
      durationSeconds: durationPlayed,
      completed: completed ? 1 : 0,
      timestamp: timestampStr,
    );
    _dbService.insertListeningEvent(
      songId: id,
      eventType: 'time_added',
      durationSeconds: durationPlayed,
      completed: 0,
      timestamp: timestampStr,
    );

    if (completed) {
      _playbackEventController.add(PlaybackEvent(
        songId: id,
        timestamp: now,
        eventType: 'completed',
        duration: durationPlayed,
        completed: true,
      ));
      // Action only - no duration sum from this event.
      _dbService.insertListeningEvent(
        songId: id,
        eventType: 'completed',
        durationSeconds: durationPlayed,
        completed: 1,
        timestamp: timestampStr,
      );
    }

    if (_enabled) {
      final lw = _listenWeight(song, durationPlayed, completed: completed);

      if (song.artist != null) {
        _artistAffinity[song.artist!] =
            (_artistAffinity[song.artist!] ?? 0) + lw;
        _maxArtistAffinity = null;
      }
      if (song.genre != null) {
        _genreAffinity[song.genre!] =
            (_genreAffinity[song.genre!] ?? 0) + lw * 0.75;
        _maxGenreAffinity = null;
      }
      if (song.albumId != null) {
        _albumAffinity[song.albumId!] =
            (_albumAffinity[song.albumId!] ?? 0) + lw * 0.6;
        _maxAlbumAffinity = null;
      }

      _timePatterns.putIfAbsent(hour, () => {});
      if (song.genre != null) {
        _timePatterns[hour]![song.genre!] =
            (_timePatterns[hour]![song.genre!] ?? 0) + 1;
      }
    }

    _scheduleSave();
    notifyListeners();
  }

  /// Updates the status of the most recently tracked play to 'completed'.
  /// Used to apply the completion bonus after the initial 30s validation.
  Future<void> trackSongCompletion(Song song, {int durationPlayed = 0}) async {
    final id = song.id;
    final profile = _profiles[id];
    if (profile == null) return;

    // Safety: only update if it was the last song started and not already completed
    if (_recentlyPlayed.isEmpty || _recentlyPlayed.first != id) return;
    
    // Check if we already registered this as completed to avoid double counting
    if (profile.completedPlays < profile.playCount) {
      profile.completedPlays++;
      
      final now = DateTime.now();
      final timestampStr = now.toIso8601String();
      _playbackEventController.add(PlaybackEvent(
        songId: id,
        timestamp: now,
        eventType: 'completed',
        duration: durationPlayed,
        completed: true,
      ));
      // Action only - no duration sum from this event.
      _dbService.insertListeningEvent(
        songId: id,
        eventType: 'completed',
        durationSeconds: durationPlayed,
        completed: 1,
        timestamp: timestampStr,
      );

      if (_enabled) {
        // Apply the difference between a partial listen and a completed listen
        // Max weight is 1.5, partial (ratio > 0.8) is 1.3. 
        // We add a bonus to reflect this completion in affinities.
        const completionBonus = 0.5;

        if (song.artist != null) {
          _artistAffinity[song.artist!] =
              (_artistAffinity[song.artist!] ?? 0) + completionBonus;
          _maxArtistAffinity = null;
        }
        if (song.genre != null) {
          _genreAffinity[song.genre!] =
              (_genreAffinity[song.genre!] ?? 0) + completionBonus * 0.75;
          _maxGenreAffinity = null;
        }
      }
      
      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> trackIncrementalListenTime(Song song, int additionalSeconds) async {
    final id = song.id;
    final profile = _profiles[id];
    if (profile != null && additionalSeconds > 0) {
      profile.totalListenTime += additionalSeconds;

      final now = DateTime.now();
      final timestampStr = now.toIso8601String();

      // Journal temporal history (only time_added events are used for duration sums)
      final event = PlaybackEvent(
        songId: id,
        timestamp: now,
        eventType: 'time_added',
        duration: additionalSeconds,
        completed: false,
      );
      _playbackEventController.add(event);

      _dbService.insertListeningEvent(
        songId: id,
        eventType: 'time_added',
        durationSeconds: additionalSeconds,
        completed: 0,
        timestamp: timestampStr,
      );

      _scheduleSave();
      notifyListeners();
    }
  }

  Future<void> trackSkip(Song song, {int secondsPlayed = 0}) async {
    final id = song.id;
    final now = DateTime.now();
    final timestampStr = now.toIso8601String();

    _skipCounts[id] = (_skipCounts[id] ?? 0) + 1;

    final profile = _profiles.putIfAbsent(
      id,
      () => SongProfile(
        songId: id,
        title: song.title,
        artist: song.artist,
        artistId: song.artistId,
        albumId: song.albumId,
        genre: song.genre,
        duration: song.duration,
      ),
    );
    profile.skipCount++;

    _playbackEventController.add(PlaybackEvent(
      songId: id,
      timestamp: now,
      eventType: 'skipped',
      duration: secondsPlayed,
      completed: false,
    ));

    // Also record time_added for the portion listened before skip
    if (secondsPlayed > 0) {
      profile.totalListenTime += secondsPlayed;

      _playbackEventController.add(PlaybackEvent(
        songId: id,
        timestamp: now,
        eventType: 'time_added',
        duration: secondsPlayed,
        completed: false,
      ));

      _dbService.insertListeningEvent(
        songId: id,
        eventType: 'time_added',
        durationSeconds: secondsPlayed,
        completed: 0,
        timestamp: timestampStr,
      );
    }

    _dbService.insertListeningEvent(
      songId: id,
      eventType: 'skipped',
      durationSeconds: secondsPlayed,
      completed: 0,
      timestamp: timestampStr,
    );

    if (_enabled) {
      final earlyFactor = song.duration != null && song.duration! > 0
          ? 1.0 - (secondsPlayed / song.duration!).clamp(0.0, 1.0)
          : 1.0;
      final penalty = 0.3 * earlyFactor;

      if (song.artist != null) {
        _artistAffinity[song.artist!] =
            (_artistAffinity[song.artist!] ?? 0) - penalty;
        _maxArtistAffinity = null;
      }
      if (song.genre != null) {
        _genreAffinity[song.genre!] =
            (_genreAffinity[song.genre!] ?? 0) - penalty * 0.5;
        _maxGenreAffinity = null;
      }
    }

    _scheduleSave();
    notifyListeners();
  }

  Future<void> trackSongRating(Song song, int rating) async {
    if (rating < 1 || rating > 5) return;

    (_profiles[song.id] ??
            (_profiles[song.id] = SongProfile(
              songId: song.id,
              title: song.title,
              artist: song.artist,
              artistId: song.artistId,
              albumId: song.albumId,
              genre: song.genre,
              duration: song.duration,
            )))
        .userRating = rating;

    if (_enabled) {
      final signedWeight = (rating - 3) / 2.0;

      if (song.artist != null) {
        _artistRatingAffinity[song.artist!] =
            (_artistRatingAffinity[song.artist!] ?? 0) + signedWeight * 2.5;
        _maxArtistRating = null;
      }
      if (song.genre != null) {
        _genreRatingAffinity[song.genre!] =
            (_genreRatingAffinity[song.genre!] ?? 0) + signedWeight * 1.8;
        _maxGenreRating = null;
      }
    }

    _scheduleSave();
    notifyListeners();
  }

  Future<void> trackStarred(Song song, bool starred) async {
    if (starred) {
      _starredSongs.add(song.id);
    } else {
      _starredSongs.remove(song.id);
    }

    if (_enabled) {
      final delta = starred ? 1.0 : -0.5;
      if (song.artist != null) {
        _artistAffinity[song.artist!] =
            (_artistAffinity[song.artist!] ?? 0) + delta * 2.0;
        _maxArtistAffinity = null;
      }
      if (song.genre != null) {
        _genreAffinity[song.genre!] =
            (_genreAffinity[song.genre!] ?? 0) + delta * 1.5;
        _maxGenreAffinity = null;
      }
    }

    _scheduleSave();
    notifyListeners();
  }

  double calculateSongScore(Song song, {int? currentHour}) {
    if (!_enabled) return 0.0;

    double score = 0.0;
    final profile = _profiles[song.id];
    final hour = currentHour ?? DateTime.now().hour;

    if (song.artist != null) {
      final maxA = _cachedMax(_artistAffinity, () => _maxArtistAffinity,
          (v) => _maxArtistAffinity = v);
      if (maxA > 0) {
        score += ((_artistAffinity[song.artist] ?? 0).clamp(0, maxA) / maxA) *
            _W.artistAffinity;
      }
    }

    if (song.genre != null) {
      final maxG = _cachedMax(_genreAffinity, () => _maxGenreAffinity,
          (v) => _maxGenreAffinity = v);
      if (maxG > 0) {
        score += ((_genreAffinity[song.genre] ?? 0).clamp(0, maxG) / maxG) *
            _W.genreAffinity;
      }
    }

    if (song.albumId != null) {
      final maxAl = _cachedMax(_albumAffinity, () => _maxAlbumAffinity,
          (v) => _maxAlbumAffinity = v);
      if (maxAl > 0) {
        score += ((_albumAffinity[song.albumId] ?? 0).clamp(0, maxAl) / maxAl) *
            _W.albumAffinity;
      }
    }

    if (song.artist != null) {
      final maxAr = _cachedMax(_artistRatingAffinity, () => _maxArtistRating,
          (v) => _maxArtistRating = v);
      if (maxAr > 0) {
        score += ((_artistRatingAffinity[song.artist] ?? 0).clamp(0, maxAr) /
                maxAr) *
            _W.artistRating;
      }
    }

    if (song.genre != null) {
      final maxGr = _cachedMax(_genreRatingAffinity, () => _maxGenreRating,
          (v) => _maxGenreRating = v);
      if (maxGr > 0) {
        score +=
            ((_genreRatingAffinity[song.genre] ?? 0).clamp(0, maxGr) / maxGr) *
                _W.genreRating;
      }
    }

    if (profile != null) {
      score += profile.completionRate * _W.completionRate;
      score += profile.getHourPreference(hour) * _W.hourPreference;
      score += min(profile.playCount / 10.0, 1.0) * _W.playCountSignal;
      if (profile.userRating != null) {
        score += (profile.userRating! / 5.0) * _W.userRating;
      }
    } else {
      score += _W.noveltyBonus;
    }

    if (song.userRating != null) {
      score += (song.userRating! / 5.0) * _W.songLevelRating;
    }

    if (_starredSongs.contains(song.id) || song.starred == true) {
      score += _W.starBonus;
    }

    final skips = _skipCounts[song.id] ?? 0;
    if (skips > 0) {
      score -= min(skips * _W.skipPenaltyPerSkip, _W.maxSkipPenalty);
    }

    final recentIdx = _recentIndex[song.id];
    if (recentIdx != null && recentIdx < 20) {
      score -= (20 - recentIdx) * _W.recencyPenaltyStep;
    }

    if (song.genre != null) {
      final hourMap = _timePatterns[hour];
      if (hourMap != null && hourMap.isNotEmpty) {
        final maxHg = hourMap.values.reduce(max);
        if (maxHg > 0) {
          score += ((hourMap[song.genre] ?? 0) / maxHg) * _W.timePatternsBonus;
        }
      }
    }

    return score.clamp(0.0, 1.0);
  }

  List<Song> getPersonalizedFeed(List<Song> allSongs, {int limit = 50}) {
    if (!_enabled || allSongs.isEmpty) return allSongs.take(limit).toList();
    return _sortByScore(allSongs, jitter: _W.randomJitter, limit: limit);
  }

  List<Song> getQuickPicks(List<Song> allSongs, {int limit = 20}) {
    if (!_enabled || allSongs.isEmpty) return [];

    final topArtists = _getTopArtists(5).toSet();
    final topGenres = _getTopGenres(4).toSet();
    final recentSet = _recentlyPlayed.take(10).toSet();

    var candidates = allSongs.where((s) {
      if (recentSet.contains(s.id)) return false;
      return topArtists.contains(s.artist) || topGenres.contains(s.genre);
    }).toList();

    if (candidates.length < limit) {
      final extra = allSongs
          .where((s) => !recentSet.contains(s.id) && !candidates.contains(s))
          .take(limit - candidates.length);
      candidates = [...candidates, ...extra];
    }

    return _sortByScore(candidates, jitter: 0.05, limit: limit);
  }

  List<Song> getDiscoverMix(List<Song> allSongs, {int limit = 25}) {
    if (!_enabled || allSongs.isEmpty) return [];

    final knownIds = _profiles.keys.toSet();
    final topGenres = _getTopGenres(5).toSet();
    final topArtists = _getTopArtists(10).toSet();
    final recentSet = _recentlyPlayed.take(20).toSet();

    bool isUnheard(Song s) =>
        !knownIds.contains(s.id) && !recentSet.contains(s.id);

    final tier1 = allSongs
        .where((s) =>
            isUnheard(s) &&
            topGenres.contains(s.genre) &&
            !topArtists.contains(s.artist))
        .toList();

    final tier2 = allSongs
        .where((s) => isUnheard(s) && topGenres.contains(s.genre))
        .toList();

    final tier3 = allSongs.where(isUnheard).toList();

    final pool = tier1.isNotEmpty
        ? tier1
        : tier2.isNotEmpty
            ? tier2
            : tier3.isNotEmpty
                ? tier3
                : allSongs.where((s) => !recentSet.contains(s.id)).toList();

    return _sortByScore(pool, jitter: 0.30, limit: limit);
  }

  List<Song> getArtistMix(
    List<Song> allSongs,
    String artist, {
    int limit = 25,
  }) {
    if (!_enabled) return [];
    final artistSongs = allSongs.where((s) => s.artist == artist).toList();
    return _sortByScore(artistSongs, jitter: 0.08, limit: limit);
  }

  List<Song> getGenreMix(
    List<Song> allSongs,
    String genre, {
    int limit = 25,
  }) {
    if (!_enabled) return [];
    final genreSongs = allSongs.where((s) => s.genre == genre).toList();
    return _sortByScore(genreSongs, jitter: 0.10, limit: limit);
  }

  Map<String, List<Song>> generateMixes(List<Song> allSongs) {
    if (!_enabled || allSongs.isEmpty) return {};

    final mixes = <String, List<Song>>{};

    final quick = getQuickPicks(allSongs, limit: 20);
    if (quick.isNotEmpty) mixes['Quick Picks'] = quick;

    final discover = getDiscoverMix(allSongs, limit: 20);
    if (discover.isNotEmpty) mixes['Discover Mix'] = discover;

    for (final artist in _getTopArtists(3)) {
      final mix = getArtistMix(allSongs, artist, limit: 15);
      if (mix.length >= 5) mixes['$artist Mix'] = mix;
    }

    for (final genre in _getTopGenres(2)) {
      final mix = getGenreMix(allSongs, genre, limit: 15);
      if (mix.length >= 5) mixes['$genre Mix'] = mix;
    }

    final hour = DateTime.now().hour;
    final hourMap = _timePatterns[hour];
    if (hourMap != null && hourMap.isNotEmpty) {
      final topG =
          hourMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      final timeSongs = _sortByScore(
        allSongs.where((s) => s.genre == topG).toList(),
        jitter: 0.10,
        limit: 15,
      );
      if (timeSongs.length >= 5) {
        mixes['${_timeLabel(hour)} Vibes'] = timeSongs;
      }
    }

    return mixes;
  }

  List<String> getRecommendedArtists({int limit = 10}) => _getTopArtists(limit);
  List<String> getRecommendedGenres({int limit = 5}) => _getTopGenres(limit);

  Map<String, dynamic> getListeningStats() {
    int totalPlays = 0;
    int totalDuration = 0;
    int ratedSongs = 0;
    int totalRating = 0;
    int totalSkips = 0;

    for (final p in _profiles.values) {
      totalPlays += p.playCount;
      totalDuration += p.totalListenTime;
      totalSkips += p.skipCount;
      if (p.userRating != null) {
        ratedSongs++;
        totalRating += p.userRating!;
      }
    }

    return {
      'totalPlays': totalPlays,
      'totalMinutes': totalDuration ~/ 60,
      'uniqueSongs': _profiles.length,
      'uniqueArtists': _artistAffinity.length,
      'uniqueGenres': _genreAffinity.length,
      'starredSongs': _starredSongs.length,
      'ratedSongs': ratedSongs,
      'totalSkips': totalSkips,
      'averageRating': ratedSongs > 0 ? totalRating / ratedSongs : 0.0,
      'skipRate': totalPlays > 0 ? totalSkips / totalPlays : 0.0,
      'topArtists': _getTopArtists(5),
      'topGenres': _getTopGenres(5),
    };
  }

  Future<void> clearData() async {
    _profiles.clear();
    _artistAffinity.clear();
    _genreAffinity.clear();
    _albumAffinity.clear();
    _skipCounts.clear();
    _timePatterns.clear();
    _recentlyPlayed.clear();
    _recentIndex.clear();
    _starredSongs.clear();
    _artistRatingAffinity.clear();
    _genreRatingAffinity.clear();
    _invalidateCaches();

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_getKey(_kDataKey)),
      prefs.remove(_getKey(_kSkipKey)),
      prefs.remove(_getKey(_kTimeKey)),
      prefs.remove(_getKey(_kDecayKey)),
    ]);

    notifyListeners();
  }

  double _listenWeight(Song song, int secondsPlayed,
      {required bool completed}) {
    if (completed) return 1.5;
    if (song.duration == null || song.duration == 0) return 0.8;
    final ratio = secondsPlayed / song.duration!;
    if (ratio >= 0.80) return 1.3;
    if (ratio >= 0.60) return 1.0;
    if (ratio >= 0.40) return 0.8;
    if (ratio >= 0.20) return 0.5;
    return 0.2;
  }

  List<Song> _sortByScore(
    List<Song> songs, {
    double jitter = 0.0,
    required int limit,
  }) {
    if (songs.isEmpty) return [];
    final rnd = jitter > 0 ? Random() : null;
    final hour = DateTime.now().hour;
    return (songs.map((s) {
      final base = calculateSongScore(s, currentHour: hour);
      final j = rnd != null ? rnd.nextDouble() * jitter : 0.0;
      return MapEntry(s, base + j);
    }).toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  double _cachedMax(
    Map<String, double> map,
    double? Function() getter,
    void Function(double) setter,
  ) {
    final cached = getter();
    if (cached != null) return cached;
    if (map.isEmpty) return 0.0;
    final m = map.values.reduce(max);
    setter(m);
    return m;
  }

  void _invalidateCaches() {
    _maxArtistAffinity = null;
    _maxGenreAffinity = null;
    _maxAlbumAffinity = null;
    _maxArtistRating = null;
    _maxGenreRating = null;
  }

  void _rebuildRecentIndex() {
    _recentIndex.clear();
    for (int i = 0; i < _recentlyPlayed.length; i++) {
      _recentIndex[_recentlyPlayed[i]] = i;
    }
  }

  void _applyDecay() {
    final now = DateTime.now();
    final daysSince =
        now.difference(_lastDecayApplied).inMilliseconds / 86400000.0;
    if (daysSince < 1.0) return;

    final factor = pow(0.5, daysSince / _kDecayHalfLifeDays).toDouble();

    void decayMap(Map<String, double> m) {
      for (final k in m.keys.toList()) {
        final decayed = m[k]! * factor;
        if (decayed.abs() < 0.001) {
          m.remove(k);
        } else {
          m[k] = decayed;
        }
      }
    }

    decayMap(_artistAffinity);
    decayMap(_genreAffinity);
    decayMap(_albumAffinity);
    decayMap(_artistRatingAffinity);
    decayMap(_genreRatingAffinity);
    _invalidateCaches();
    _lastDecayApplied = now;
  }

  List<String> _getTopArtists(int limit) {
    if (_artistAffinity.isEmpty) return [];
    return (_artistAffinity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  List<String> _getTopGenres(int limit) {
    if (_genreAffinity.isEmpty) return [];
    return (_genreAffinity.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  String _timeLabel(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  List<RecommendedAlbum> getRecommendedAlbums(List<Album> allAlbums) {
    if (!_enabled || allAlbums.isEmpty) return [];

    final recommendations = <RecommendedAlbum>[];
    final recentSet = _recentlyPlayed.take(20).map((id) {
      // Find album ID for recent songs if possible
      return _profiles[id]?.albumId;
    }).whereType<String>().toSet();

    final topArtists = _getTopArtists(10).toSet();
    final topGenres = _getTopGenres(5).toSet();

    for (final album in allAlbums) {
      double score = 0.0;
      String? reason;

      // 1. Artist Affinity (50%)
      if (album.artist != null && _artistAffinity.containsKey(album.artist)) {
        final maxA = _maxArtistAffinity ?? 1.0;
        final artistScore = ((_artistAffinity[album.artist] ?? 0).clamp(0, maxA) / maxA);
        score += artistScore * 0.5;
        if (artistScore > 0.7) {
          reason = 'artist';
        }
      }

      // 2. Genre Affinity (30%)
      if (album.genre != null && _genreAffinity.containsKey(album.genre)) {
        final maxG = _maxGenreAffinity ?? 1.0;
        final genreScore = ((_genreAffinity[album.genre] ?? 0).clamp(0, maxG) / maxG);
        score += genreScore * 0.3;
        if (reason == null && genreScore > 0.7) {
          reason = 'genre';
        }
      }

      // 3. Starred / Favorite Bonus (20%)
      // Note: Album model doesn't have starred property, check via service or specific songs if needed
      // For now, check if artist is in top 5 as a proxy for 'favorite'
      if (album.artist != null && _getTopArtists(5).contains(album.artist)) {
        score += 0.2;
      }

      // 4. Recency Penalty
      if (recentSet.contains(album.id)) {
        score -= 0.4;
      }

      if (score > 0.1) {
        recommendations.add(RecommendedAlbum(
          album: album,
          score: score.clamp(0.0, 1.0),
          reason: reason,
        ));
      }
    }

    // Sort by score and limit
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    // Diversify artists: allow max 2 albums per artist
    final diversified = <RecommendedAlbum>[];
    final artistCount = <String, int>{};

    for (final rec in recommendations) {
      final artist = rec.album.artist ?? 'Unknown';
      final count = artistCount[artist] ?? 0;
      if (count < 2) {
        diversified.add(rec);
        artistCount[artist] = count + 1;
      }
      if (diversified.length >= 20) break;
    }

    return diversified;
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: _kSaveDebounceMs),
      _saveData,
    );
  }

  Future<void> _loadAllData() async {
    final prefs = _prefs!;

    final dataJson = prefs.getString(_getKey(_kDataKey));
    if (dataJson != null) {
      try {
        final Map<String, dynamic> d = json.decode(dataJson);
        _profiles = (d['profiles'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, SongProfile.fromJson(v))) ??
            {};
        _artistAffinity = _parseDoubleMap(d['artists']);
        _genreAffinity = _parseDoubleMap(d['genres']);
        _albumAffinity = _parseDoubleMap(d['albums']);
        _artistRatingAffinity = _parseDoubleMap(d['artistRatings']);
        _genreRatingAffinity = _parseDoubleMap(d['genreRatings']);
        _recentlyPlayed = List<String>.from(d['recent'] ?? []);
        _starredSongs = Set<String>.from(d['starred'] ?? []);
      } catch (e) {
        debugPrint('RecommendationService: error loading main data: $e');
      }
    }

    final skipJson = prefs.getString(_getKey(_kSkipKey));
    if (skipJson != null) {
      try {
        _skipCounts = Map<String, int>.from(json.decode(skipJson));
      } catch (e) {
        debugPrint('RecommendationService: error loading skip data: $e');
      }
    }

    final timeJson = prefs.getString(_getKey(_kTimeKey));
    if (timeJson != null) {
      try {
        final Map<String, dynamic> t = json.decode(timeJson);
        _timePatterns = t.map(
          (k, v) => MapEntry(int.parse(k), _parseDoubleMap(v)),
        );
      } catch (e) {
        debugPrint('RecommendationService: error loading time patterns: $e');
      }
    }

    final decayTs = prefs.getInt(_getKey(_kDecayKey));
    if (decayTs != null) {
      _lastDecayApplied = DateTime.fromMillisecondsSinceEpoch(decayTs);
    }

    _rebuildRecentIndex();
  }

  Future<void> _saveData() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();

      final data = {
        'profiles': _profiles.map((k, v) => MapEntry(k, v.toJson())),
        'artists': _artistAffinity,
        'genres': _genreAffinity,
        'albums': _albumAffinity,
        'recent': _recentlyPlayed,
        'starred': _starredSongs.toList(),
        'artistRatings': _artistRatingAffinity,
        'genreRatings': _genreRatingAffinity,
      };

      await Future.wait([
        prefs.setString(_getKey(_kDataKey), json.encode(data)),
        prefs.setString(_getKey(_kSkipKey), json.encode(_skipCounts)),
        prefs.setString(
          _getKey(_kTimeKey),
          json.encode(_timePatterns.map((k, v) => MapEntry(k.toString(), v))),
        ),
        prefs.setInt(_getKey(_kDecayKey), _lastDecayApplied.millisecondsSinceEpoch),
      ]);
    } catch (e) {
      debugPrint('RecommendationService: error saving data: $e');
    }
  }

  Map<String, double> _parseDoubleMap(dynamic raw) {
    if (raw == null) return {};
    return (raw as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
  }
}

class SongProfile {
  final String songId;
  final String title;
  final String? artist;
  final String? artistId;
  final String? albumId;
  final String? genre;
  final int? duration;

  int playCount = 0;
  int skipCount = 0;
  int totalListenTime = 0;
  int completedPlays = 0;
  int? userRating;
  Map<int, int> hourlyPlays = {};
  late DateTime lastPlayed;
  DateTime? firstPlayed;

  SongProfile({
    required this.songId,
    required this.title,
    this.artist,
    this.artistId,
    this.albumId,
    this.genre,
    this.duration,
    DateTime? lastPlayed,
    this.firstPlayed,
  }) : lastPlayed = lastPlayed ?? DateTime.fromMillisecondsSinceEpoch(0);

  double get completionRate =>
      playCount == 0 ? 0.0 : completedPlays / playCount;

  double get skipRate {
    final total = playCount + skipCount;
    return total == 0 ? 0.0 : skipCount / total;
  }

  bool get isDisliked => skipRate > 0.6 && skipCount >= 3;

  double getHourPreference(int hour) {
    if (hourlyPlays.isEmpty) return 0.0;
    final maxH = hourlyPlays.values.reduce(max);
    if (maxH == 0) return 0.0;
    return (hourlyPlays[hour] ?? 0) / maxH;
  }

  void addPlay({int durationPlayed = 0, bool completed = false, int? hour}) {
    playCount++;
    totalListenTime += durationPlayed;
    if (completed) completedPlays++;
    if (hour != null) hourlyPlays[hour] = (hourlyPlays[hour] ?? 0) + 1;
    lastPlayed = DateTime.now();
    firstPlayed ??= DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'artist': artist,
        'artistId': artistId,
        'albumId': albumId,
        'genre': genre,
        'duration': duration,
        'playCount': playCount,
        'skipCount': skipCount,
        'totalListenTime': totalListenTime,
        'completedPlays': completedPlays,
        'userRating': userRating,
        'hourlyPlays': hourlyPlays.map((k, v) => MapEntry(k.toString(), v)),
        'lastPlayed': lastPlayed.millisecondsSinceEpoch,
        'firstPlayed': firstPlayed?.millisecondsSinceEpoch,
      };

  factory SongProfile.fromJson(Map<String, dynamic> json) => SongProfile(
        songId: json['songId'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String?,
        artistId: json['artistId'] as String?,
        albumId: json['albumId'] as String?,
        genre: json['genre'] as String?,
        duration: json['duration'] as int?,
        lastPlayed: json['lastPlayed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayed'] as int)
            : null,
        firstPlayed: json['firstPlayed'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['firstPlayed'] as int)
            : null,
      )
        ..playCount = json['playCount'] as int? ?? 0
        ..skipCount = json['skipCount'] as int? ?? 0
        ..totalListenTime = json['totalListenTime'] as int? ?? 0
        ..completedPlays = json['completedPlays'] as int? ?? 0
        ..userRating = json['userRating'] as int?
        ..hourlyPlays = (json['hourlyPlays'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
            {};
}

class PlaybackEvent {
  final String songId;
  final DateTime timestamp;
  final String eventType; // play_validated, completed, skipped, time_added
  final int duration;
  final bool completed;

  PlaybackEvent({
    required this.songId,
    required this.timestamp,
    required this.eventType,
    required this.duration,
    required this.completed,
  });
}
