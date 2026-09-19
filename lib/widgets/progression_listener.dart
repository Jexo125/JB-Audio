import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/xp_service.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'level_up_celebration.dart';

/// A global listener that monitors XP progression and displays
/// real-time feedback (SnackBars) for level ups and title unlocks.
class ProgressionListener extends StatefulWidget {
  final Widget child;

  const ProgressionListener({super.key, required this.child});

  @override
  State<ProgressionListener> createState() => _ProgressionListenerState();
}

class _ProgressionListenerState extends State<ProgressionListener> {
  XpService? _xpService;
  int? _lastLevel;
  Set<String>? _unlockedTitleIds;

  @override
  void initState() {
    super.initState();
    // Delay initialization to capture initial state correctly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _xpService = Provider.of<XpService>(context, listen: false);
      _lastLevel = _xpService!.snapshot.currentLevel;
      _unlockedTitleIds = _xpService!.getTitleSnapshots()
          .where((s) => s.isUnlocked)
          .map((s) => s.definition.id)
          .toSet();
      
      _xpService!.addListener(_onProgressionChanged);
    });
  }

  @override
  void dispose() {
    _xpService?.removeListener(_onProgressionChanged);
    super.dispose();
  }

  void _onProgressionChanged() {
    final xpService = _xpService;
    if (!mounted || xpService == null || !xpService.isEnabled) return;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    final snapshot = xpService.snapshot;
    final titleSnapshots = xpService.getTitleSnapshots();

    // 1. Check for Level Up
    if (_lastLevel != null && snapshot.currentLevel > _lastLevel!) {
      LevelUpCelebration.show(context, snapshot.currentLevel, snapshot.progressPercent);
    }
    _lastLevel = snapshot.currentLevel;

    // 2. Check for Title Unlocks
    final currentUnlocked = titleSnapshots
        .where((s) => s.isUnlocked)
        .toList();
    
    for (final title in currentUnlocked) {
      if (_unlockedTitleIds != null && !_unlockedTitleIds!.contains(title.definition.id)) {
        _showTitleUnlockFeedback(context, title, l10n);
      }
    }
    _unlockedTitleIds = currentUnlocked.map((s) => s.definition.id).toSet();
  }

  void _showTitleUnlockFeedback(BuildContext context, TitleSnapshot title, AppLocalizations l10n) {
    // Basic lookup for localized name
    final name = _getLocalizedName(l10n, title.definition.nameKey);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.rosette, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.titleUnlockedNotification(name),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getLocalizedName(AppLocalizations l10n, String key) {
    final Map<String, String> lookup = {
      'titleMelomane': l10n.titleMelomane,
      'titleExplorer': l10n.titleExplorer,
      'titleCollector': l10n.titleCollector,
      'titleFinisher': l10n.titleFinisher,
      'titlePioneer': l10n.titlePioneer,
      'titleRegular': l10n.titleRegular,
    };
    return lookup[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
