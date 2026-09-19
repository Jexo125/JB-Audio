import 'package:flutter/material.dart';
import 'package:jbaudio/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:jbaudio/providers/providers.dart';
import 'package:jbaudio/services/services.dart';
import 'package:jbaudio/services/audio_handler.dart';
import 'package:jbaudio/services/transcoding_service.dart';
import 'package:jbaudio/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCastService extends CastService {
  @override
  bool get isConnected => false;

  @override
  Future<bool> loadMedia({
    required String url,
    required String title,
    required String artist,
    required String imageUrl,
    String? albumName,
    int? trackNumber,
    Duration? duration,
    bool autoPlay = true,
  }) async {
    return true;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}
}

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
  bool get isEnabled => true;

  @override
  Future<void> setEnabled(bool value) async {}

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

Widget createTestApp({
  required Widget child,
  SubsonicService? subsonicService,
  StorageService? storageService,
  PlayerProvider? playerProvider,
  LibraryProvider? libraryProvider,
  AuthProvider? authProvider,
  XpService? xpService,
  MusicQuestService? musicQuestService,
}) {
  final service = subsonicService ?? SubsonicService();
  final storage = storageService ?? StorageService();

  return MultiProvider(
    providers: [
      Provider<SubsonicService>.value(value: service),
      Provider<StorageService>.value(value: storage),
      Provider<MusicQuestService>.value(value: musicQuestService ?? FakeMusicQuestService()),
      ChangeNotifierProvider<XpService>.value(value: xpService ?? FakeXpService()),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => authProvider ?? AuthProvider(service, storage),
      ),
      ChangeNotifierProvider<PlayerProvider>(
        create: (_) =>
            playerProvider ??
            PlayerProvider(service, storage, FakeCastService(), UpnpService(),
                MuslyAudioHandler(), JukeboxService(), TranscodingService()),
      ),
      ChangeNotifierProvider<LibraryProvider>(
        create: (_) => libraryProvider ?? LibraryProvider(service, MuslyAudioHandler()),
      ),
      ChangeNotifierProvider<TranscodingService>(
          create: (_) => TranscodingService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

List<dynamic> createTestSongJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'song_${index + 1}',
      'title': 'Song ${index + 1}',
      'artist': 'Artist ${(index % 3) + 1}',
      'album': 'Album ${(index % 5) + 1}',
      'duration': 180 + (index * 10),
      'track': index + 1,
    },
  );
}

List<dynamic> createTestAlbumJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'album_${index + 1}',
      'name': 'Album ${index + 1}',
      'artist': 'Artist ${(index % 3) + 1}',
      'songCount': 10 + (index % 5),
      'duration': 3600 + (index * 100),
      'year': 2020 + (index % 4),
    },
  );
}

List<dynamic> createTestArtistJsonList(int count) {
  return List.generate(
    count,
    (index) => {
      'id': 'artist_${index + 1}',
      'name': 'Artist ${index + 1}',
      'albumCount': 5 + (index % 10),
    },
  );
}
