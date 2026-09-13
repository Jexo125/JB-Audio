import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/main.dart';
import 'package:jbaudio/providers/auth_provider.dart';
import 'package:jbaudio/services/locale_service.dart';
import 'package:jbaudio/services/theme_service.dart';
import 'package:jbaudio/services/subsonic_service.dart';
import 'package:jbaudio/services/storage_service.dart';
import 'package:jbaudio/services/music_quest_service.dart';

class FakeMusicQuestService extends Fake implements MusicQuestService {
  @override
  void dispose() {}
}

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    final subsonic = SubsonicService();
    final storage = StorageService();
    final musicQuestService = FakeMusicQuestService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<MusicQuestService>.value(value: musicQuestService),
          ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(subsonic, storage),
          ),
        ],
        child: MuslyApp(musicQuestService: musicQuestService),
      ),
    );
    expect(find.byType(MuslyApp), findsOneWidget);
  });
}
