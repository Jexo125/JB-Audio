import 'dart:io';

import 'android_cast_session_manager.dart';
import 'ios_cast_session_manager.dart';

import 'cast_session_manager_platform.dart';

class GoogleCastSessionManager {
  static final GoogleCastSessionManagerPlatformInterface _instance =
      Platform.isAndroid
          ? GoogleCastSessionManagerAndroidMethodChannel()
          : GoogleCastSessionManagerIOSMethodChannel();

  static GoogleCastSessionManagerPlatformInterface get instance => _instance;

  GoogleCastSessionManager._();
}
