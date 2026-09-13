import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/main.dart';
import 'package:jbaudio/providers/auth_provider.dart';
import 'package:jbaudio/services/services.dart';
import '../bootstrap.dart';

class FakeMusicQuestService extends Fake implements MusicQuestService {
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService),
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService),
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

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            Provider<MusicQuestService>.value(value: musicQuestService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: MaterialApp(
            home: MuslyApp(musicQuestService: musicQuestService),
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
