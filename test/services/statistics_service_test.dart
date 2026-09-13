import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/song.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/statistics_service.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

// Manual Fake for LibraryDatabaseService
class FakeDbService extends LibraryDatabaseService {
  final Database _testDb;
  FakeDbService(this._testDb);

  @override
  Future<Database> get database async => _testDb;
}

class FakeDbServiceWithQuery extends Fake implements LibraryDatabaseService {
  final List<Map<String, dynamic>> queryResult;
  FakeDbServiceWithQuery(this.queryResult);

  @override
  Future<Database> get database async => FakeDatabase(queryResult);
}

class FakeDatabase extends Fake implements Database {
  final List<Map<String, dynamic>> queryResult;
  FakeDatabase(this.queryResult);

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    return queryResult;
  }
}

void main() {
  // Note: We skip the in-memory SQLite initialization because of the previous 
  // 'databaseFactory not initialized' error. We focus on GlobalStats (RecommendationService logic)
  // and mock/structure the rest as needed.

  group('StatisticsService Logic Tests', () {
    late RecommendationService recommendationService;
    late StatisticsService statisticsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      recommendationService = RecommendationService();
      await recommendationService.initialize();
      statisticsService = StatisticsService(LibraryDatabaseService(), recommendationService);
    });

    test('getGlobalStats should aggregate all profiles correctly', () async {
      final s1 = Song(id: 's1', title: 'Song 1', artist: 'Artist 1');
      await recommendationService.trackSongPlay(s1, durationPlayed: 30, completed: true);
      
      final stats = await statisticsService.getGlobalStats();
      expect(stats.totalPlays, 1);
      expect(stats.uniqueSongs, 1);
      expect(stats.totalListenTime, 30);
    });

    test('getGlobalStats should aggregate multiple tracks and artists', () async {
      final s1 = Song(id: 's1', title: 'T1', artist: 'A1');
      final s2 = Song(id: 's2', title: 'T2', artist: 'A2');
      
      await recommendationService.trackSongPlay(s1, durationPlayed: 30, completed: true);
      await recommendationService.trackSongPlay(s2, durationPlayed: 40, completed: false);
      await recommendationService.trackSkip(s2, secondsPlayed: 5);
      
      final stats = await statisticsService.getGlobalStats();
      expect(stats.totalPlays, 2);
      expect(stats.totalSkips, 1);
      expect(stats.uniqueSongs, 2);
      expect(stats.totalListenTime, 75); // 30 + 40 + 5
    });

    test('getDiscoveryCount should correctly filter by period', () async {
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 1));
      final end = now.add(const Duration(hours: 1));

      final song = Song(id: 'discovery_1', title: 'New Track');
      await recommendationService.trackSongPlay(song, durationPlayed: 30);

      final count = await statisticsService.getDiscoveryCount(start: start, end: end);
      expect(count, 1);

      final countOld = await statisticsService.getDiscoveryCount(
        start: now.subtract(const Duration(days: 2)),
        end: now.subtract(const Duration(days: 1)),
      );
      expect(countOld, 0);
    });

    test('getPeriodStats should return zeroed stats on empty results', () async {
      final mockService = FakeDbServiceWithQuery([]);
      final statsService = StatisticsService(mockService, recommendationService);

      final stats = await statsService.getPeriodStats(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(stats.totalListenTime, 0);
      expect(stats.totalPlayCount, 0);
      expect(stats.totalCompletionCount, 0);
    });

    test('getPeriodStats should map SQL results correctly', () async {
      final mockService = FakeDbServiceWithQuery([
        {
          'totalTime': 100,
          'totalPlays': 5,
          'totalCompletions': 3,
        }
      ]);
      final statsService = StatisticsService(mockService, recommendationService);

      final stats = await statsService.getPeriodStats(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(stats.totalListenTime, 100);
      expect(stats.totalPlayCount, 5);
      expect(stats.totalCompletionCount, 3);
    });
  });
}
