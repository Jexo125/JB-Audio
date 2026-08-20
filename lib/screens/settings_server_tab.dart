import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/settings/settings_section_card.dart';
import '../widgets/settings/settings_icon_badge.dart';
import '../utils/context_extensions.dart';

class SettingsServerTab extends StatefulWidget {
  const SettingsServerTab({super.key});

  @override
  State<SettingsServerTab> createState() => _SettingsServerTabState();
}

class _SettingsServerTabState extends State<SettingsServerTab> {

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: l10n.sectionServerConnection,
          children: [
            _buildInfoTile(
              icon: CupertinoIcons.link,
              iconColor: const Color(0xFF007AFF),
              title: l10n.serverUrl,
              subtitle: authProvider.config?.serverUrl ?? l10n.notConnected,
            ),
            const SettingsDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.person,
              iconColor: const Color(0xFF34C759),
              title: l10n.username,
              subtitle: authProvider.config?.username ?? l10n.unknown,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: l10n.sectionAccount,
          children: [_buildLogoutButton()],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
        icon: CupertinoIcons.square_arrow_right,
      ),
      title: Text(
        AppLocalizations.of(context)!.logout,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () {
        final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.logout),
            content: Text(AppLocalizations.of(context)!.logoutConfirmation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  playerProvider.stop();
                  authProvider.logout();
                },
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(color: Color(0xFFFF3B30)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
