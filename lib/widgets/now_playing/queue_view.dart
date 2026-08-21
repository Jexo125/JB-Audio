import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/player_provider.dart';
import '../album_artwork.dart';

class QueueView extends StatelessWidget {
  const QueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final queue = provider.queue;
        final currentIndex = provider.currentIndex;

        if (queue.isEmpty) {
          return const Center(
            child: Text(
              "Nessun brano in coda",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 100, bottom: 40, left: 24, right: 24),
          itemCount: queue.length + 1, // +1 pour l'en-tête "À suivre"
          itemBuilder: (context, index) {
            if (index == 0) {
              final isFr = Localizations.localeOf(context).languageCode == 'fr';

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
                child: Text(
                  isFr ? "À suivre" : "Up Next",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            final songIndex = index - 1;
            final song = queue[songIndex];
            final isPlaying = songIndex == currentIndex;
            final isPast = songIndex < currentIndex;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: AlbumArtwork(
                coverArt: song.coverArt,
                size: 48,
                borderRadius: 8,
              ),
              title: Text(
                song.title.isNotEmpty ? song.title : 'Titre inconnu',
                style: TextStyle(
                  color: isPlaying ? Theme.of(context).colorScheme.primary : (isPast ? Colors.white38 : Colors.white),
                  fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                song.artist ?? 'Artista Sconosciuto',
                style: TextStyle(
                  color: isPlaying ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8) : (isPast ? Colors.white24 : Colors.white70),
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: isPlaying
                  ? Icon(Icons.equalizer_rounded, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                provider.skipToIndex(songIndex);
              },
            );
          },
        );
      },
    );
  }
}
