import 'library_database_service.dart';
import 'recommendation_service.dart';

/// Represents global statistics (All Time).
/// Can include data prior to Phase 2 via [RecommendationService].
class GlobalStats {
  final int totalListenTime; // In seconds
  final int totalPlays;      // validated plays
  final int totalCompleted;
  final int totalSkips;
  final int uniqueSongs;
  final DateTime? firstEvent;
  final DateTime? lastEvent;

  GlobalStats({
    required this.totalListenTime,
    required this.totalPlays,
    required this.totalCompleted,
    required this.totalSkips,
    required this.uniqueSongs,
    this.firstEvent,
    this.lastEvent,
  });
}

/// Represents an item in a Top list (Artist, Album, Song, Genre).
class StatItem {
  final String id;
  final String name;
  final String? subName; // Artist name for album/song
  final int playCount;
  final int listenTime; // In seconds
  final String? imageUrl;

  StatItem({
    required this.id,
    required this.name,
    this.subName,
    required this.playCount,
    required this.listenTime,
    this.imageUrl,
  });
}

/// Represents a point in time for charts.
class TimeDataPoint {
  final DateTime timestamp;
  final int listenTime;
  final int playCount;

  TimeDataPoint({
    required this.timestamp,
    required this.listenTime,
    required this.playCount,
  });
}

/// Simple aggregates for a specific period.
class PeriodStats {
  final int totalListenTime;
  final int totalPlayCount;
  final int totalCompletionCount;

  PeriodStats({
    required this.totalListenTime,
    required this.totalPlayCount,
    required this.totalCompletionCount,
  });
}

class StatisticsService {
  final LibraryDatabaseService _dbService;
  final RecommendationService _recommendationService;

  StatisticsService(this._dbService, this._recommendationService);

  /// Returns global statistics.
  /// Uses [RecommendationService] profiles as the primary source to include 
  /// history before detailed SQLite logging started.
  Future<GlobalStats> getGlobalStats() async {
    final profiles = _recommendationService.profiles.values;
    
    int totalTime = 0;
    int totalPlays = 0;
    int totalComp = 0;
    int totalSkips = 0;
    DateTime? first;
    DateTime? last;

    for (final p in profiles) {
      totalTime += p.totalListenTime;
      totalPlays += p.playCount;
      totalComp += p.completedPlays;
      totalSkips += p.skipCount;
      
      if (p.firstPlayed != null) {
        if (first == null || p.firstPlayed!.isBefore(first)) {
          first = p.firstPlayed;
        }
      }
      if (p.lastPlayed.millisecondsSinceEpoch > 0) {
        if (last == null || p.lastPlayed.isAfter(last)) {
          last = p.lastPlayed;
        }
      }
    }

    return GlobalStats(
      totalListenTime: totalTime,
      totalPlays: totalPlays,
      totalCompleted: totalComp,
      totalSkips: totalSkips,
      uniqueSongs: profiles.length,
      firstEvent: first,
      lastEvent: last,
    );
  }

  /// Base query for Tops with period filtering.
  /// Uses SQLite 'time_added' events for duration and 'play_validated' for counts.
  Future<List<StatItem>> getTopSongs({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    
    if (start != null) {
      where += " AND timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    // We aggregate counts from play_validated and duration from time_added
    final query = '''
      SELECT 
        e.song_id,
        SUM(CASE WHEN e.event_type = 'play_validated' THEN 1 ELSE 0 END) as plays,
        SUM(CASE WHEN e.event_type = 'time_added' THEN e.duration_seconds ELSE 0 END) as duration,
        s.title,
        s.artist,
        s.coverArt
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE 1=1 $where
      GROUP BY e.song_id
      HAVING plays > 0 OR duration > 0
      ORDER BY plays DESC, duration DESC
      LIMIT ?
    ''';
    
    whereArgs.add(limit);
    final results = await db.rawQuery(query, whereArgs);

    return results.map((r) {
      final songId = r['song_id'] as String;
      String name = r['title'] as String? ?? "Unknown";
      String? artist = r['artist'] as String?;
      String? cover = r['coverArt'] as String?;

      // Fallback to SongProfile if song is missing from library
      if (name == "Unknown") {
        final profile = _recommendationService.profiles[songId];
        if (profile != null) {
          name = profile.title;
          artist = profile.artist;
        }
      }

      return StatItem(
        id: songId,
        name: name,
        subName: artist,
        playCount: (r['plays'] as num).toInt(),
        listenTime: (r['duration'] as num).toInt(),
        imageUrl: cover,
      );
    }).toList();
  }

  Future<List<StatItem>> getTopArtists({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    // Join with songs to get artist info. 
    // For deleted songs, we use the raw song_id to try fallback lookup later if needed,
    // but SQL grouping by artist name is more reliable for "Top Artists".
    final query = '''
      SELECT 
        COALESCE(s.artist, 'Unknown') as artist_name,
        SUM(CASE WHEN e.event_type = 'play_validated' THEN 1 ELSE 0 END) as plays,
        SUM(CASE WHEN e.event_type = 'time_added' THEN e.duration_seconds ELSE 0 END) as duration
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE 1=1 $where
      GROUP BY artist_name
      HAVING plays > 0 OR duration > 0
      ORDER BY plays DESC, duration DESC
      LIMIT ?
    ''';
    
    whereArgs.add(limit);
    final results = await db.rawQuery(query, whereArgs);

    return results.map((r) {
      String name = r['artist_name'] as String;
      
      // Note: Full fallback for artists requires iterating profiles, 
      // which we skip here if name is already found in SQLite via JOIN.
      
      return StatItem(
        id: name, // For artists, ID is the name
        name: name,
        playCount: (r['plays'] as num).toInt(),
        listenTime: (r['duration'] as num).toInt(),
      );
    }).toList();
  }

  Future<List<StatItem>> getTopAlbums({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    final query = '''
      SELECT 
        COALESCE(s.albumId, 'Unknown') as album_id,
        COALESCE(s.album, 'Unknown') as album_name,
        COALESCE(s.artist, 'Unknown') as artist_name,
        s.coverArt,
        SUM(CASE WHEN e.event_type = 'play_validated' THEN 1 ELSE 0 END) as plays,
        SUM(CASE WHEN e.event_type = 'time_added' THEN e.duration_seconds ELSE 0 END) as duration
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE 1=1 $where
      GROUP BY album_id, album_name
      HAVING plays > 0 OR duration > 0
      ORDER BY plays DESC, duration DESC
      LIMIT ?
    ''';
    
    whereArgs.add(limit);
    final results = await db.rawQuery(query, whereArgs);

    return results.map((r) {
      return StatItem(
        id: r['album_id'] as String,
        name: r['album_name'] as String,
        subName: r['artist_name'] as String,
        playCount: (r['plays'] as num).toInt(),
        listenTime: (r['duration'] as num).toInt(),
        imageUrl: r['coverArt'] as String?,
      );
    }).toList();
  }

  Future<List<StatItem>> getTopGenres({
    DateTime? start,
    DateTime? end,
    int limit = 10,
  }) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    final query = '''
      SELECT 
        COALESCE(s.genre, 'Unknown') as genre_name,
        SUM(CASE WHEN e.event_type = 'play_validated' THEN 1 ELSE 0 END) as plays,
        SUM(CASE WHEN e.event_type = 'time_added' THEN e.duration_seconds ELSE 0 END) as duration
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE 1=1 $where
      GROUP BY genre_name
      HAVING plays > 0 OR duration > 0
      ORDER BY plays DESC, duration DESC
      LIMIT ?
    ''';
    
    whereArgs.add(limit);
    final results = await db.rawQuery(query, whereArgs);

    return results.map((r) {
      return StatItem(
        id: r['genre_name'] as String,
        name: r['genre_name'] as String,
        playCount: (r['plays'] as num).toInt(),
        listenTime: (r['duration'] as num).toInt(),
      );
    }).toList();
  }

  /// Returns time-series data for charts.
  /// [interval] can be 'day' or 'month'.
  Future<List<TimeDataPoint>> getListeningHistory({
    required DateTime start,
    required DateTime end,
    required String interval,
  }) async {
    final db = await _dbService.database;
    
    // SQLite date grouping
    String dateFunc = "strftime('%Y-%m-%d', timestamp)";
    if (interval == 'month') {
      dateFunc = "strftime('%Y-%m', timestamp)";
    }

    final query = '''
      SELECT 
        $dateFunc as period,
        SUM(CASE WHEN event_type = 'play_validated' THEN 1 ELSE 0 END) as plays,
        SUM(CASE WHEN event_type = 'time_added' THEN duration_seconds ELSE 0 END) as duration
      FROM listening_events
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY period
      ORDER BY period ASC
    ''';

    final results = await db.rawQuery(query, [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    return results.map((r) {
      return TimeDataPoint(
        timestamp: DateTime.parse(r['period'] as String),
        listenTime: (r['duration'] as num).toInt(),
        playCount: (r['plays'] as num).toInt(),
      );
    }).toList();
  }

  /// Returns simple aggregates for the period [start, end).
  Future<PeriodStats> getPeriodStats({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbService.database;

    final query = '''
      SELECT 
        SUM(CASE WHEN event_type = 'time_added' THEN duration_seconds ELSE 0 END) as totalTime,
        SUM(CASE WHEN event_type = 'play_validated' THEN 1 ELSE 0 END) as totalPlays,
        SUM(CASE WHEN event_type = 'completed' THEN 1 ELSE 0 END) as totalCompletions
      FROM listening_events
      WHERE timestamp >= ? AND timestamp < ?
    ''';

    final results = await db.rawQuery(query, [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    if (results.isEmpty || results.first['totalTime'] == null) {
      return PeriodStats(
        totalListenTime: 0,
        totalPlayCount: 0,
        totalCompletionCount: 0,
      );
    }

    final row = results.first;
    return PeriodStats(
      totalListenTime: (row['totalTime'] as num?)?.toInt() ?? 0,
      totalPlayCount: (row['totalPlays'] as num?)?.toInt() ?? 0,
      totalCompletionCount: (row['totalCompletions'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Music Quest Criteria Helpers ──────────────────────────────────────────

  /// Counts distinct artists listened to during the period.
  /// Falls back to SongProfile metadata for deleted songs.
  Future<int> getDistinctArtistCount({DateTime? start, DateTime? end}) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    final query = '''
      SELECT DISTINCT s.artist as name, e.song_id
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE (e.event_type = 'play_validated' OR e.event_type = 'time_added') $where
    ''';

    final results = await db.rawQuery(query, whereArgs);
    final distinctNames = <String>{};

    for (final r in results) {
      String? artistName = r['name'] as String?;
      if (artistName == null || artistName == "Unknown") {
        final profile = _recommendationService.profiles[r['song_id'] as String];
        artistName = profile?.artist ?? "Unknown";
      }
      distinctNames.add(artistName);
    }

    return distinctNames.where((n) => n != "Unknown").length;
  }

  /// Counts distinct albums listened to during the period.
  Future<int> getDistinctAlbumCount({DateTime? start, DateTime? end}) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    final query = '''
      SELECT DISTINCT s.albumId as id, e.song_id
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE (e.event_type = 'play_validated' OR e.event_type = 'time_added') $where
    ''';

    final results = await db.rawQuery(query, whereArgs);
    final distinctIds = <String>{};

    for (final r in results) {
      String? albumId = r['id'] as String?;
      if (albumId == null || albumId == "Unknown") {
        final profile = _recommendationService.profiles[r['song_id'] as String];
        albumId = profile?.albumId ?? "Unknown";
      }
      distinctIds.add(albumId);
    }

    return distinctIds.where((id) => id != "Unknown").length;
  }

  /// Counts distinct genres listened to during the period.
  Future<int> getDistinctGenreCount({DateTime? start, DateTime? end}) async {
    final db = await _dbService.database;
    String where = "";
    List<Object?> whereArgs = [];
    if (start != null) {
      where += " AND e.timestamp >= ?";
      whereArgs.add(start.toIso8601String());
    }
    if (end != null) {
      where += " AND e.timestamp <= ?";
      whereArgs.add(end.toIso8601String());
    }

    final query = '''
      SELECT DISTINCT s.genre as name, e.song_id
      FROM listening_events e
      LEFT JOIN songs s ON e.song_id = s.id
      WHERE (e.event_type = 'play_validated' OR e.event_type = 'time_added') $where
    ''';

    final results = await db.rawQuery(query, whereArgs);
    final distinctNames = <String>{};

    for (final r in results) {
      String? genre = r['name'] as String?;
      if (genre == null || genre == "Unknown") {
        final profile = _recommendationService.profiles[r['song_id'] as String];
        genre = profile?.genre ?? "Unknown";
      }
      distinctNames.add(genre);
    }

    return distinctNames.where((n) => n != "Unknown").length;
  }

  /// Counts active listening days during the period.
  /// Uses 'time_added' as the reliable indicator of real listening.
  Future<int> getActiveDayCount({required DateTime start, required DateTime end}) async {
    final db = await _dbService.database;
    
    final query = '''
      SELECT COUNT(DISTINCT strftime('%Y-%m-%d', timestamp)) as days
      FROM listening_events
      WHERE event_type = 'time_added' 
        AND timestamp >= ? AND timestamp <= ?
    ''';

    final results = await db.rawQuery(query, [
      start.toIso8601String(),
      end.toIso8601String(),
    ]);

    if (results.isEmpty) return 0;
    return (results.first['days'] as num).toInt();
  }

  /// Counts how many tracks were discovered (first ever listen) during the period.
  /// Relies on SongProfile.firstPlayed being within the range.
  Future<int> getDiscoveryCount({required DateTime start, required DateTime end}) async {
    final profiles = _recommendationService.profiles.values;
    int count = 0;
    
    for (final p in profiles) {
      if (p.firstPlayed != null) {
        if ((p.firstPlayed!.isAtSameMomentAs(start) || p.firstPlayed!.isAfter(start)) &&
            (p.firstPlayed!.isAtSameMomentAs(end) || p.firstPlayed!.isBefore(end))) {
          count++;
        }
      }
    }
    return count;
  }
}
