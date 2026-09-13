import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/main.dart';
import 'package:jbaudio/providers/auth_provider.dart';
import 'package:jbaudio/services/services.dart';
import 'package:jbaudio/models/models.dart';
import '../bootstrap.dart';

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
  initializeTestEnvironment();
  group('Musly App Integration Tests', () {
    testWidgets('should display login screen when not authenticated', (
      tester,
    ) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();
      final musicQuestService = FakeMusicQuestService();
      final xpService = FakeXpService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<XpService>.value(value: xpService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService, xpService: xpService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('JB Audio'), findsWidgets);
      expect(find.text('Connection au serveur de JB Audio'), findsOneWidget);
    });

    testWidgets('should have login form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();
      final musicQuestService = FakeMusicQuestService();
      final xpService = FakeXpService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<XpService>.value(value: xpService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService, xpService: xpService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Se Connecter'), findsOneWidget);
    });

    testWidgets('should validate empty form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();
      final musicQuestService = FakeMusicQuestService();
      final xpService = FakeXpService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<XpService>.value(value: xpService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService, xpService: xpService),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final connectButton = find.text('Se Connecter');
      await tester.ensureVisible(connectButton);
      await tester.tap(connectButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter server URL'), findsOneWidget);
      expect(find.text('Please enter username'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });
  });
}
