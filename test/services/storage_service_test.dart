import 'package:flutter_test/flutter_test.dart';
import 'package:jbaudio/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('saveDiscordRpcEnabled saves value', () async {
      await storageService.saveDiscordRpcEnabled(true);
      expect(await storageService.getDiscordRpcEnabled(), true);
    });

    test('getDiscordRpcEnabled returns true by default', () async {
      expect(await storageService.getDiscordRpcEnabled(), true);
    });

    test('saveDiscordRpcEnabled updates value', () async {
      await storageService.saveDiscordRpcEnabled(true);
      expect(await storageService.getDiscordRpcEnabled(), true);
      await storageService.saveDiscordRpcEnabled(false);
      expect(await storageService.getDiscordRpcEnabled(), false);
    });

    test('getAudioDuckingEnabled returns true by default', () async {
      expect(await storageService.getAudioDuckingEnabled(), true);
    });

    test('saveAudioDuckingEnabled updates value', () async {
      await storageService.saveAudioDuckingEnabled(false);
      expect(await storageService.getAudioDuckingEnabled(), false);
      await storageService.saveAudioDuckingEnabled(true);
      expect(await storageService.getAudioDuckingEnabled(), true);
    });
  });
}
