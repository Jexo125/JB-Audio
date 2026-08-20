import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../../l10n/app_localizations.dart';

class NowPlayingMoreMenu extends StatelessWidget {
  const NowPlayingMoreMenu({super.key});

  void _setSleepTimer(BuildContext context, int minutes, PlayerProvider provider) {
    if (minutes == 0) {
      provider.setSleepTimer(Duration.zero, endCurrentSong: false);
    } else if (minutes == -1) {
      provider.setSleepTimer(Duration.zero, endCurrentSong: true);
    } else {
      provider.setSleepTimer(Duration(minutes: minutes), endCurrentSong: false);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<PlayerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 24),
                const SizedBox(width: 12),
                Text(
                  l10n.sleepTimer,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildOption(
              context, 
              l10n.off, 
              () => _setSleepTimer(context, 0, provider),
              isActive: !provider.hasSleepTimer && !provider.sleepTimerEndCurrentSong,
            ),
            _buildOption(
              context, 
              l10n.sleepTimerMinutes(5), 
              () => _setSleepTimer(context, 5, provider),
              isActive: provider.sleepTimerRemaining?.inMinutes == 5,
            ),
            _buildOption(
              context, 
              l10n.sleepTimerMinutes(15), 
              () => _setSleepTimer(context, 15, provider),
              isActive: provider.sleepTimerRemaining?.inMinutes == 15,
            ),
            _buildOption(
              context, 
              l10n.sleepTimerMinutes(30), 
              () => _setSleepTimer(context, 30, provider),
              isActive: provider.sleepTimerRemaining?.inMinutes == 30,
            ),
            _buildOption(
              context, 
              l10n.sleepTimerMinutes(60), 
              () => _setSleepTimer(context, 60, provider),
              isActive: provider.sleepTimerRemaining?.inMinutes == 60,
            ),
            _buildOption(
              context, 
              l10n.endOfSong, 
              () => _setSleepTimer(context, -1, provider),
              isActive: provider.sleepTimerEndCurrentSong,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, VoidCallback onTap, {bool isActive = false}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? theme.colorScheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? theme.colorScheme.primary : null,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
