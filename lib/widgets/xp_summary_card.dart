import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/xp_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../utils/navigation_helper.dart';
import '../screens/progression_screen.dart';

class XpSummaryCard extends StatelessWidget {
  final double horizontalPadding;

  const XpSummaryCard({
    super.key,
    this.horizontalPadding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<XpService>(
      builder: (context, xpService, _) {
        if (!xpService.isEnabled) return const SizedBox.shrink();

        return StreamBuilder<ProgressionSnapshot>(
          stream: xpService.onSnapshotUpdated,
          initialData: xpService.snapshot,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final data = snapshot.data!;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
              child: GestureDetector(
                onTap: () => NavigationHelper.push(context, const ProgressionScreen()),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.levelLabel(data.currentLevel),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${data.totalXp} XP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _AnimatedProgressBar(
                        value: data.progressPercent,
                        color: theme.colorScheme.primary,
                        backgroundColor: isDark ? Colors.white10 : Colors.grey[200]!,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            data.isMaxLevel
                                ? l10n.maxLevelReached
                                : '${data.xpInCurrentLevel} / ${data.xpRequiredForNext} XP',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          if (!data.isMaxLevel)
                            Text(
                              l10n.xpNextLevel(data.xpRequiredForNext - data.xpInCurrentLevel),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color backgroundColor;

  const _AnimatedProgressBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 8,
        width: double.infinity,
        color: backgroundColor,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: val.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
