import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:audio_session/audio_session.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../services/auto_dj_service.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import '../services/upnp_service.dart';
import '../services/jukebox_service.dart';
import '../services/audio_handler.dart';

import '../services/transcoding_service.dart';
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SubsonicService _subsonicService;
  late final StorageService _storageService;
  final MuslyAudioHandler _audioHandler;
  AudioPlayer get _audioPlayer => _audioHandler.player;
  final AutoDjService _autoDjService = AutoDjService();
  final CastService _castService;
  late final UpnpService _upnpService;

  RecommendationService? _recommendationService;
  VoidCallback? onAudioFocusDenied;

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _shuffleEnabled = false;
  final bool _gaplessEnabled = true;
  final List<String> _shuffleHistory = [];
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  double _volume = 1.0;

  bool _isRenderingRemotely = false;
  String? _resolvedArtworkUrl;

  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  SharedPreferences? _prefs;
  Timer? _persistDebounceTimer;
  static const String _keyQueue = 'persistent_queue';
  static const String _keyQueueIndex = 'persistent_queue_index';
  static const String _keyQueueSongId = 'persistent_queue_song_id';
  static const String _keyQueuePosition = 'persistent_queue_position_ms';

  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  bool _sleepTimerEndCurrentSong = false;
  bool _sleepTimerFadeOut = false;
  int _sleepTimerFadeDurationSeconds = 30;
  Timer? _sleepTimerFadeTimer;
  Timer? _sleepTimerFadePeriodicTimer;
  Timer? _jukeboxPollTimer;

  final JukeboxService _jukeboxService;
  final TranscodingService _transcodingService;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  bool _pitchCorrection = true;

  bool _isSeeking = false;
  DateTime _lastSeekTime = DateTime.now();

  PlayerProvider(
      this._subsonicService,
      StorageService storageService,
      this._castService,
      this._upnpService,
      this._audioHandler,
      this._jukeboxService,
      this._transcodingService,
      ) {
    _storageService = storageService;
    _castService.addListener(_onCastStateChanged);
    _upnpService.addListener(_onUpnpStateChanged);
    _upnpService.onRendererLost = _onUpnpRendererLost;
    _jukeboxService.addListener(_onJukeboxEnabledChanged);
    _initializePlayer();
    _onJukeboxEnabledChanged();
    try {
      _initializeAndroidAuto();
    } catch (_) {}
    _initializeAutoDj();
    _wireAudioHandlerCallbacks();

    _restoreQueueState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint('[Player] App lifecycle state: $state - saving queue state');
      _saveQueueStateImmediate();
    }
  }

  void _wireAudioHandlerCallbacks() {
    _audioHandler.onPlay = play;
    _audioHandler.onPause = pause;
    _audioHandler.onStop = stop;
    _audioHandler.onSkipNext = skipNext;
    _audioHandler.onSkipPrevious = skipPrevious;
    _audioHandler.onSeekTo = seek;
    _audioHandler.onTogglePlayPause = togglePlayPause;
  }

  void _saveQueueState() {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      await _saveQueueStateImmediate();
    });
  }

  Future<void> _saveQueueStateImmediate() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;
      final queueJson = _queue.map((s) => s.toJson()).toList();
      await _prefs!.setString(_keyQueue, jsonEncode(queueJson));
      await _prefs!.setInt(_keyQueueIndex, _currentIndex);
      await _prefs!.setString(_keyQueueSongId, _currentSong?.id ?? '');
      await _prefs!.setInt(_keyQueuePosition, _position.inMilliseconds);
    } catch (e) {
      debugPrint('Error saving queue state: $e');
    }
  }

  Future<void> _restoreQueueState() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;

      final queueRaw = _prefs!.getString(_keyQueue);
      if (queueRaw == null || queueRaw.isEmpty) return;

      final queueJson = jsonDecode(queueRaw) as List<dynamic>;
      if (queueJson.isEmpty) return;

      final restoredSongs = queueJson
          .map((j) => Song.fromJson(j as Map<String, dynamic>))
          .where((s) {
        if (s.isLocal && s.path != null) {
          return File(s.path!).existsSync();
        }
        return true;
      }).toList();

      if (restoredSongs.isEmpty) return;

      final savedIndex = _prefs!.getInt(_keyQueueIndex) ?? 0;
      final savedSongId = _prefs!.getString(_keyQueueSongId);
      final savedPositionMs = _prefs!.getInt(_keyQueuePosition) ?? 0;

      var targetIndex = savedIndex.clamp(0, restoredSongs.length - 1);
      if (savedSongId != null && savedSongId.isNotEmpty) {
        final idIndex = restoredSongs.indexWhere((s) => s.id == savedSongId);
        if (idIndex != -1) targetIndex = idIndex;
      }

      _queue = restoredSongs;
      _currentIndex = targetIndex;
      _currentSong = restoredSongs[targetIndex];
      _position = Duration(milliseconds: savedPositionMs);
      final songDurationSecs = restoredSongs[targetIndex].duration;
      if (songDurationSecs != null && songDurationSecs > 0) {
        _duration = Duration(seconds: songDurationSecs);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring queue state: $e');
    }
  }

  void _clearPersistedQueue() {
    _persistDebounceTimer?.cancel();
    try {
      SharedPreferences.getInstance().then((p) {
        p.remove(_keyQueue);
        p.remove(_keyQueueIndex);
        p.remove(_keyQueueSongId);
      });
    } catch (_) {}
  }

  void _onJukeboxEnabledChanged() {
    if (_jukeboxService.enabled) {
      _startJukeboxPolling();
    } else {
      _stopJukeboxPolling();
    }
  }

  void _startJukeboxPolling() {
    _stopJukeboxPolling();
    _jukeboxPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollJukebox();
    });
    _pollJukebox();
  }

  void _stopJukeboxPolling() {
    _jukeboxPollTimer?.cancel();
    _jukeboxPollTimer = null;
  }

  Future<void> _pollJukebox() async {
    if (!_jukeboxService.enabled) return;
    try {
      await _jukeboxService.refresh(_subsonicService);
      _syncFromJukeboxStatus();
    } catch (e) {
      debugPrint('Jukebox poll error: $e');
    }
  }

  void _syncFromJukeboxStatus() {
    if (!_jukeboxService.enabled) return;
    final status = _jukeboxService.status;
    final song = status.currentSong;

    bool changed = false;
    if (song != null && song.id != _currentSong?.id) {
      _currentSong = song;
      _resolvedArtworkUrl = null;
      changed = true;
    }
    final isPlayingStatus = status.playing;
    if (_isPlaying != isPlayingStatus) {
      _isPlaying = isPlayingStatus;
      changed = true;
    }
    final positionStatus = status.position;
    if (_position != positionStatus) {
      _position = positionStatus;
      changed = true;
    }
    final playlistStatus = status.playlist;
    if (playlistStatus.isNotEmpty && !identical(_queue, playlistStatus)) {
      _queue = List.from(playlistStatus);
      changed = true;
    }
    final clampedIndex = status.currentIndex.clamp(
      0,
      (_queue.length - 1).clamp(0, double.maxFinite.toInt()),
    );
    if (_currentIndex != clampedIndex) {
      _currentIndex = clampedIndex;
      changed = true;
    }
    if (changed) {
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    // _libraryProvider = libraryProvider;
  }

  void setRecommendationService(RecommendationService recommendationService) {
    _recommendationService = recommendationService;
    _autoDjService.setServices(_subsonicService, recommendationService);
  }

  AutoDjService get autoDjService => _autoDjService;

  Future<void> _initializeAutoDj() async {
    await _autoDjService.initialize();
    _autoDjService.setServices(_subsonicService, _recommendationService);
  }

  void _initializeAndroidAuto() {
    _audioHandler.onGetAlbumSongs = _getAlbumSongsForAndroidAuto;
    _audioHandler.onGetArtistAlbums = _getArtistAlbumsForAndroidAuto;
    _audioHandler.onGetPlaylistSongs = _getPlaylistSongsForAndroidAuto;
    _audioHandler.onSearch = _searchForAndroidAuto;
    _audioHandler.onPlayFromMediaId = _playFromMediaId;
    _audioHandler.onPlayFromSearch = _playFromSearchForAndroidAuto;
    _audioHandler.onSetRemoteVolume = _onRemoteVolumeChange;
  }

  Future<List<Map<String, String>>> _getAlbumSongsForAndroidAuto(
      String albumId,
      ) async {
    try {
      final songs = await _subsonicService.getAlbumSongs(albumId);
      return songs
          .map(
            (song) => {
          'id': song.id,
          'title': song.title,
          'artist': song.artist ?? '',
          'album': song.album ?? '',
          'artworkUrl': _subsonicService.getCoverArtUrl(
            song.coverArt,
            size: 300,
          ),
          'duration': (song.duration ?? 0).toString(),
        },
      )
          .toList();
    } catch (e) {
      debugPrint('Error getting album songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getArtistAlbumsForAndroidAuto(
      String artistId,
      ) async {
    try {
      final albums = await _subsonicService.getArtistAlbums(artistId);
      return albums
          .map(
            (album) => {
          'id': album.id,
          'name': album.name,
          'artist': album.artist ?? '',
          'artworkUrl': _subsonicService.getCoverArtUrl(
            album.coverArt,
            size: 300,
          ),
        },
      )
          .toList();
    } catch (e) {
      debugPrint('Error getting artist albums for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getPlaylistSongsForAndroidAuto(
      String playlistId,
      ) async {
    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);
      final songs = playlist.songs ?? [];
      return songs
          .map(
            (song) => {
          'id': song.id,
          'title': song.title,
          'artist': song.artist ?? '',
          'album': song.album ?? '',
          'artworkUrl': _subsonicService.getCoverArtUrl(
            song.coverArt,
            size: 300,
          ),
          'duration': (song.duration ?? 0).toString(),
        },
      )
          .toList();
    } catch (e) {
      debugPrint('Error getting playlist songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _searchForAndroidAuto(
      String query,
      ) async {
    try {
      final results = await _subsonicService.search(query);
      return results.songs
          .map(
            (song) => {
          'id': song.id,
          'title': song.title,
          'artist': song.artist ?? '',
          'album': song.album ?? '',
          'artworkUrl': _subsonicService.getCoverArtUrl(
            song.coverArt,
            size: 300,
          ),
          'duration': (song.duration ?? 0).toString(),
        },
      )
          .toList();
    } catch (e) {
      debugPrint('Android Auto search error: $e');
      return [];
    }
  }

  Future<void> _playFromSearchForAndroidAuto(String query) async {
    try {
      if (query.trim().isEmpty) {
        if (_currentSong != null) {
          await play();
        }
        return;
      }
      final results = await _subsonicService.search(query);
      if (results.songs.isNotEmpty) {
        await playSong(
          results.songs.first,
          playlist: results.songs,
          startIndex: 0,
        );
      }
    } catch (e) {
      debugPrint('Android Auto playFromSearch error: $e');
    }
  }

  Future<void> _playFromMediaId(String mediaId) async {
    final queueIndex = _queue.indexWhere((song) => song.id == mediaId);
    if (queueIndex != -1) {
      await skipToIndex(queueIndex);
      return;
    }
    try {
      final searchResults = await _subsonicService.search(mediaId);
      if (searchResults.songs.isNotEmpty) {
        final song = searchResults.songs.firstWhere(
              (s) => s.id == mediaId,
          orElse: () => searchResults.songs.first,
        );
        await playSong(song);
      }
    } catch (e) {
      debugPrint('Android Auto error fetching song: $e');
    }
  }

  String? _resolveArtworkUrl() {
    if (_currentSong == null) return null;
    if (_currentSong!.coverArt == null) return null;
    if (_currentSong!.isLocal) {
      return Uri.file(_currentSong!.coverArt!).toString();
    }
    return _resolvedArtworkUrl;
  }

  Future<void> _refreshArtworkUrl() async {
    final song = _currentSong;
    if (song == null || song.coverArt == null) {
      _resolvedArtworkUrl = null;
      return;
    }
    if (song.isLocal) {
      _resolvedArtworkUrl = Uri.file(song.coverArt!).toString();
      return;
    }

    final coverArtId = song.coverArt!;
    for (final sz in [1200, 800, 600, 400, 300, 200]) {
      for (final key in ['${coverArtId}_natural_$sz', '${coverArtId}_$sz']) {
        try {
          final fileInfo = await DefaultCacheManager().getFileFromCache(key);
          if (fileInfo != null && fileInfo.file.existsSync()) {
            if (_currentSong?.id == song.id) {
              _resolvedArtworkUrl = Uri.file(fileInfo.file.path).toString();
            }
            return;
          }
        } catch (_) {}
      }
    }
    _resolvedArtworkUrl = _subsonicService.getCoverArtUrl(coverArtId, size: 1200);
  }

  void _updateAndroidAuto() {
    if (_currentSong == null) return;
    final artworkUrl = _resolveArtworkUrl();
    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _audioHandler.updateNowPlaying(
      id: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
    );

    if (_isRenderingRemotely || _jukeboxService.enabled) {
      _audioHandler.updateRemotePlaybackState(
        playing: _isPlaying,
        position: _position,
      );
    }
  }

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get isRemotePlayback => _isRenderingRemotely;
  bool get shuffleEnabled => _shuffleEnabled;
  bool get gaplessEnabled => _gaplessEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentSong;
  bool get hasNext =>
      _queue.isNotEmpty &&
          (_currentIndex < _queue.length - 1 ||
              _repeatMode == RepeatMode.all ||
              (_shuffleEnabled && _queue.length > 1));
  bool get hasPrevious =>
      _queue.isNotEmpty &&
          (_currentIndex > 0 ||
              _repeatMode == RepeatMode.all ||
              (_shuffleEnabled && _shuffleHistory.isNotEmpty));
  double get volume => _volume;

  RadioStation? get currentRadioStation => _currentRadioStation;
  bool get isPlayingRadio => _isPlayingRadio;

  final _positionController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionController.stream;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;

  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }

  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  bool get pitchCorrection => _pitchCorrection;

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 4.0);
    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(_playbackSpeed, _pitch);
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }
    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    final success = await _audioHandler.setPlaybackParameters(_playbackSpeed, _pitch);
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }
    notifyListeners();
  }

  Future<void> togglePitchCorrection() async {
    _pitchCorrection = !_pitchCorrection;
    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);
    final success = await _audioHandler.setPlaybackParameters(_playbackSpeed, _pitch);
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }
    notifyListeners();
  }

  bool get hasSleepTimer => _sleepTimer != null;
  bool get sleepTimerEndCurrentSong => _sleepTimerEndCurrentSong;
  bool get sleepTimerFadeOut => _sleepTimerFadeOut;
  int get sleepTimerFadeDurationSeconds => _sleepTimerFadeDurationSeconds;

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void setSleepTimer(
      Duration duration, {
        bool endCurrentSong = false,
        bool fadeOut = false,
        int fadeDurationSeconds = 30,
      }) {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerEndCurrentSong = endCurrentSong;
    _sleepTimerFadeOut = fadeOut;
    _sleepTimerFadeDurationSeconds = fadeDurationSeconds;

    if (duration > Duration.zero) {
      _sleepTimerEnd = DateTime.now().add(duration);
      if (fadeOut) {
        final fadeStart = duration - Duration(seconds: fadeDurationSeconds);
        if (fadeStart > Duration.zero) {
          _sleepTimerFadeTimer = Timer(fadeStart, () => _startFadeOut(fadeDurationSeconds));
        } else {
          _startFadeOut(fadeDurationSeconds);
        }
      }

      _sleepTimer = Timer(duration, () {
        if (endCurrentSong) {
          _sleepTimerEndCurrentSong = true;
          _sleepTimer = null;
          _sleepTimerEnd = null;
          notifyListeners();
        } else {
          _doSleepTimerStop();
        }
      });
    }
    notifyListeners();
  }

  void _startFadeOut([int fadeDurationSeconds = 30]) {
    _sleepTimerFadePeriodicTimer?.cancel();
    final steps = fadeDurationSeconds.clamp(5, 300);
    const stepDuration = Duration(seconds: 1);
    final originalVolume = _volume;
    int step = 0;
    _sleepTimerFadePeriodicTimer = Timer.periodic(stepDuration, (t) {
      step++;
      final newVolume = originalVolume * (1.0 - step / steps);
      _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
      if (step >= steps) {
        t.cancel();
        _sleepTimerFadePeriodicTimer = null;
      }
    });
  }

  void _doSleepTimerStop() {
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _audioPlayer.setVolume(_volume);
    pause();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerFadeOut = false;
    _sleepTimerFadeDurationSeconds = 30;
    _sleepTimerEndCurrentSong = false;
    notifyListeners();
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerEndCurrentSong = false;
    _sleepTimerFadeOut = false;
    _sleepTimerFadeDurationSeconds = 30;
    _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  Future<void> _initializePlayer() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      _volume = _audioPlayer.volume;

      _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;

        if (_isPlaying != wasPlaying) {
          if (_isPlaying) {
            // notifyListeners() is enough, positionStream handles the rest
          } else {
            _saveQueueState();
          }
          notifyListeners();
          _updateAndroidAuto();
        }

        if (state.processingState == ProcessingState.completed) {
          if (_sleepTimerEndCurrentSong) {
            _doSleepTimerStop();
          } else {
            _handleSongCompletion();
          }
        }
      });

      _positionSub = _audioPlayer.positionStream.listen((pos) {
        if (!_isRenderingRemotely) {
          // Ignore updates during and immediately after a seek to prevent slider "jump back"
          if (_isSeeking || DateTime.now().difference(_lastSeekTime) < const Duration(milliseconds: 1000)) {
            return;
          }
          _position = pos;
          _positionController.add(pos);
          notifyListeners();
          
          // Debounce queue state saving - only save every few seconds or when paused
          // (Already handled by _saveQueueState debouncer)
          _saveQueueState();
        }
      });

      _durationSub = _audioPlayer.durationStream.listen((dur) {
        if (dur != null && dur > Duration.zero) {
          _duration = dur;
          notifyListeners();
        }
      });

      _currentIndexSub = _audioPlayer.currentIndexStream.listen((index) {
        if (index != null && index != _currentIndex && _queue.isNotEmpty) {
          if (index < _queue.length) {
            _currentIndex = index;
            _currentSong = _queue[index];
            _duration = Duration(seconds: _currentSong?.duration ?? 0);
            _refreshArtworkUrl();
            notifyListeners();
            _updateAndroidAuto();
            _recordPlaybackHistory(_currentSong);
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  Future<void> _handleSongCompletion() async {
    if (_shuffleEnabled) {
      await skipNext();
      return;
    }
    if (_currentIndex < _queue.length - 1) {
      await skipNext();
    } else if (_repeatMode == RepeatMode.all) {
      await skipToIndex(0);
    } else {
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();

      if (_autoDjService.isEnabled) {
        try {
          final nextSong = await _autoDjService.getNextSong(_subsonicService);
          if (nextSong != null) {
            await addToQueue(nextSong);
            await skipNext();
          }
        } catch (e) {
          debugPrint('Auto-DJ error: $e');
        }
      }
    }
  }

  Future<void> playSong(Song song, {List<Song>? playlist, int startIndex = 0}) async {
    try {
      _isPlayingRadio = false;
      _currentRadioStation = null;

      if (playlist != null && playlist.isNotEmpty) {
        _queue = List.from(playlist);
        _currentIndex = startIndex.clamp(0, _queue.length - 1);
      } else {
        _queue = [song];
        _currentIndex = 0;
      }

      _currentSong = _queue[_currentIndex];
      _position = Duration.zero;
      _duration = Duration(seconds: _currentSong?.duration ?? 0);
      _resolvedArtworkUrl = null;
      notifyListeners();
      _refreshArtworkUrl();

      await _prepareAndPlayCurrentSong();
      _recordPlaybackHistory(_currentSong);
      _clearPersistedQueue();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> _prepareAndPlayCurrentSong() async {
    if (_currentSong == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (_isRenderingRemotely) {
        await _playRemotely(_currentSong!);
        _isLoading = false;
        _isPlaying = true;
        notifyListeners();
        _updateAndroidAuto();
        return;
      }

      if (_jukeboxService.enabled) {
        await _jukeboxService.setQueue(_subsonicService, [_currentSong!]);
        _isLoading = false;
        _isPlaying = true;
        notifyListeners();
        _updateAndroidAuto();
        return;
      }

      Uri audioUri;
      if (_currentSong!.isLocal && _currentSong!.path != null) {
        audioUri = Uri.file(_currentSong!.path!);
      } else {
        audioUri = _transcodingService.getStreamUri(
          _currentSong!.id,
          serverUrl: _subsonicService.config?.serverUrl ?? '',
          username: _subsonicService.config?.username ?? '',
          password: _subsonicService.config?.password ?? '',
        );
      }

      await _audioPlayer.setUrl(audioUri.toString());
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error preparing audio source: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  Future<void> play() async {
    if (_currentRadioStation != null) {
      await playRadioStation(_currentRadioStation!);
      return;
    }
    if (_currentSong == null && _queue.isNotEmpty) {
      _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
      _currentSong = _queue[_currentIndex];
    }
    if (_currentSong == null) return;

    if (_isRenderingRemotely) {
      await _playRemotely(_currentSong!);
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    if (_jukeboxService.enabled) {
      await _jukeboxService.play(_subsonicService);
      return;
    }

    if (_audioPlayer.audioSource == null) {
      await _prepareAndPlayCurrentSong();
    } else {
      await _audioPlayer.play();
    }
    _isPlaying = true;
    notifyListeners();
    _updateAndroidAuto();
  }

  Future<void> pause() async {
    if (_isRenderingRemotely) {
      await _pauseRemotely();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    if (_jukeboxService.enabled) {
      await _jukeboxService.pause(_subsonicService);
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
    _updateAndroidAuto();
    _saveQueueState();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    if (_isRenderingRemotely) {
      await _stopRemotely();
    }
    await _audioPlayer.stop();
    _isPlaying = false;
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
    _clearPersistedQueue();
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;

    if (_shuffleEnabled) {
      if (_currentIndex != -1) {
        _shuffleHistory.add(_currentIndex.toString());
      }
      final random = Random();
      final nextIndex = random.nextInt(_queue.length);
      await skipToIndex(nextIndex);
      return;
    }

    if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
    } else if (_repeatMode == RepeatMode.all) {
      await skipToIndex(0);
    }
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;

    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_shuffleEnabled && _shuffleHistory.isNotEmpty) {
      final lastIndexStr = _shuffleHistory.removeLast();
      final lastIndex = int.tryParse(lastIndexStr) ?? 0;
      await skipToIndex(lastIndex);
      return;
    }

    if (_currentIndex > 0) {
      await skipToIndex(_currentIndex - 1);
    } else if (_repeatMode == RepeatMode.all) {
      await skipToIndex(_queue.length - 1);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    _currentSong = _queue[index];
    _position = Duration.zero;
    _duration = Duration(seconds: _currentSong?.duration ?? 0);
    _resolvedArtworkUrl = null;
    notifyListeners();
    _refreshArtworkUrl();

    await _prepareAndPlayCurrentSong();
    _recordPlaybackHistory(_currentSong);
  }

  Future<void> seek(Duration position) async {
    if (_isRenderingRemotely) {
      await _seekRemotely(position);
      return;
    }
    
    _isSeeking = true;
    _lastSeekTime = DateTime.now();

    // Update local state immediately for snappy UI
    _position = position;
    _positionController.add(position);
    notifyListeners();
    
    try {
      await _audioPlayer.seek(position);
    } finally {
      // Small delay before allowing stream updates to resume
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSeeking = false;
        notifyListeners();
      });
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isRenderingRemotely) {
      await _onRemoteVolumeChange((_volume * 100).round());
    } else {
      await _audioPlayer.setVolume(_volume);
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    _queue.add(song);
    if (_currentIndex == -1 && _queue.length == 1) {
      _currentIndex = 0;
      _currentSong = song;
      _duration = Duration(seconds: song.duration ?? 0);
    }
    notifyListeners();
    _saveQueueState();
  }

  Future<void> addToQueueNext(Song song) async {
    if (_currentIndex == -1) {
      await addToQueue(song);
      return;
    }
    _queue.insert(_currentIndex + 1, song);
    notifyListeners();
    _saveQueueState();
  }

  Future<void> addAllToQueue(List<Song> songs) async {
    _queue.addAll(songs);
    if (_currentIndex == -1 && _queue.isNotEmpty) {
      _currentIndex = 0;
      _currentSong = _queue[0];
      _duration = Duration(seconds: _currentSong?.duration ?? 0);
    }
    notifyListeners();
    _saveQueueState();
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex--;
    } else if (index == _currentIndex) {
      if (_queue.isNotEmpty) {
        _currentIndex = _currentIndex.clamp(0, _queue.length - 1);
        _currentSong = _queue[_currentIndex];
      } else {
        _currentIndex = -1;
        _currentSong = null;
      }
    }
    notifyListeners();
    _saveQueueState();
  }

  Future<void> clearQueue() async {
    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();
    _clearPersistedQueue();
  }

  Future<void> playRadioStation(RadioStation station) async {
    try {
      _isPlayingRadio = true;
      _currentRadioStation = station;
      _currentSong = Song(
        id: station.id,
        title: station.name,
        artist: 'Radio',
        album: '',
        duration: 0,
      );
      _resolvedArtworkUrl = null;
      notifyListeners();

      await _audioPlayer.setUrl(station.streamUrl);
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } catch (e) {
      debugPrint('Error playing radio station: $e');
    }
  }

  void _recordPlaybackHistory(Song? song) {
    if (song == null) return;
    try {
      _storageService.recordPlay(song.id);
    } catch (e) {
      debugPrint('Error recording playback history: $e');
    }
  }

  void _onCastStateChanged() {}
  void _onUpnpStateChanged() {}
  void _onUpnpRendererLost() {
    _isRenderingRemotely = false;
    notifyListeners();
  }

  Future<void> _playRemotely(Song song) async {}
  Future<void> _pauseRemotely() async {}
  Future<void> _stopRemotely() async {}
  Future<void> _seekRemotely(Duration position) async {}
  Future<void> _onRemoteVolumeChange(int volumePercent) async {}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistDebounceTimer?.cancel();
    _positionController.close();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentIndexSub?.cancel();
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _jukeboxPollTimer?.cancel();
    super.dispose();
  }
}