import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/xp_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';

class ProgressionScreen extends StatelessWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<XpService>(
        builder: (context, xpService, _) {
          final snapshot = xpService.snapshot;
          final titleSnapshots = xpService.getTitleSnapshots();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    l10n.progressionTitle,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level and XP Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
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
                                  l10n.levelLabel(snapshot.currentLevel),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 28),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.xpTotal(snapshot.totalXp),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: snapshot.progressPercent,
                                minHeight: 12,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  snapshot.isMaxLevel 
                                      ? l10n.maxLevelReached 
                                      : l10n.xpNextLevel(snapshot.xpRequiredForNext - snapshot.xpInCurrentLevel),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!snapshot.isMaxLevel)
                                  Text(
                                    l10n.questPercentLabel((snapshot.progressPercent * 100).toInt()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      SectionHeader(title: l10n.titlesSection),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final title = titleSnapshots[index];
                      return _TitleListItem(title: title);
                    },
                    childCount: titleSnapshots.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _TitleListItem extends StatelessWidget {
  final TitleSnapshot title;

  const _TitleListItem({required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String name = _getLocalizedName(context, title.definition.nameKey);
    final String desc = _getLocalizedName(context, title.definition.descKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: title.isUnlocked 
              ? theme.colorScheme.primary.withValues(alpha: 0.3) 
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: title.isUnlocked 
                  ? theme.colorScheme.primary.withValues(alpha: 0.1) 
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              title.isUnlocked ? CupertinoIcons.rosette : CupertinoIcons.lock,
              color: title.isUnlocked ? theme.colorScheme.primary : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: title.isUnlocked 
                        ? (isDark ? Colors.white : Colors.black)
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (title.isUnlocked && title.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.unlockedOn(DateFormat.yMMMd().format(title.unlockedAt!)),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!title.isUnlocked)
            Text(
              l10n.lockedTitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  String _getLocalizedName(BuildContext context, String key) {
    // In a real scenario, we might use reflection or a map. 
    // Since we have a limited set, a simple switch or just looking up in l10n is fine.
    final l10n = AppLocalizations.of(context)!;
    final Map<String, dynamic> lookup = {
      'titleMelomane': l10n.titleMelomane,
      'titleMelomaneDesc': l10n.titleMelomaneDesc,
      'titleExplorer': l10n.titleExplorer,
      'titleExplorerDesc': l10n.titleExplorerDesc,
      'titleCollector': l10n.titleCollector,
      'titleCollectorDesc': l10n.titleCollectorDesc,
      'titleFinisher': l10n.titleFinisher,
      'titleFinisherDesc': l10n.titleFinisherDesc,
      'titlePioneer': l10n.titlePioneer,
      'titlePioneerDesc': l10n.titlePioneerDesc,
      'titleRegular': l10n.titleRegular,
      'titleRegularDesc': l10n.titleRegularDesc,
    };
    return lookup[key] ?? key;
  }
}
