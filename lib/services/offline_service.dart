import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/song.dart';
import 'subsonic_service.dart';

enum DownloadStatus { queued, downloading, done, failed }

class DownloadLogEntry {
  final Song song;
  final DownloadStatus status;
  const DownloadLogEntry(this.song, this.status);
  DownloadLogEntry copyWith({DownloadStatus? status}) =>
      DownloadLogEntry(song, status ?? this.status);
}

class DownloadState {
  final bool isDownloading;
  final int currentProgress;
  final int totalCount;
  final int downloadedCount;
  final Song? currentSong;
  final List<Song> failedSongs;

  DownloadState({
    this.isDownloading = false,
    this.currentProgress = 0,
    this.totalCount = 0,
    this.downloadedCount = 0,
    this.currentSong,
    this.failedSongs = const [],
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? currentProgress,
    int? totalCount,
    int? downloadedCount,
    Song? currentSong,
    bool clearCurrentSong = false,
    List<Song>? failedSongs,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: totalCount ?? this.totalCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      failedSongs: failedSongs ?? this.failedSongs,
    );
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  SharedPreferences? _prefs;
  String? _offlineDir;

  bool _offlineMode = false;
  bool get isOfflineMode => _offlineMode;
  void setOfflineMode(bool value) { _offlineMode = value; }

  final ValueNotifier<DownloadState> downloadState = ValueNotifier(DownloadState());
  final ValueNotifier<Set<String>> downloadedSongIds = ValueNotifier({});
  final ValueNotifier<List<DownloadLogEntry>> downloadLog = ValueNotifier([]);

  bool _isBackgroundDownloadActive = false;
  bool get isBackgroundDownloadActive => _isBackgroundDownloadActive;

  static const String _keyDownloadedSongs = 'offline_downloaded_songs';
  static const String _keyExpectedSizes = 'offline_expected_sizes';
  static const String _keyQueuedPlaylists = 'offline_queued_playlists';
  static const String _keyQueuedPlaylistData = 'offline_queued_playlist_data';
  static const String _keyDownloadedPlaylists = 'offline_downloaded_playlists';
  static const String _keyParallelDownloads = 'parallel_downloads_count';

  static const String _keyKeepScreenOn = 'offline_keep_screen_on';

  static const int _defaultParallelDownloads = 3;
  Map<String, int> _expectedSizes = {};

  final ValueNotifier<Set<String>> queuedPlaylistIds = ValueNotifier({});
  final ValueNotifier<Set<String>> downloadedPlaylistIds = ValueNotifier({});

  Map<String, List<Map<String, dynamic>>> _queuedPlaylistData = {};
  final List<({String playlistId, List<Song> songs, SubsonicService service})> _downloadQueue = [];

  int getParallelDownloadsCount() =>
      _prefs?.getInt(_keyParallelDownloads) ?? _defaultParallelDownloads;

  Future<void> setParallelDownloadsCount(int count) async {
    await _prefs?.setInt(_keyParallelDownloads, count);
  }

  bool getKeepScreenOn() => _prefs?.getBool(_keyKeepScreenOn) ?? false;

  Future<void> setKeepScreenOn(bool value) async {
    await _prefs?.setBool(_keyKeepScreenOn, value);
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<int> getDownloadedSize() async {
    if (_offlineDir == null) return 0;
    int total = 0;
    final dir = Directory(_offlineDir!);
    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          total += await file.length();
        }
      }
    }
    return total;
  }

  String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  Future<void> startBackgroundDownload(
    List<Song> songs,
    SubsonicService service,
  ) async {
    if (_isBackgroundDownloadActive) return;
    _isBackgroundDownloadActive = true;

    // Simple implementation for background download
    for (final song in songs) {
      if (!_isBackgroundDownloadActive) break;
      if (!isSongDownloaded(song.id)) {
        await downloadSong(song, service);
      }
    }

    _isBackgroundDownloadActive = false;
  }

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    _offlineDir = '${dir.path}/offline_music';

    final offlineDirectory = Directory(_offlineDir!);
    if (!await offlineDirectory.exists()) {
      await offlineDirectory.create(recursive: true);
    }

    final sizesJson = _prefs?.getString(_keyExpectedSizes);
    if (sizesJson != null) {
      try {
        final raw = json.decode(sizesJson) as Map<String, dynamic>;
        _expectedSizes = raw.map((k, v) => MapEntry(k, v as int));
      } catch (_) {}
    }

    final prefsIds = getDownloadedSongIds().toSet();
    final diskIds = <String>{};
    final offDir = Directory(_offlineDir!);
    if (await offDir.exists()) {
      await for (final entity in offDir.list()) {
        if (entity is File && entity.path.endsWith('.mp3')) {
          final songId = entity.path.split('/').last.replaceAll('.mp3', '');
          if (_isFileValid(songId, entity)) {
            diskIds.add(songId);
          }
        }
      }
    }

    final merged = {...prefsIds, ...diskIds};
    if (merged.length != prefsIds.length) {
      await _prefs?.setStringList(_keyDownloadedSongs, merged.toList());
    }
    downloadedSongIds.value = merged;

    final queuedIds = _prefs?.getStringList(_keyQueuedPlaylists) ?? [];
    final queuedDataJson = _prefs?.getString(_keyQueuedPlaylistData);
    if (queuedDataJson != null) {
      try {
        final raw = json.decode(queuedDataJson) as Map<String, dynamic>;
        _queuedPlaylistData = raw.map(
              (k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()),
        );
      } catch (_) {}
    }
    queuedPlaylistIds.value = queuedIds.toSet();

    final downloadedPlaylistList = _prefs?.getStringList(_keyDownloadedPlaylists) ?? [];
    downloadedPlaylistIds.value = downloadedPlaylistList.toSet();
  }

  Future<void> queuePlaylistDownload(String playlistId, List<Song> songs, SubsonicService subsonicService) async {
    if (_offlineDir == null) await initialize();
    _queuedPlaylistData[playlistId] = songs.map((s) => s.toJson()).toList();
    queuedPlaylistIds.value = {...queuedPlaylistIds.value, playlistId};
    await _prefs?.setStringList(_keyQueuedPlaylists, queuedPlaylistIds.value.toList());
    await _prefs?.setString(_keyQueuedPlaylistData, json.encode(_queuedPlaylistData));

    final missing = songs.where((s) => !isSongDownloaded(s.id)).toList();
    if (missing.isEmpty) return;
    _downloadQueue.add((playlistId: playlistId, songs: missing, service: subsonicService));
  }

  void cancelPlaylistDownload(String playlistId) {
    _downloadQueue.removeWhere((entry) => entry.playlistId == playlistId);
    _queuedPlaylistData.remove(playlistId);
    queuedPlaylistIds.value = queuedPlaylistIds.value.difference({playlistId});
    _prefs?.setStringList(_keyQueuedPlaylists, queuedPlaylistIds.value.toList());
    _prefs?.setString(_keyQueuedPlaylistData, json.encode(_queuedPlaylistData));
  }

  Future<void> deletePlaylistDownloads(String playlistId, List<Song> songs) async {
    for (final song in songs) {
      await deleteSong(song.id);
    }
    final downloadedPlaylists = downloadedPlaylistIds.value.toSet()..remove(playlistId);
    downloadedPlaylistIds.value = downloadedPlaylists;
    await _prefs?.setStringList(_keyDownloadedPlaylists, downloadedPlaylists.toList());
  }

  bool _isFileValid(String songId, File file) {
    try {
      final len = file.lengthSync();
      final expected = _expectedSizes[songId];
      if (expected != null && expected > 0) return len >= expected;
      return len >= 65536;
    } catch (_) { return false; }
  }

  String _getSongPath(String songId) => '$_offlineDir/$songId.mp3';
  String _getLyricsPath(String songId) => '$_offlineDir/$songId.lyrics.json';
  String _getCoverArtPath(String songId) => '$_offlineDir/$songId.jpg';

  String? getLocalCoverArtPathByCoverArtId(String? coverArtId) {
    if (coverArtId == null || coverArtId.isEmpty || _offlineDir == null) {
      return null;
    }
    final path = _getCoverArtPath(coverArtId);
    if (File(path).existsSync()) return path;
    return null;
  }

  bool isSongDownloaded(String songId) => File(_getSongPath(songId)).existsSync() && _isFileValid(songId, File(_getSongPath(songId)));

  Future<Map<String, dynamic>?> getLocalLyrics(String songId) async {
    final file = File(_getLyricsPath(songId));
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  List<String> getDownloadedSongIds() => _prefs?.getStringList(_keyDownloadedSongs) ?? [];
  int getDownloadedCount() => getDownloadedSongIds().length;

  Future<bool> downloadSong(
    Song song,
    SubsonicService subsonicService, {
    void Function(double)? onProgress,
  }) async {
    if (_offlineDir == null) await initialize();
    final filePath = _getSongPath(song.id);
    try {
      final url = subsonicService.getDownloadUrl(song.id);
      final dio = Dio();
      await dio.download(
        url,
        filePath,
        onReceiveProgress: (count, total) {
          if (total > 0 && onProgress != null) {
            onProgress(count / total);
          }
        },
      );
      if (!isSongDownloaded(song.id)) throw Exception('Size check failed');

      final downloadedIds = getDownloadedSongIds();
      if (!downloadedIds.contains(song.id)) {
        downloadedIds.add(song.id);
        await _prefs?.setStringList(_keyDownloadedSongs, downloadedIds);
      }
      downloadedSongIds.value = {...downloadedSongIds.value, song.id};
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> flushPendingScrobbles(SubsonicService service) async {}

  Future<void> deleteAllDownloads() async {
    if (_offlineDir != null) {
      final dir = Directory(_offlineDir!);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }
    }
    downloadedSongIds.value = {};
    await _prefs?.remove(_keyDownloadedSongs);
  }

  void cancelBackgroundDownload() { _isBackgroundDownloadActive = false; }

  Future<void> deleteSong(String songId) async {
    final files = [File(_getSongPath(songId)), File(_getLyricsPath(songId)), File(_getCoverArtPath(songId))];
    for (var f in files) { if (await f.exists()) await f.delete(); }
    final ids = getDownloadedSongIds()..remove(songId);
    await _prefs?.setStringList(_keyDownloadedSongs, ids);
    downloadedSongIds.value = ids.toSet();
  }
}