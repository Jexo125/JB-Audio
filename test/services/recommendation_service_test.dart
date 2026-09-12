import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/song.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeLibraryDatabaseService extends Fake implements LibraryDatabaseService {
  @override
  Future<void> insertListeningEvent({
    required String songId,
    required String eventType,
    required int durationSeconds,
    required int completed,
    required String timestamp,
  }) async {
    // No-op for tests to avoid SQLite initialization error
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('RecommendationService & PlaybackEvent Foundations', () {
    late RecommendationService recommendationService;

    setUp(() async {
      recommendationService = RecommendationService();
      recommendationService.dbService = FakeLibraryDatabaseService();
      await recommendationService.initialize();
    });

    test('trackSongPlay should set firstPlayed and emit play_validated event', () async {
      final song = Song(id: 'test_song_1', title: 'Test Title', artist: 'Test Artist', genre: 'Rock');

      // Listen for the stream events
      final eventsFuture = recommendationService.playbackEvents.toList();

      await recommendationService.trackSongPlay(song, durationPlayed: 30);

      final profile = recommendationService.profiles['test_song_1'];
      expect(profile, isNotNull);
      expect(profile!.firstPlayed, isNotNull);
      
      final initialFirstPlayed = profile.firstPlayed;

      // Track again to ensure firstPlayed does not change
      await Future.delayed(const Duration(milliseconds: 10));
      await recommendationService.trackSongPlay(song, durationPlayed: 45);
      expect(profile.firstPlayed, equals(initialFirstPlayed));

      recommendationService.dispose();
      final events = await eventsFuture;
      expect(events.any((e) => e.eventType == 'play_validated'), isTrue);
    });

    test('trackSongCompletion should emit completed event', () async {
      final song = Song(id: 'test_song_2', title: 'Test Title 2', artist: 'Test Artist 2');

      final eventsFuture = recommendationService.playbackEvents.take(2).toList();

      await recommendationService.trackSongPlay(song, durationPlayed: 30);
      await recommendationService.trackSongCompletion(song, durationPlayed: 180);

      final profile = recommendationService.profiles['test_song_2'];
      expect(profile!.completedPlays, equals(1));

      recommendationService.dispose();
      final events = await eventsFuture;
      expect(events.any((e) => e.eventType == 'completed'), isTrue);
    });

    test('trackSkip should emit skipped event', () async {
      final song = Song(id: 'test_song_3', title: 'Test Title 3');

      final eventsFuture = recommendationService.playbackEvents.take(1).toList();

      await recommendationService.trackSkip(song, secondsPlayed: 5);

      recommendationService.dispose();
      final events = await eventsFuture;
      expect(events.first.eventType, equals('skipped'));
      expect(events.first.duration, equals(5));
    });

    test('trackIncrementalListenTime should increase totalListenTime without changing playCount', () async {
      final song = Song(id: 'test_song_4', title: 'Test Title 4');

      await recommendationService.trackSongPlay(song, durationPlayed: 30);
      final profile = recommendationService.profiles['test_song_4']!;
      expect(profile.playCount, equals(1));
      final initialListenTime = profile.totalListenTime;

      await recommendationService.trackIncrementalListenTime(song, 15);
      expect(profile.playCount, equals(1));
      expect(profile.totalListenTime, equals(initialListenTime + 15));
    });
  });
}
