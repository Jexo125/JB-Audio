import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../entities/cast_session.dart';
import '../entities/cast_device.dart';
import '../enums/connection_state.dart';
import '../models/ios/ios_cast_device.dart';
import '../models/ios/ios_cast_sessions.dart';
import 'cast_session_manager_platform.dart';
import 'package:rxdart/subjects.dart';

class GoogleCastSessionManagerIOSMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  GoogleCastSessionManagerIOSMethodChannel() {
    _channel.setMethodCallHandler(
      (call) => _methodCallHandler(call),
    );
  }

  final _channel = const MethodChannel('google_cast.session_manager');

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastIosDevice;
    return await _channel.invokeMethod(
      'startSessionWithDevice',
      device.index,
    );
  }

  @override
  GoogleCastConnectionState get connectionState =>
      currentSession?.connectionState ??
      GoogleCastConnectionState.disconnected;

  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  GoogleCastSession? get currentSession =>
      _currentSessionStreamController.value;

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
      connectionState == GoogleCastConnectionState.connected;

  @override
  Future<void> setDefaultSessionOptions() {
    // TODO: implement setDefaultSessionOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> startSessionWithOpenURLOptions() {
    // TODO: implement startSessionWithOpenURLOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> suspendSessionWithReason() {
    // TODO: implement suspendSessionWithReason
    throw UnimplementedError();
  }

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onCurrentSessionChanged':
        return _onCurrentSessionChanged(call.arguments);
    }
  }

  void _onCurrentSessionChanged(Object? arguments) async {
    try {
      if (arguments == null) {
        _currentSessionStreamController.add(null);
        return;
      }
      final session = IOSGoogleCastSessions.fromMap(
          Map<String, dynamic>.from(arguments as Map));
      _currentSessionStreamController.add(session);
    } catch (e, s) {
      if (kDebugMode) {
        print('Error in _onCurrentSessionChanged: $e');
        print(s);
      }
    }
  }

  @override
  void setDeviceVolume(double value) {
    _channel.invokeMethod('setDeviceVolume', value);
  }
}
