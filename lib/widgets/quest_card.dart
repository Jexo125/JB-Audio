import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import '../services/music_quest_service.dart';
import '../l10n/app_localizations.dart';

class QuestCard extends StatelessWidget {
  final MusicQuestInstance instance;
  final MusicQuestProgress? progress;

  const QuestCard({
    super.key,
    required this.instance,
    this.progress,
  });

  String _getQuestTitle(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'daily_listener':
        return l10n.questDailyListenerTitle;
      case 'daily_explorer':
        return l10n.questDailyExplorerTitle;
      case 'daily_finisher':
        return l10n.questDailyFinisherTitle;
      case 'daily_discovery':
        return l10n.questDailyDiscoveryTitle;
      case 'weekly_loyalty':
        return l10n.questWeeklyLoyaltyTitle;
      default:
        return id;
    }
  }

  String _getQuestDescription(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'daily_listener':
        return l10n.questDailyListenerDesc;
      case 'daily_explorer':
        return l10n.questDailyExplorerDesc;
      case 'daily_finisher':
        return l10n.questDailyFinisherDesc;
      case 'daily_discovery':
        return l10n.questDailyDiscoveryDesc;
      case 'weekly_loyalty':
        return l10n.questWeeklyLoyaltyDesc;
      default:
        return '';
    }
  }

  String _formatValue(double value, String id, BuildContext context) {
    if (id == 'daily_listener') {
      final minutes = (value / 60).floor();
      return '$minutes min';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    
    final isCompleted = instance.status == QuestStatus.completed || (progress?.isCompleted ?? false);
    final currentPercent = progress?.percent ?? (isCompleted ? 1.0 : 0.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _getQuestTitle(context, instance.definitionId),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (isCompleted)
                Icon(CupertinoIcons.checkmark_circle_fill, color: theme.colorScheme.primary, size: 20)
              else if (instance.status == QuestStatus.expired)
                const Icon(CupertinoIcons.xmark_circle, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getQuestDescription(context, instance.definitionId),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isCompleted ? l10n.goalReached : l10n.progress,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              if (progress != null)
                Text(
                  l10n.questProgressLabel(
                    _formatValue(progress!.currentValue, instance.definitionId, context),
                    _formatValue(progress!.targetValue, instance.definitionId, context),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentPercent,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? theme.colorScheme.primary : theme.colorScheme.secondary,
              ),
            ),
          ),
          if (progress != null && !isCompleted) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.questPercentLabel((currentPercent * 100).toInt()),
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.secondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
