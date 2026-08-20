class ServerConfig {
  final String serverUrl;
  final String username;
  final String? password;
  final bool useLegacyAuth;
  final bool allowSelfSignedCertificates;
  final String? customCertificatePath;
  final String? clientCertificatePath;
  final String? clientCertificatePassword;
  final String? name;
  final String serverFamily;
  final String? apiToken;
  final String? userId;
  final String? serverType;
  final String? serverVersion;
  final List<String> selectedMusicFolderIds;

  const ServerConfig({
    required this.serverUrl,
    required this.username,
    this.password,
    this.useLegacyAuth = false,
    this.allowSelfSignedCertificates = false,
    this.customCertificatePath,
    this.clientCertificatePath,
    this.clientCertificatePassword,
    this.name,
    this.serverFamily = 'subsonic',
    this.apiToken,
    this.userId,
    this.serverType,
    this.serverVersion,
    this.selectedMusicFolderIds = const [],
  });

  bool get isValid => serverUrl.isNotEmpty && username.isNotEmpty;

  String get normalizedUrl {
    String url = serverUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String?,
      useLegacyAuth: json['useLegacyAuth'] as bool? ?? false,
      allowSelfSignedCertificates:
          json['allowSelfSignedCertificates'] as bool? ?? false,
      customCertificatePath: json['customCertificatePath'] as String?,
      clientCertificatePath: json['clientCertificatePath'] as String?,
      clientCertificatePassword: json['clientCertificatePassword'] as String?,
      name: json['name'] as String?,
      serverFamily: json['serverFamily'] as String? ?? 'subsonic',
      apiToken: json['apiToken'] as String?,
      userId: json['userId'] as String?,
      serverType: json['serverType'] as String?,
      serverVersion: json['serverVersion'] as String?,
      selectedMusicFolderIds:
          (json['selectedMusicFolderIds'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'useLegacyAuth': useLegacyAuth,
      'allowSelfSignedCertificates': allowSelfSignedCertificates,
      'customCertificatePath': customCertificatePath,
      'clientCertificatePath': clientCertificatePath,
      'clientCertificatePassword': clientCertificatePassword,
      'name': name,
      'serverFamily': serverFamily,
      'apiToken': apiToken,
      'userId': userId,
      'serverType': serverType,
      'serverVersion': serverVersion,
      'selectedMusicFolderIds': selectedMusicFolderIds,
    };
  }

  ServerConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    bool? useLegacyAuth,
    bool? allowSelfSignedCertificates,
    String? customCertificatePath,
    String? clientCertificatePath,
    String? clientCertificatePassword,
    String? name,
    String? serverFamily,
    String? apiToken,
    String? userId,
    String? serverType,
    String? serverVersion,
    List<String>? selectedMusicFolderIds,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      useLegacyAuth: useLegacyAuth ?? this.useLegacyAuth,
      allowSelfSignedCertificates: allowSelfSignedCertificates ?? this.allowSelfSignedCertificates,
      customCertificatePath: customCertificatePath ?? this.customCertificatePath,
      clientCertificatePath: clientCertificatePath ?? this.clientCertificatePath,
      clientCertificatePassword: clientCertificatePassword ?? this.clientCertificatePassword,
      name: name ?? this.name,
      serverFamily: serverFamily ?? this.serverFamily,
      apiToken: apiToken ?? this.apiToken,
      userId: userId ?? this.userId,
      serverType: serverType ?? this.serverType,
      serverVersion: serverVersion ?? this.serverVersion,
      selectedMusicFolderIds: selectedMusicFolderIds ?? this.selectedMusicFolderIds,
    );
  }
}