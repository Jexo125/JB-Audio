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
    // No-op
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('RecommendationService Reliability Tests', () {
    late RecommendationService recommendationService;

    setUp(() async {
      recommendationService = RecommendationService();
      recommendationService.dbService = FakeLibraryDatabaseService();
      await recommendationService.initialize();
    });

    test('trackSongPlay should set firstPlayed and emit time_added', () async {
      final song = Song(id: 's1', title: 'T1', artist: 'A1');
      final events = <PlaybackEvent>[];
      recommendationService.playbackEvents.listen((e) => events.add(e));

      await recommendationService.trackSongPlay(song, durationPlayed: 30);
      
      // Yield to let stream events be processed
      await Future.delayed(Duration.zero);
      
      expect(recommendationService.profiles['s1']?.firstPlayed, isNotNull);
      expect(events.any((e) => e.eventType == 'play_validated'), isTrue);
      expect(events.any((e) => e.eventType == 'time_added' && e.duration == 30), isTrue);
    });

    test('trackSkip should update time and emit time_added', () async {
      final song = Song(id: 's2', title: 'T2', artist: 'A2');
      final events = <PlaybackEvent>[];
      recommendationService.playbackEvents.listen((e) => events.add(e));

      await recommendationService.trackSkip(song, secondsPlayed: 10);
      
      await Future.delayed(Duration.zero);
      
      expect(recommendationService.profiles['s2']?.totalListenTime, 10);
      expect(events.any((e) => e.eventType == 'skipped'), isTrue);
      expect(events.any((e) => e.eventType == 'time_added' && e.duration == 10), isTrue);
    });

    test('trackIncrementalListenTime should emit time_added', () async {
      final song = Song(id: 's3', title: 'T3', artist: 'A3');
      await recommendationService.trackSongPlay(song, durationPlayed: 30);
      
      final events = <PlaybackEvent>[];
      recommendationService.playbackEvents.listen((e) => events.add(e));

      await recommendationService.trackIncrementalListenTime(song, 5);
      
      await Future.delayed(Duration.zero);
      
      expect(recommendationService.profiles['s3']?.totalListenTime, 35);
      expect(events.any((e) => e.eventType == 'time_added' && e.duration == 5), isTrue);
    });
  });
}
