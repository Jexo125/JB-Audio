import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class ReleaseAsset {
  final String name;
  final String browserDownloadUrl;

  const ReleaseAsset({required this.name, required this.browserDownloadUrl});

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        name: json['name'] as String,
        browserDownloadUrl: json['browser_download_url'] as String,
      );
}

class ReleaseInfo {
  final String version;
  final String tagName;
  final String htmlUrl;
  final String body;
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.assets,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    return ReleaseInfo(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      tagName: tag,
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UpdateService {
  static const String _apiUrl =
      'https://api.github.com/repos/Jexo125/JB-Audio/releases/latest';

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );

  static Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('UpdateService: failed to get current version: $e');
      return '0.0.0';
    }
  }

  static Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      debugPrint('UpdateService: Checking for update. Current version: $currentVersion');
      
      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      final data = response.data;
      if (data == null) return null;

      final release = ReleaseInfo.fromJson(data);
      debugPrint('UpdateService: Latest version on GitHub: ${release.version}');
      
      if (_isNewer(release.version, currentVersion)) {
        return release;
      }
    } catch (e) {
      debugPrint('UpdateService: check failed – $e');
    }
    return null;
  }

  static bool _isNewer(String remote, String current) {
    try {
      List<int> parse(String v) =>
          v.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final r = parse(remote);
      final c = parse(current);
      final len = r.length > c.length ? r.length : c.length;
      
      List<int> rPadded = List.from(r);
      List<int> cPadded = List.from(c);
      
      while (rPadded.length < len) {
        rPadded.add(0);
      }
      while (cPadded.length < len) {
        cPadded.add(0);
      }

      for (int i = 0; i < len; i++) {
        if (rPadded[i] > cPadded[i]) return true;
        if (rPadded[i] < cPadded[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static String? getApkUrl(ReleaseInfo release) {
    for (final asset in release.assets) {
      if (asset.name.toLowerCase().endsWith('.apk')) {
        return asset.browserDownloadUrl;
      }
    }
    return null;
  }

  static Future<void> downloadAndInstallApk(String url, Function(double) onProgress) async {
    try {
      final directory = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${directory.path}/jbaudio_update.apk';
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      await _dio.download(
        url, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
      
      final result = await OpenFile.open(
        filePath, 
        type: 'application/vnd.android.package-archive',
      );
      
      if (result.type != ResultType.done) {
        throw Exception('Failed to open APK: ${result.message}');
      }
    } catch (e) {
      debugPrint('UpdateService: download/install failed - $e');
      rethrow;
    }
  }

  static String stripMarkdown(String md) {
    return md
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`{1,3}(.*?)`{1,3}'), (m) => m.group(1) ?? '')
        .replaceAllMapped(
            RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '')
        .replaceAll(RegExp(r'^---+$', multiLine: true), '─────────────')
        .trim();
  }
}
