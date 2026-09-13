import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/main.dart';
import 'package:jbaudio/providers/auth_provider.dart';
import 'package:jbaudio/services/locale_service.dart';
import 'package:jbaudio/services/theme_service.dart';
import 'package:jbaudio/services/subsonic_service.dart';
import 'package:jbaudio/services/storage_service.dart';
import 'package:jbaudio/services/music_quest_service.dart';
import 'package:jbaudio/services/xp_service.dart';
import 'package:jbaudio/models/models.dart';

class FakeMusicQuestService extends Fake implements MusicQuestService {
  @override
  bool get isInitialized => true;
  @override
  List<MusicQuestInstance> getActiveQuests() => [];
  @override
  Future<List<MusicQuestInstance>> getCompletedQuests() async => [];
  @override
  Stream<MusicQuestInstance> get onQuestUpdated => const Stream.empty();
  @override
  Future<void> initialize() async {}
  @override
  Future<Map<String, MusicQuestProgress>> getAllActiveProgress() async => {};
  @override
  MusicQuestPeriodRange getCurrentPeriodRange(QuestPeriodType type) => MusicQuestPeriodRange(DateTime.now(), DateTime.now());
  @override
  Future<MusicQuestProgress> getQuestProgress(MusicQuestInstance instance) async => MusicQuestProgress(currentValue: 0, targetValue: 1);
  @override
  void dispose() {}
}

class FakeXpService extends ChangeNotifier implements XpService {
  @override
  bool get isInitialized => true;
  @override
  UserProgression get progression => const UserProgression();
  @override
  ProgressionSnapshot get snapshot => ProgressionSnapshot.fromTotalXp(0);
  @override
  Stream<UserProgression> get onProgressionUpdated => const Stream.empty();
  @override
  Stream<ProgressionSnapshot> get onSnapshotUpdated => const Stream.empty();
  @override
  List<TitleSnapshot> getTitleSnapshots() => [];
  @override
  Future<void> initialize() async {}
  @override
  Future<void> checkTitles() async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    final subsonic = SubsonicService();
    final storage = StorageService();
    final musicQuestService = FakeMusicQuestService();
    final xpService = FakeXpService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MusicQuestService>.value(value: musicQuestService),
          ChangeNotifierProvider<XpService>.value(value: xpService),
          ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(subsonic, storage),
          ),
        ],
        child: MuslyApp(musicQuestService: musicQuestService, xpService: xpService),
      ),
    );
    expect(find.byType(MuslyApp), findsOneWidget);
  });
}
