import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';

class GamificationIntroOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const GamificationIntroOverlay({super.key, required this.onDismiss});

  static Future<void> showIfNeeded(BuildContext context) async {
    final storage = StorageService();
    final seenVersion = await storage.getGamificationIntroVersionSeen();
    const currentVersion = 1;

    if (seenVersion < currentVersion) {
      if (!context.mounted) return;
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Gamification Intro',
        barrierColor: Colors.black.withValues(alpha: 0.8),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim1, anim2) {
          return GamificationIntroOverlay(
            onDismiss: () async {
              await storage.saveGamificationIntroVersionSeen(currentVersion);
              if (context.mounted) Navigator.pop(context);
            },
          );
        },
      );
    }
  }

  @override
  State<GamificationIntroOverlay> createState() => _GamificationIntroOverlayState();
}

class _GamificationIntroOverlayState extends State<GamificationIntroOverlay> {
  int _step = 0;
  bool _isTyping = false;
  String _currentText = '';
  Timer? _typingTimer;

  late final List<String> _introSteps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    _introSteps = [
      l10n.introStep1, // "Bienvenue dans l'aventure musicale JB Audio !"
      l10n.introStep2, // "Chaque minute d'écoute vous rapporte de l'XP."
      l10n.introStep3, // "Débloquez des titres légendaires et montez en niveau."
      l10n.introStep4, // "Relevez des quêtes musicales pour des bonus massifs."
      l10n.introStep5, // "Retrouvez votre progression dans la Bibliothèque."
    ];
    if (_currentText.isEmpty && !_isTyping) {
      _startTyping();
    }
  }

  void _startTyping() {
    if (_step >= _introSteps.length) return;
    
    setState(() {
      _isTyping = true;
      _currentText = '';
    });

    final fullText = _introSteps[_step];
    int charIndex = 0;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (charIndex < fullText.length) {
        setState(() {
          _currentText += fullText[charIndex];
        });
        charIndex++;
      } else {
        timer.cancel();
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  void _nextStep() {
    if (_isTyping) {
      // Skip typing
      _typingTimer?.cancel();
      setState(() {
        _currentText = _introSteps[_step];
        _isTyping = false;
      });
    } else {
      if (_step < _introSteps.length - 1) {
        setState(() {
          _step++;
        });
        _startTyping();
      } else {
        widget.onDismiss();
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  border: Border.all(color: theme.colorScheme.primary, width: 2),
                ),
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 50,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: Text(
                          _currentText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_step + 1} / ${_introSteps.length}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_step == _introSteps.length - 1 && !_isTyping ? l10n.done : l10n.next),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
