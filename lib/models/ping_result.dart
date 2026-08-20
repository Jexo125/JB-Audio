class PingResult {
  final bool success;
  final String? error;
  final String? serverType;
  final String? serverVersion;

  PingResult({
    required this.success,
    this.error,
    this.serverType,
    this.serverVersion,
  });
}