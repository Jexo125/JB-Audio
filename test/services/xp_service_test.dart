import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/models.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/music_quest_service.dart';
import 'package:jbaudio/services/statistics_service.dart';
import 'package:jbaudio/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class FakeDbService extends Fake implements LibraryDatabaseService {
  UserProgression progression = const UserProgression();
  final List<Map<String, dynamic>> transactions = [];
  final List<Map<String, dynamic>> titles = [];

  @override
  Future<UserProgression> getUserProgression() async => progression;

  @override
  Future<void> updateUserProgression(UserProgression p) async {
    progression = p;
  }

  @override
  Future<List<Map<String, dynamic>>> getUnlockedTitles() async => titles;

  @override
  Future<void> insertUnlockedTitle(String titleKey, String unlockedAt) async {
    titles.add({'title_key': titleKey, 'unlocked_at': unlockedAt});
  }

  @override
  Future<void> insertListeningEvent({
    required String songId,
    required String eventType,
    required int durationSeconds,
    required int completed,
    required String timestamp,
  }) async {
    // No-op for XP tests
  }

  @override
  Future<bool> creditEventXp({
    required String type,
    required String sourceId,
    required int amount,
  }) async {
    final exists = transactions.any((t) => t['type'] == type && t['id'] == sourceId);
    if (exists) return false;
    
    transactions.add({
      'type': type,
      'id': sourceId,
      'amount': amount,
    });
    progression = progression.copyWith(totalXp: progression.totalXp + amount);
    return true;
  }
}

class MockMusicQuestService extends Fake implements MusicQuestService {
  final _controller = StreamController<MusicQuestInstance>.broadcast();
  @override
  Stream<MusicQuestInstance> get onQuestUpdated => _controller.stream;

  void emit(MusicQuestInstance quest) => _controller.add(quest);

  @override
  void dispose() => _controller.close();
}

class MockStatsService extends Fake implements StatisticsService {
  int listenTime = 0;
  int completedCount = 0;
  int artistCount = 0;
  int albumCount = 0;
  int discoveryCount = 0;
  int activeDays = 0;

  @override
  Future<GlobalStats> getGlobalStats() async => GlobalStats(
    totalListenTime: listenTime,
    totalPlays: 0,
    totalCompleted: completedCount,
    totalSkips: 0,
    uniqueSongs: 0,
  );

  @override
  Future<int> getDistinctArtistCount({DateTime? start, DateTime? end}) async => artistCount;
  @override
  Future<int> getDistinctAlbumCount({DateTime? start, DateTime? end}) async => albumCount;
  @override
  Future<int> getActiveDayCount({required DateTime start, required DateTime end}) async => activeDays;
  @override
  Future<int> getDiscoveryCount({required DateTime start, required DateTime end}) async => discoveryCount;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('XpService Logic Tests', () {
    late FakeDbService dbService;
    late RecommendationService recService;
    late MockMusicQuestService questService;
    late MockStatsService statsService;
    late XpService xpService;

    setUp(() async {
      dbService = FakeDbService();
      recService = RecommendationService();
      recService.dbService = dbService; // Inject fake DB
      await recService.initialize();
      questService = MockMusicQuestService();
      statsService = MockStatsService();
      xpService = XpService(dbService, recService, questService, statsService);
    });

    tearDown(() {
      questService.dispose();
      xpService.dispose();
    });

    test('initialize() should load progression and start listening', () async {
      dbService.progression = const UserProgression(totalXp: 50, pendingSeconds: 10);
      
      expect(xpService.isInitialized, false);
      await xpService.initialize();
      expect(xpService.isInitialized, true);
      expect(xpService.progression.totalXp, 50);
      expect(xpService.progression.pendingSeconds, 10);
    });

    test('time_added should increment XP based on 60s rule', () async {
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      
      // trackSongPlay gives 12 XP (2 val + 10 disco)
      await recService.trackSongPlay(song); 
      await Future.delayed(const Duration(milliseconds: 50));
      final baseXP = xpService.progression.totalXp;
      
      // Simulate 30s event
      await recService.trackIncrementalListenTime(song, 30);
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(xpService.progression.totalXp, baseXP);
      expect(xpService.progression.pendingSeconds, 30);

      // Add 40s -> should overflow to 1 XP
      await recService.trackIncrementalListenTime(song, 40);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, baseXP + 1);
      expect(xpService.progression.pendingSeconds, 10);
    });

    test('90s event should give 1 XP and 30s pending', () async {
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      await recService.trackSongPlay(song);
      await Future.delayed(const Duration(milliseconds: 50));
      final baseXP = xpService.progression.totalXp;

      await recService.trackIncrementalListenTime(song, 90);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, baseXP + 1);
      expect(xpService.progression.pendingSeconds, 30);
    });

    test('120s event should give 2 XP', () async {
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      await recService.trackSongPlay(song);
      await Future.delayed(const Duration(milliseconds: 50));
      final baseXP = xpService.progression.totalXp;

      await recService.trackIncrementalListenTime(song, 120);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, baseXP + 2);
      expect(xpService.progression.pendingSeconds, 0);
    });

    test('pending 59 + 5s should give 1 XP and 4s pending', () async {
      dbService.progression = const UserProgression(totalXp: 10, pendingSeconds: 59);
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      await recService.trackSongPlay(song);
      await Future.delayed(const Duration(milliseconds: 50));
      final baseXP = xpService.progression.totalXp; // should be 10 + 12 = 22
      
      await recService.trackIncrementalListenTime(song, 5);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, baseXP + 1);
      expect(xpService.progression.pendingSeconds, 4);
    });

    test('skipped events should remove from session validation', () async {
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      
      // Play and validate
      await recService.trackSongPlay(song, durationPlayed: 30);
      await Future.delayed(const Duration(milliseconds: 50));
      final baseXP = xpService.progression.totalXp;

      // Skip should remove validation
      await recService.trackSkip(song);
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Completion should NOT give XP now
      await recService.trackSongCompletion(song);
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(xpService.progression.totalXp, baseXP); 
    });

    test('play_validated should give XP and discovery bonus if applicable', () async {
      await xpService.initialize();
      final song = Song(id: 'discovery_1', title: 'T1');
      
      // First play -> Discovery
      await recService.trackSongPlay(song, durationPlayed: 30);
      await Future.delayed(const Duration(milliseconds: 50));

      // +2 for validation, +10 for discovery = 12 XP
      expect(xpService.progression.totalXp, 12);
      expect(dbService.transactions.any((t) => t['type'] == 'val'), true);
      expect(dbService.transactions.any((t) => t['type'] == 'disco'), true);

      // Second play of same song (not discovery anymore)
      await recService.trackSongPlay(song, durationPlayed: 30);
      await Future.delayed(const Duration(milliseconds: 50));

      // +2 XP (validation) 
      // AND +1 XP for time (30s first play + 30s second play = 60s = 1 XP)
      // Total: 12 + 2 + 1 = 15 XP
      expect(xpService.progression.totalXp, 15);
      expect(dbService.transactions.where((t) => t['type'] == 'disco').length, 1);
    });

    test('quest completion should give bonus XP', () async {
      await xpService.initialize();
      
      final dailyQuest = MusicQuestInstance(
        id: 101,
        definitionId: 'daily_listener',
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        status: QuestStatus.completed,
      );

      questService.emit(dailyQuest);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, 50);
      expect(dbService.transactions.any((t) => t['id'] == 'quest_101'), true);
      
      // Weekly quest
      final weeklyQuest = MusicQuestInstance(
        id: 102,
        definitionId: 'weekly_loyalty',
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
        status: QuestStatus.completed,
      );

      questService.emit(weeklyQuest);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(xpService.progression.totalXp, 250); // 50 + 200
    });

    test('XP events should be idempotent', () async {
      await xpService.initialize();
      final song = Song(id: 's1', title: 'T1');
      
      final timestamp = DateTime.now();
      
      // creditEventXp handles idempotence via FakeDbService
      final result = await dbService.creditEventXp(
        type: 'val',
        sourceId: "val_${song.id}_${timestamp.millisecondsSinceEpoch}",
        amount: 2,
      );
      expect(result, true);
      
      final result2 = await dbService.creditEventXp(
        type: 'val',
        sourceId: "val_${song.id}_${timestamp.millisecondsSinceEpoch}",
        amount: 2,
      );
      expect(result2, false);
    });
  });
}
