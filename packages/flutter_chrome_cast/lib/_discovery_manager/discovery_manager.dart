import 'dart:io';
import './android_discovery_manager.dart';
import './discovery_manager_platform_interface.dart';
import './ios_discovery_manager.dart';

class GoogleCastDiscoveryManager {
  static final _instance = Platform.isAndroid
      ? GoogleCastDiscoveryManagerMethodChannelAndroid()
      : GoogleCastDiscoveryManagerMethodChannelIOS();

  static GoogleCastDiscoveryManagerPlatformInterface get instance => _instance;

  GoogleCastDiscoveryManager._();
}
