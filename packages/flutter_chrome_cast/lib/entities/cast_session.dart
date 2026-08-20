import 'cast_device.dart';
import '../enums/connection_state.dart';

abstract class GoogleCastSession {
  final GoogleCastDevice? device;
  final String? sessionID;
  final GoogleCastConnectionState connectionState;
  final bool currentDeviceMuted;
  final double currentDeviceVolume;
  final String deviceStatusText;

  GoogleCastSession({
    required this.device,
    required this.sessionID,
    required this.connectionState,
    required this.currentDeviceMuted,
    required this.currentDeviceVolume,
    required this.deviceStatusText,
  });
}
