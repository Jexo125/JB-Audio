import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/screen_helper.dart';

enum _LoginErrorType {
  ssl,
  credentials,
  notFound,
  timeout,
  connection,
  format,
  generic,
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _useLegacyAuth = false;
  bool _allowSelfSignedCertificates = false;
  bool _obscurePassword = true;
  String _serverFamily = 'subsonic'; // 'subsonic' | 'jellyfin' | 'youtube'
  final _profileNameController = TextEditingController();
  
  String? _loginError;

  @override
  void initState() {
    super.initState();
    
    _serverController.addListener(_clearError);
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _profileNameController.addListener(_clearError);
  }

  void _clearError() {
    if (_loginError != null && mounted) {
      setState(() => _loginError = null);
    }
  }

  _LoginErrorType _categoriseError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ssl') ||
        lower.contains('certificate') ||
        lower.contains('handshake') ||
        lower.contains('tls')) {
      return _LoginErrorType.ssl;
    }
    if (lower.contains('invalid username') ||
        lower.contains('wrong password') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return _LoginErrorType.credentials;
    }
    if (lower.contains('not found') ||
        lower.contains('404') ||
        lower.contains('url path')) {
      return _LoginErrorType.notFound;
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return _LoginErrorType.timeout;
    }
    if (lower.contains('cannot connect') ||
        lower.contains('connection refused') ||
        lower.contains('network') ||
        lower.contains('socket')) {
      return _LoginErrorType.connection;
    }
    if (lower.contains('url format') || lower.contains('http')) {
      return _LoginErrorType.format;
    }
    return _LoginErrorType.generic;
  }

  Widget _buildErrorCard(ThemeData theme) {
    final error = _loginError;
    if (error == null) return const SizedBox.shrink();

    final type = _categoriseError(error);

    IconData icon;
    Color color;
    String? hint;

    switch (type) {
      case _LoginErrorType.ssl:
        icon = CupertinoIcons.lock_slash;
        color = const Color(0xFFFF9500); 
        if (!_allowSelfSignedCertificates) {
          hint = 'Try enabling "Allow Self-Signed Certificates" below.';
        }
      case _LoginErrorType.credentials:
        icon = CupertinoIcons.person_badge_minus;
        color = AppTheme.appleMusicRed;
        hint = 'Check your username and password and try again.';
      case _LoginErrorType.notFound:
        icon = CupertinoIcons.question_circle;
        color = const Color(0xFFFF9500);
        hint = 'Verify the server URL path (e.g. /navidrome, /airsonic).';
      case _LoginErrorType.timeout:
        icon = CupertinoIcons.timer;
        color = const Color(0xFFFF9500);
        hint = 'The server took too long to respond. Check your network.';
      case _LoginErrorType.connection:
        icon = CupertinoIcons.wifi_slash;
        color = const Color(0xFFFF9500);
        hint = null;
      case _LoginErrorType.format:
        icon = CupertinoIcons.link;
        color = const Color(0xFFFF9500);
        hint = 'URL must start with http:// or https://';
      case _LoginErrorType.generic:
        icon = CupertinoIcons.exclamationmark_triangle;
        color = AppTheme.appleMusicRed;
        hint = null;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded, size: 16, color: color.withValues(alpha: 0.7)),
                  tooltip: 'Copy error',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: error));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.errorCopied),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        width: 260,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            
            if (type == _LoginErrorType.ssl &&
                !_allowSelfSignedCertificates) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _allowSelfSignedCertificates = true;
                      _loginError = null;
                    });
                  },
                  child: Text(
                    Platform.isIOS || Platform.isAndroid
                        ? 'Tap to enable self-signed certificates'
                        : 'Click to enable self-signed certificates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverController.removeListener(_clearError);
    _usernameController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _profileNameController.removeListener(_clearError);
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _profileNameController.dispose();
    _serverFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // YouTube Music requires no credentials — skip form validation
    if (_serverFamily != 'youtube') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _loginError = null);

    final serverUrl = _serverFamily == 'youtube'
        ? 'https://music.youtube.com'
        : _serverController.text.trim();

    if (_serverFamily != 'youtube' &&
        !serverUrl.startsWith('http://') &&
        !serverUrl.startsWith('https://')) {
      setState(
        () => _loginError = 'Server URL must start with http:// or https://',
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileName = _profileNameController.text.trim();
    final success = await authProvider.login(
      serverUrl: serverUrl,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      useLegacyAuth: _useLegacyAuth,
      allowSelfSignedCertificates: _allowSelfSignedCertificates,
      customCertificatePath: null,
      clientCertificatePath: null,
      clientCertificatePassword: null,
      profileName: profileName.isEmpty ? null : profileName,
      serverFamily: _serverFamily,
    );

    if (!success && mounted) {
      setState(
        () => _loginError = authProvider.error ?? 'Failed to connect to server',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.state == AuthState.authenticating;
    final theme = Theme.of(context);
    final isBusy = isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ScreenHelper.loginPadding(context)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Center(
                    child: Container(
                      width: ScreenHelper.loginLogoSize(context),
                      height: ScreenHelper.loginLogoSize(context),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.appleMusicRed.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Transform.translate(
                          offset: const Offset(0, 8),
                          child: Image.asset(
                            'assets/logobig.png',
                            width: ScreenHelper.loginLogoSize(context),
                            height: ScreenHelper.loginLogoSize(context),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                      Text(
                        'JB Audio',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: ScreenHelper.isSmallScreen(context) ? 32 : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connection au serveur de JB Audio',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightSecondaryText,
                        ),
                      ),
                  const SizedBox(height: 24),

                  _SavedProfilesSwitcher(
                    onProfileSelected: (profile) async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.switchProfile(profile);
                      if (mounted && authProvider.error != null) {
                        setState(
                          () => _loginError = authProvider.error,
                        );
                      }
                    },
                    onProfileDeleted: (profile) async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.deleteProfile(profile);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),
                  _ServerFamilyToggle(
                    serverFamily: _serverFamily,
                    onChanged: (v) => setState(() {
                      _serverFamily = v;
                      _useLegacyAuth = false;
                    }),
                  ),
                  const SizedBox(height: 16),

                  if (_serverFamily == 'youtube') ...[                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0000).withAlpha(20),
                        border: Border.all(
                          color: const Color(0xFFFF0000).withAlpha(80),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.info_circle,
                            color: Color(0xFFFF0000),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'YouTube Music streams music directly from YouTube. No account required — tap Connect to start.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[                    
                  TextFormField(
                    controller: _serverController,
                    focusNode: _serverFocusNode,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _usernameFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-server.com',
                      prefixIcon: const Icon(CupertinoIcons.globe),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter server URL';
                      }
                      final url = value.trim();
                      if (!url.startsWith('http://') &&
                          !url.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(CupertinoIcons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) { if (!isBusy) _login(); },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(CupertinoIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? CupertinoIcons.eye
                              : CupertinoIcons.eye_slash,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                  ],
                  const SizedBox(height: 16),

                  const SizedBox(height: 24),

                  _buildErrorCard(theme),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.appleMusicRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Se Connecter',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedProfilesSwitcher extends StatefulWidget {
  final Future<void> Function(ServerConfig) onProfileSelected;
  final Future<void> Function(ServerConfig) onProfileDeleted;

  const _SavedProfilesSwitcher({
    required this.onProfileSelected,
    required this.onProfileDeleted,
  });

  @override
  State<_SavedProfilesSwitcher> createState() => _SavedProfilesSwitcherState();
}

class _SavedProfilesSwitcherState extends State<_SavedProfilesSwitcher> {
  Future<List<ServerConfig>>? _profilesFuture;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _reload();
    }
  }

  void _reload() {
    _profilesFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).getSavedProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServerConfig>>(
      future: _profilesFuture,
      builder: (context, snap) {
        final profiles = snap.data ?? [];
        if (profiles.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved Profiles',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles.map((profile) {
                final label = profile.name?.isNotEmpty == true
                    ? profile.name!
                    : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
                return InputChip(
                  avatar: const Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 18,
                  ),
                  label: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  tooltip: '${profile.username} – ${profile.serverUrl}',
                  onPressed: () async {
                    await widget.onProfileSelected(profile);
                    if (mounted) setState(_reload);
                  },
                  onDeleted: () async {
                    await widget.onProfileDeleted(profile);
                    if (mounted) setState(_reload);
                  },
                  deleteIcon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a profile to connect • tap × to delete',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServerFamilyToggle extends StatelessWidget {
  final String serverFamily;
  final ValueChanged<String> onChanged;

  const _ServerFamilyToggle({
    required this.serverFamily,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
