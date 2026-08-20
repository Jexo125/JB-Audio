/// Represents the connection state of a Google Cast session.
enum GoogleCastConnectionState {
  ///Disconnected from the device or application.
  disconnected,

  ///Connecting to the device or application.
  connecting,

  ///Connected to the device or application.
  connected,

  ///Disconnecting from the device.
  disconnecting,
}
