import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../enums/connection_state.dart';
import '../entities/cast_session.dart';
import '../entities/cast_device.dart';
import '../models/android/cast_device.dart';
import '../models/android/cast_session.dart';
import 'package:rxdart/subjects.dart';

import 'cast_session_manager_platform.dart';

class GoogleCastSessionManagerAndroidMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  GoogleCastSessionManagerAndroidMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }
  final _channel =
      const MethodChannel('com.felnanuke.google_cast.session_manager');

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  GoogleCastConnectionState get connectionState =>
      _currentSessionStreamController.value?.connectionState ??
      GoogleCastConnectionState.disconnected;

  @override
  GoogleCastSession? get currentSession =>
      _currentSessionStreamController.value;

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  @override
  Future<bool> endSession() async {
    return await _channel.invokeMethod('endSession');
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    return await _channel.invokeMethod('endSessionAndStopCasting');
  }

  @override
  bool get hasConnectedSession =>
      _currentSessionStreamController.value?.connectionState ==
      GoogleCastConnectionState.connected;

  @override
  Future<void> setDefaultSessionOptions() {
    throw UnimplementedError('Only works in IOS');
  }

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastAndroidDevice;
    return (await _channel.invokeMethod(
          'startSessionWithDeviceId',
          device.deviceID,
        )) ==
        true;
  }

  @override
  Future<bool> startSessionWithOpenURLOptions() {
    throw UnimplementedError('Only works in iOS');
  }

  @override
  Future<bool> suspendSessionWithReason() async {
    return (await _channel.invokeMethod('suspendSession')) == true;
  }

  Future _onMethodCallHandler(MethodCall call) async {
    // print('receive ${call.method}');

    switch (call.method) {
      case "onSessionChanged":
        _onSessionChanged(call.arguments);
        return;
      default:
    }
  }

  void _onSessionChanged(dynamic arguments) {
    try {
      if (arguments == null) {
        _currentSessionStreamController.add(null);
        return;
      }
      final map = Map<String, dynamic>.from(arguments);
      final session = GoogleCastSessionAndroid.fromMap(map);
      _currentSessionStreamController.add(session);
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
    }
    // print('onSessionChangedSuccess');
  }

  @override
  void setDeviceVolume(double value) {
    _channel.invokeMethod('setStreamVolume', value);
  }
}
