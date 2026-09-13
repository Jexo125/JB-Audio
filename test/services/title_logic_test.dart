import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/models/models.dart';
import 'package:jbaudio/services/library_database_service.dart';
import 'package:jbaudio/services/recommendation_service.dart';
import 'package:jbaudio/services/music_quest_service.dart';
import 'package:jbaudio/services/statistics_service.dart';
import 'package:jbaudio/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeDbService extends Fake implements LibraryDatabaseService {
  UserProgression progression = const UserProgression();
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
  Future<bool> creditEventXp({required String type, required String sourceId, required int amount}) async => true;
  
  @override
  Future<void> insertListeningEvent({required String songId, required String eventType, required int durationSeconds, required int completed, required String timestamp}) async {}
}

class MockStatsService extends Fake implements StatisticsService {
  int listenTime = 0;
  int artistCount = 0;
  int albumCount = 0;
  int completedCount = 0;
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

class MockMusicQuestService extends Fake implements MusicQuestService {
  @override
  Stream<MusicQuestInstance> get onQuestUpdated => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Title Engine Logic Tests', () {
    late FakeDbService dbService;
    late RecommendationService recService;
    late MockStatsService statsService;
    late MockMusicQuestService questService;
    late XpService xpService;

    setUp(() async {
      dbService = FakeDbService();
      recService = RecommendationService();
      recService.dbService = dbService;
      await recService.initialize();
      statsService = MockStatsService();
      questService = MockMusicQuestService();
      xpService = XpService(dbService, recService, questService, statsService);
      await xpService.initialize();
    });

    test('should not unlock titles if thresholds are not met', () async {
      await xpService.checkTitles();
      final snapshots = xpService.getTitleSnapshots();
      expect(snapshots.every((s) => !s.isUnlocked), true);
    });

    test('should unlock Explorateur when artist count hits 20', () async {
      statsService.artistCount = 20;
      await xpService.checkTitles();
      
      final snapshots = xpService.getTitleSnapshots();
      final explorer = snapshots.firstWhere((s) => s.definition.id == 'title_explorer');
      expect(explorer.isUnlocked, true);
      expect(dbService.titles.any((t) => t['title_key'] == 'title_explorer'), true);
    });

    test('should unlock Mélomane when listen time hits 10h', () async {
      statsService.listenTime = 36000;
      await xpService.checkTitles();
      
      final snapshots = xpService.getTitleSnapshots();
      final melomane = snapshots.firstWhere((s) => s.definition.id == 'title_melomane');
      expect(melomane.isUnlocked, true);
    });

    test('idempotence: should not unlock twice', () async {
      statsService.artistCount = 20;
      await xpService.checkTitles();
      expect(dbService.titles.length, 1);
      
      await xpService.checkTitles();
      expect(dbService.titles.length, 1); // No new entry
    });

    test('persistence: should load previously unlocked titles', () async {
      dbService.titles.add({'title_key': 'title_pioneer', 'unlocked_at': DateTime.now().toIso8601String()});
      
      final newXpService = XpService(dbService, recService, questService, statsService);
      await newXpService.initialize();
      
      final snapshots = newXpService.getTitleSnapshots();
      expect(snapshots.firstWhere((s) => s.definition.id == 'title_pioneer').isUnlocked, true);
    });
  });
}
