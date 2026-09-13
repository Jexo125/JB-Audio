import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/song.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/statistics_service.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
      expect(stats.totalListenTime, 75); // 30 (s1) + 40 (s2) + 5 (s2 skip)
    });
  });
}
