import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranscodeBitrate {
  static const int original = 0;
  static const int kbps64 = 64;
  static const int kbps128 = 128;
  static const int kbps192 = 192;
  static const int kbps256 = 256;
  static const int kbps320 = 320;

  static const List<int> options = [
    original,
    kbps64,
    kbps128,
    kbps192,
    kbps256,
    kbps320,
  ];

  static String getLabel(int bitrate) {
    if (bitrate == original) return 'Original (No Transcoding)';
    return '$bitrate kbps';
  }
}

class TranscodeFormat {
  static const String original = 'raw';
  static const String mp3 = 'mp3';
  static const String opus = 'opus';
  static const String aac = 'aac';

  static const List<String> options = [original, mp3, opus, aac];

  static String getLabel(String format) {
    switch (format) {
      case original:
        return 'Original';
      case mp3:
        return 'MP3';
      case opus:
        return 'Opus';
      case aac:
        return 'AAC';
      default:
        return format.toUpperCase();
    }
  }
}

enum ConnectionType { wifi, mobile }

class TranscodingService extends ChangeNotifier {
  static const String _wifiBitrateKey = 'transcoding_wifi_bitrate';
  static const String _mobileBitrateKey = 'transcoding_mobile_bitrate';
  static const String _formatKey = 'transcoding_format';
  static const String _enabledKey = 'transcoding_enabled';
  static const String _connectionTypeKey = 'transcoding_connection_type';
  static const String _smartEnabledKey = 'transcoding_smart_enabled';

  int _wifiBitrate = TranscodeBitrate.original;
  int _mobileBitrate = TranscodeBitrate.kbps192;
  String _format = TranscodeFormat.mp3;
  bool _enabled = false;
  bool _smartEnabled = false;
  ConnectionType _currentConnectionType = ConnectionType.wifi;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int get wifiBitrate => _wifiBitrate;
  int get mobileBitrate => _mobileBitrate;
  int get currentBitRate => _smartEnabled
      ? (_currentConnectionType == ConnectionType.wifi
          ? _wifiBitrate
          : _mobileBitrate)
      : _wifiBitrate;
  String get format => _format;
  bool get enabled => _enabled;
  bool get smartEnabled => _smartEnabled;
  ConnectionType get currentConnectionType => _currentConnectionType;

  TranscodingService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _wifiBitrate = prefs.getInt(_wifiBitrateKey) ?? TranscodeBitrate.original;
    _mobileBitrate =
        prefs.getInt(_mobileBitrateKey) ?? TranscodeBitrate.kbps192;
    _format = prefs.getString(_formatKey) ?? TranscodeFormat.mp3;
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _smartEnabled = prefs.getBool(_smartEnabledKey) ?? false;
    final connectionIndex = prefs.getInt(_connectionTypeKey) ?? 0;
    _currentConnectionType = ConnectionType.values[connectionIndex];

    if (_smartEnabled) {
      await _initConnectivityWatcher();
    }

    notifyListeners();
  }

  Future<void> _initConnectivityWatcher() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionType(result);

    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_updateConnectionType);
  }

  void _updateConnectionType(List<ConnectivityResult> results) {
    final newType = results.contains(ConnectivityResult.wifi)
        ? ConnectionType.wifi
        : ConnectionType.mobile;

    if (newType != _currentConnectionType) {
      _currentConnectionType = newType;
      debugPrint(
        '[Transcoding] Network changed → ${newType.name} '
        '(bitrate: ${getCurrentBitrate() ?? "original"})',
      );
      notifyListeners();
    }
  }

  void _stopConnectivityWatcher() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setSmartEnabled(bool value) async {
    _smartEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smartEnabledKey, value);
    if (value) {
      await _initConnectivityWatcher();
    } else {
      _stopConnectivityWatcher();
    }
    notifyListeners();
  }

  Future<void> setWifiBitrate(int bitrate) async {
    _wifiBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wifiBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setMobileBitrate(int bitrate) async {
    _mobileBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mobileBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setFormat(String format) async {
    _format = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format);
    notifyListeners();
  }

  Future<void> setConnectionType(ConnectionType type) async {
    _currentConnectionType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_connectionTypeKey, type.index);
    notifyListeners();
  }

  int? getCurrentBitrate() {
    if (!_enabled) return null;
    final bitrate = _currentConnectionType == ConnectionType.wifi
        ? _wifiBitrate
        : _mobileBitrate;
    return bitrate == TranscodeBitrate.original ? null : bitrate;
  }

  String? getCurrentFormat() {
    if (!_enabled) return null;
    return _format == TranscodeFormat.original ? null : _format;
  }

  Future<String?> getTranscodeDecision(
    String songId, {
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final bitrate = getCurrentBitrate();
    if (bitrate == null) return null;

    final salt = _generateRandomSalt();
    final token = md5.convert(utf8.encode(password + salt)).toString();

    final url = Uri.parse('$serverUrl/rest/getTranscodeDecision.view').replace(
      queryParameters: {
        'u': username,
        't': token,
        's': salt,
        'v': '1.16.1',
        'c': 'JB Audio',
        'f': 'json',
        'id': songId,
      },
    );

    final clientInfo = {
      "name": "JB Audio",
      "platform": "Android",
      "maxAudioBitrate": 0,
      "maxTranscodingAudioBitrate": bitrate * 1000,
      "directPlayProfiles": [
        {
          "containers": ["flac", "mp3", "ogg", "opus", "m4a"],
          "audioCodecs": ["flac", "mp3", "vorbis", "opus", "aac"],
          "protocols": ["http"],
          "maxAudioChannels": 2
        }
      ],
      "transcodingProfiles": [
        {
          "container": _format == TranscodeFormat.original ? "mp3" : _format,
          "audioCodec": _format == TranscodeFormat.original ? "mp3" : _format,
          "protocol": "http",
          "maxAudioChannels": 2
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(clientInfo),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision = data['subsonic-response']?['transcodeDecision'];
        if (decision != null && decision['canTranscode'] == true) {
          return decision['transcodeParams'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error getting transcode decision: $e');
    }
    return null;
  }

  Uri getStreamUri(
    String id, {
    required String serverUrl,
    required String username,
    required String password,
    String? transcodeParams,
  }) {
    final bitrate = getCurrentBitrate();
    final format = getCurrentFormat();

    final salt = _generateRandomSalt();
    final token = md5.convert(utf8.encode(password + salt)).toString();

    final params = {
      'u': username,
      't': token,
      's': salt,
      'v': '1.16.1',
      'c': 'JB Audio',
      'id': id,
      'estimateContentLength': 'true',
    };

    if (transcodeParams != null) {
      params['transcodeParams'] = transcodeParams;
    } else {
      if (bitrate != null) params['maxBitRate'] = bitrate.toString();
      if (format != null) params['format'] = format;
    }

    return Uri.parse('$serverUrl/rest/stream.view')
        .replace(queryParameters: params);
  }

  String _generateRandomSalt() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  @override
  void dispose() {
    _stopConnectivityWatcher();
    super.dispose();
  }
}
