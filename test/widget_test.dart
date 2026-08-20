import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/main.dart';
import 'package:jbaudio/providers/auth_provider.dart';
import 'package:jbaudio/services/locale_service.dart';
import 'package:jbaudio/services/theme_service.dart';
import 'package:jbaudio/services/subsonic_service.dart';
import 'package:jbaudio/services/storage_service.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    final subsonic = SubsonicService();
    final storage = StorageService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(subsonic, storage),
          ),
        ],
        child: const MuslyApp(),
      ),
    );
    expect(find.byType(MuslyApp), findsOneWidget);
  });
}
