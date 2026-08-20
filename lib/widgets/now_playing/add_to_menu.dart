import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/song.dart';
import '../../models/playlist.dart';
import '../../services/subsonic_service.dart';
import '../../l10n/app_localizations.dart';

class AddToMenu extends StatelessWidget {
  final Song song;
  final ImageProvider? coverProvider;

  const AddToMenu({
    super.key,
    required this.song,
    this.coverProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isStarred = song.starred ?? false;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (Cover, Title, Artist)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.withValues(alpha: 0.2),
                    child: coverProvider != null
                        ? Image(image: coverProvider!, fit: BoxFit.cover)
                        : const Icon(Icons.music_note, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist ?? AppLocalizations.of(context)!.unknownArtist,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Menu Options
            _buildDialogButton(
              context,
              icon: Icons.playlist_add_rounded,
              label: AppLocalizations.of(context)!.addToPlaylist,
              onTap: () {
                Navigator.of(context).pop();
                _showPlaylistSelector(context, song);
              },
            ),
            const SizedBox(height: 8),
            _buildDialogButton(
              context,
              icon: isStarred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: isStarred ? AppLocalizations.of(context)!.removeFromFavorites : AppLocalizations.of(context)!.addToFavorites,
              onTap: () async {
                Navigator.of(context).pop();
                final subsonic = Provider.of<SubsonicService>(context, listen: false);
                try {
                  if (isStarred) {
                    await subsonic.unstar(id: song.id);
                  } else {
                    await subsonic.star(id: song.id);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isStarred ? AppLocalizations.of(context)!.removedFromLikedSongs : AppLocalizations.of(context)!.addedToLikedSongs)),
                    );
                  }
                } catch (e) {
                  debugPrint('Error toggling favorite: $e');
                }
              },
              color: isStarred ? theme.colorScheme.primary : null,
            ),
            
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: color != null ? FontWeight.w600 : null),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: _PlaylistSelectionDialog(song: song),
      ),
    );
  }
}

class _PlaylistSelectionDialog extends StatefulWidget {
  final Song song;

  const _PlaylistSelectionDialog({required this.song});

  @override
  State<_PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState extends State<_PlaylistSelectionDialog> {
  List<Playlist>? _playlists;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    try {
      final playlists = await subsonic.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingPlaylists(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context)!.selectPlaylist,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_playlists == null || _playlists!.isEmpty)
               Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(AppLocalizations.of(context)!.noPlaylists, textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _playlists!.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists![index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: playlist.coverArt != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: Provider.of<SubsonicService>(context, listen: false)
                                      .getCoverArtUrl(playlist.coverArt!, size: 100),
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.queue_music_rounded, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.queue_music_rounded, color: Colors.grey),
                      ),
                      title: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(AppLocalizations.of(context)!.songsCount(playlist.songCount ?? 0)),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final subsonic = Provider.of<SubsonicService>(context, listen: false);
                        try {
                          await subsonic.updatePlaylist(playlistId: playlist.id, songIdsToAdd: [widget.song.id]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.addedToPlaylist(widget.song.title, playlist.name))),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.errorAddingToPlaylist(e.toString()))),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
