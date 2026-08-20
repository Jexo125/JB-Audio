import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/update_service.dart';
import '../widgets/settings/settings_section_card.dart';
import '../utils/context_extensions.dart';

class SettingsAboutTab extends StatefulWidget {
  const SettingsAboutTab({super.key});

  @override
  State<SettingsAboutTab> createState() => _SettingsAboutTabState();
}

class _SettingsAboutTabState extends State<SettingsAboutTab> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _disableAnalytics();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await UpdateService.getCurrentVersion();
    if (mounted) {
      setState(() {
        _appVersion = version;
      });
    }
  }

  Future<void> _disableAnalytics() async {
    // Désactivation forcée de l'analytics au chargement
    await AnalyticsService().setEnabled(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Section Informations (Version / Plateforme)
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAboutInformation,
          children: [
            _buildInfoTile(
              context,
              icon: CupertinoIcons.info,
              iconColor: Theme.of(context).colorScheme.primary,
              title: AppLocalizations.of(context)!.aboutVersion,
              subtitle: _appVersion,
            ),
            _buildDivider(context),
            _buildInfoTile(
              context,
              icon: CupertinoIcons.device_phone_portrait,
              iconColor: const Color(0xFF007AFF),
              title: AppLocalizations.of(context)!.aboutPlatform,
              subtitle: Theme.of(context).platform.name.toUpperCase(),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Section Développeur (Restaurée et personnalisée)
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionAboutDeveloper,
          children: [_buildDeveloperInfo(context)],
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        height: 0.5,
        color: context.isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
      ),
    );
  }

  Widget _buildInfoTile(
      BuildContext context, {
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
      trailing: Text(
        subtitle,
        style: TextStyle(
          fontSize: 16,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildDeveloperInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            'Développé par JB Audio',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}