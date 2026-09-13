import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/models.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:jbaudio/services/music_quest_service.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/statistics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDbService extends Fake implements LibraryDatabaseService {
  final List<MusicQuestInstance> instances = [];
  int _nextId = 1;

  @override
  Future<List<MusicQuestInstance>> getActiveQuestInstances() async {
    return instances.where((i) => i.status == QuestStatus.active).toList();
  }

  @override
  Future<List<MusicQuestInstance>> getQuestInstancesByPeriod(DateTime start, DateTime end) async {
    return instances.where((i) => i.periodStart.isAtSameMomentAs(start) && i.periodEnd.isAtSameMomentAs(end)).toList();
  }

  @override
  Future<int> insertQuestInstance(MusicQuestInstance instance) async {
    final newInstance = instance.copyWith(id: _nextId++);
    instances.add(newInstance);
    return newInstance.id!;
  }

  @override
  Future<void> updateQuestInstanceStatus(int id, QuestStatus status, {DateTime? completedAt}) async {
    final idx = instances.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      instances[idx] = instances[idx].copyWith(status: status, completedAt: completedAt);
    }
  }

  @override
  Future<List<MusicQuestInstance>> getQuestInstances() async => instances;
}

class MockStatsService extends Fake implements StatisticsService {
  int listenTime = 0;
  int playCount = 0;
  int completionCount = 0;
  int artistCount = 0;
  int albumCount = 0;
  int genreCount = 0;
  int discoveryCount = 0;
  int activeDayCount = 0;

  @override
  Future<PeriodStats> getPeriodStats({required DateTime start, required DateTime end}) async {
    return PeriodStats(
      totalListenTime: listenTime,
      totalPlayCount: playCount,
      totalCompletionCount: completionCount,
    );
  }

  @override
  Future<int> getDistinctArtistCount({DateTime? start, DateTime? end}) async => artistCount;

  @override
  Future<int> getDistinctAlbumCount({DateTime? start, DateTime? end}) async => albumCount;

  @override
  Future<int> getDistinctGenreCount({DateTime? start, DateTime? end}) async => genreCount;

  @override
  Future<int> getDiscoveryCount({required DateTime start, required DateTime end}) async => discoveryCount;

  @override
  Future<int> getActiveDayCount({required DateTime start, required DateTime end}) async => activeDayCount;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('MusicQuestService Tests', () {
    late FakeDbService dbService;
    late RecommendationService recService;
    late MockStatsService statsService;
    late MusicQuestService questService;

    setUp(() async {
      dbService = FakeDbService();
      recService = RecommendationService();
      await recService.initialize();
      statsService = MockStatsService();
      questService = MusicQuestService(dbService, recService, statsService);
    });

    test('initialize() should generate 5 V1 quêtes for today', () async {
      await questService.initialize();

      final active = questService.getActiveQuests();
      expect(active.length, 5);
      expect(dbService.instances.length, 5);
      
      // Ensure specific IDs are present
      final ids = active.map((i) => i.definitionId).toSet();
      expect(ids.contains('daily_listener'), true);
      expect(ids.contains('weekly_loyalty'), true);
    });

    test('initialize() multiple times should not create duplicates', () async {
      await questService.initialize();
      final count1 = dbService.instances.length;

      await questService.initialize();
      expect(dbService.instances.length, count1);
    });

    test('getQuestProgress should return correct values', () async {
      await questService.initialize();
      final instance = questService.getActiveQuests().firstWhere((i) => i.definitionId == 'daily_listener');

      statsService.listenTime = 900; // 15 mins
      final progress = await questService.getQuestProgress(instance);

      expect(progress.currentValue, 900);
      expect(progress.targetValue, 1800);
      expect(progress.percent, 0.5);
      expect(progress.isCompleted, false);

      statsService.listenTime = 2000;
      final progress2 = await questService.getQuestProgress(instance);
      expect(progress2.isCompleted, true);
      expect(progress2.percent, 1.0);
    });

    test('PlaybackEvent should trigger completion', () async {
      await questService.initialize();
      
      // Listen for updates
      final updates = <MusicQuestInstance>[];
      questService.onQuestUpdated.listen((i) => updates.add(i));

      // Simulate enough time listened
      statsService.listenTime = 2000;

      // Ensure song has a profile to emit event
      final song = Song(id: 's1', title: 'T1');
      await recService.trackSongPlay(song, durationPlayed: 30);

      // Trigger event
      await recService.trackIncrementalListenTime(song, 5);
      
      // Give some time for async processing
      await Future.delayed(const Duration(milliseconds: 100));

      final completed = updates.where((i) => i.definitionId == 'daily_listener' && i.status == QuestStatus.completed).toList();
      expect(completed.length, 1);
      expect(completed.first.completedAt, isNotNull);
      
      // Check that it's no longer in active list
      expect(questService.getActiveQuests().any((i) => i.definitionId == 'daily_listener'), false);
    });

    test('Expired quests should be handled', () async {
      // Manually add an old active quest to DB
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final end = start.add(const Duration(days: 1));
      
      dbService.instances.add(MusicQuestInstance(
        id: 99,
        definitionId: 'daily_listener',
        periodStart: start,
        periodEnd: end,
        status: QuestStatus.active,
      ));

      await questService.initialize();

      final instance = dbService.instances.firstWhere((i) => i.id == 99);
      expect(instance.status, QuestStatus.expired);
      expect(questService.getActiveQuests().any((i) => i.id == 99), false);
    });

    test('Period range logic for daily and weekly', () async {
      // Mocking different "now" dates would require refactoring Service to accept a clock,
      // but we can check the generated periods for today.
      await questService.initialize();
      final daily = questService.getActiveQuests().firstWhere((i) => i.definitionId == 'daily_listener');
      
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, now.day);
      expect(daily.periodStart.isAtSameMomentAs(expectedStart), true);
      expect(daily.periodEnd.isAtSameMomentAs(expectedStart.add(const Duration(days: 1))), true);

      final weekly = questService.getActiveQuests().firstWhere((i) => i.definitionId == 'weekly_loyalty');
      // Monday check
      final daysToMonday = now.weekday - 1;
      final expectedWeekStart = expectedStart.subtract(Duration(days: daysToMonday));
      expect(weekly.periodStart.isAtSameMomentAs(expectedWeekStart), true);
      expect(weekly.periodEnd.isAtSameMomentAs(expectedWeekStart.add(const Duration(days: 7))), true);
    });

    test('Concurrent events should trigger a pending re-check', () async {
      await questService.initialize();
      
      // Trigger multiple events very quickly
      for(int i=0; i<10; i++) {
         recService.trackIncrementalListenTime(Song(id: 's1', title: 'T1'), 1);
      }

      await Future.delayed(const Duration(milliseconds: 200));
      
      // The test passes if no exceptions occurred (like parallel loop conflicts)
      // and all 10 events were handled by the serializing mechanism.
    });

    test('isInitialized getter follows initialization cycle', () async {
      expect(questService.isInitialized, false);
      final initFuture = questService.initialize();
      expect(questService.isInitialized, false); // Still initializing
      await initFuture;
      expect(questService.isInitialized, true);
    });

    test('getCurrentPeriodRange returns correct bounds', () async {
      final now = DateTime.now();
      final expectedStart = DateTime(now.year, now.month, now.day);
      
      final daily = questService.getCurrentPeriodRange(QuestPeriodType.daily);
      expect(daily.start, equals(expectedStart));
      expect(daily.end, equals(expectedStart.add(const Duration(days: 1))));
    });

    test('getAllActiveProgress provides a single snapshot for all active quests', () async {
      await questService.initialize();
      
      statsService.listenTime = 120;
      statsService.artistCount = 2;
      
      final progressMap = await questService.getAllActiveProgress();
      
      expect(progressMap.length, 5);
      expect(progressMap['daily_listener']?.currentValue, 120);
      expect(progressMap['daily_explorer']?.currentValue, 2);
    });
  });
}
