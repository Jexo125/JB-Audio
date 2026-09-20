import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/context_extensions.dart';
import '../../services/storage_service.dart';

class DeveloperCard extends StatefulWidget {
  const DeveloperCard({super.key});

  @override
  State<DeveloperCard> createState() => _DeveloperCardState();
}

class _DeveloperCardState extends State<DeveloperCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _tapCount = 0;
  Timer? _resetTimer;
  bool _showSecret = false;
  bool _isBadgeUnlocked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _checkBadgeStatus();
  }

  Future<void> _checkBadgeStatus() async {
    final unlocked = await StorageService().getCuriousBadgeUnlocked();
    if (mounted) {
      setState(() {
        _isBadgeUnlocked = unlocked;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _resetTimer?.cancel();
    setState(() {
      _tapCount++;
    });

    if (_tapCount >= 3) {
      _triggerDiscovery();
      setState(() {
        _showSecret = true;
        _tapCount = 0;
      });
      // Revert after 5 seconds to let them read the message
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showSecret = false;
          });
        }
      });
    } else {
      _resetTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _tapCount = 0;
          });
        }
      });
    }
  }

  Future<void> _triggerDiscovery() async {
    if (!_isBadgeUnlocked) {
      await StorageService().saveCuriousBadgeUnlocked(true);
      if (mounted) {
        setState(() {
          _isBadgeUnlocked = true;
        });
      }
    }
    _triggerCelebration();
  }

  void _triggerCelebration() {
    final overlay = Overlay.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CelebrationOverlay(
        message: l10n.badgeCuriousTitle,
        description: l10n.badgeCuriousDesc,
        onFinished: () => entry.remove(),
      ),
    );
    
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final l10n = AppLocalizations.of(context)!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(2), // Liseré width
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: SweepGradient(
              colors: const [
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.indigo,
                Colors.purple,
                Colors.red,
              ],
              transform: GradientRotation(_controller.value * 2 * math.pi),
            ),
          ),
          child: GestureDetector(
            onTap: _handleTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5856D6), Color(0xFFAF52DE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5856D6).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.code_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _showSecret ? l10n.developerRealName : l10n.aboutMadeBy,
                          key: ValueKey('name_$_showSecret'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _showSecret ? l10n.developerRevealMessage : l10n.aboutMadeWith,
                          key: ValueKey('slogan_$_showSecret'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontStyle: _showSecret ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isBadgeUnlocked)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Tooltip(
                        message: '${l10n.badgeCuriousTitle}: ${l10n.badgeCuriousDesc}',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CelebrationOverlay extends StatefulWidget {
  final String message;
  final String description;
  final VoidCallback onFinished;

  const _CelebrationOverlay({
    required this.message,
    required this.description,
    required this.onFinished,
  });

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: CurveTween(curve: Curves.easeOutBack), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(tween: CurveTween(curve: Curves.easeInBack), weight: 20),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 70),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    // Initialize random particles
    final random = math.Random();
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(
        color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        angle: random.nextDouble() * 2 * math.pi,
        speed: 2.0 + random.nextDouble() * 5.0,
        size: 4.0 + random.nextDouble() * 8.0,
      ));
    }

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      child: Stack(
        children: [
          // Background particles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
          // Centered message
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.amber, size: 80),
                      const SizedBox(height: 16),
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final Color color;
  final double angle;
  final double speed;
  final double size;

  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint();

    for (final p in particles) {
      final distance = progress * p.speed * 200;
      final x = center.dx + math.cos(p.angle) * distance;
      final y = center.dy + math.sin(p.angle) * distance;
      
      paint.color = p.color.withValues(alpha: 1.0 - progress);
      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
