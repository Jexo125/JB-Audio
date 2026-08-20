import 'package:flutter/material.dart';
import '../../services/player_ui_settings_service.dart';

class AlbumArtView extends StatelessWidget {
  final ImageProvider image;
  final String tag;

  const AlbumArtView({
    super.key,
    required this.image,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final svc = PlayerUiSettingsService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<String>(
      valueListenable: svc.artworkShapeNotifier,
      builder: (context, shape, _) {
        return ValueListenableBuilder<double>(
          valueListenable: svc.albumArtCornerRadiusNotifier,
          builder: (context, globalRadius, _) {
            return ValueListenableBuilder<String>(
              valueListenable: svc.artworkShadowNotifier,
              builder: (context, shadowLevel, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: svc.artworkShadowColorNotifier,
                  builder: (context, shadowColor, _) {
                    final radius = shape == 'circle'
                        ? 9999.0
                        : shape == 'square'
                            ? 0.0
                            : globalRadius;

                    return Hero(
                      tag: tag,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius),
                          boxShadow: _getShadow(context, shadowLevel, shadowColor, isDark),
                          image: DecorationImage(
                            image: image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<BoxShadow>? _getShadow(
    BuildContext context,
    String level,
    String colorName,
    bool isDark,
  ) {
    if (level == 'none') return null;
    
    final Color color = colorName == 'accent'
        ? Theme.of(context).colorScheme.primary
        : Colors.black;
        
    double opacity;
    double blur;
    Offset offset;
    
    // We don't have the size here easily, but let's estimate based on typical Now Playing size
    const estimatedSize = 300.0;

    switch (level) {
      case 'medium':
        opacity = isDark ? 0.35 : 0.25;
        blur = estimatedSize / 6;
        offset = const Offset(0, estimatedSize / 20);
        break;
      case 'strong':
        opacity = isDark ? 0.55 : 0.40;
        blur = estimatedSize / 4;
        offset = const Offset(0, estimatedSize / 12);
        break;
      default: // soft
        opacity = isDark ? 0.22 : 0.14;
        blur = estimatedSize / 10;
        offset = const Offset(0, estimatedSize / 30);
    }

    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      )
    ];
  }
}
