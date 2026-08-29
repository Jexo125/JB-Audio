import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';
import 'album_artwork.dart';
import '../utils/navigation_helper.dart';
import '../screens/album_screen.dart';

class RecommendedCarousel extends StatelessWidget {
  final double hPad;

  const RecommendedCarousel({
    super.key,
    required this.hPad,
  });

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final recommendations = libraryProvider.recommendedAlbums;

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Responsive card size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardSize = screenWidth > 600 ? 200.0 : 160.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Text(
            l10n.recommendedForYou,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: cardSize + 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad - 8),
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              return _RecommendedCard(
                recommendation: rec,
                size: cardSize,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final RecommendedAlbum recommendation;
  final double size;

  const _RecommendedCard({
    required this.recommendation,
    required this.size,
  });

  String? _getReasonLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final album = recommendation.album;

    switch (recommendation.reason) {
      case 'artist':
        return l10n.recommendedBecauseYouLike(album.artist ?? '');
      case 'genre':
        return l10n.recommendedInYourStyle(album.genre ?? '');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reason = _getReasonLabel(context);

    return GestureDetector(
      onTap: () => NavigationHelper.push(
        context,
        AlbumScreen(albumId: recommendation.album.id),
      ),
      child: Container(
        width: size,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtwork(
              coverArt: recommendation.album.coverArt,
              size: size,
              borderRadius: 12,
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.album.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              recommendation.album.artist ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (reason != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  reason,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
