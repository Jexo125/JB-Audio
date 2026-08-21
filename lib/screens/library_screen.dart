import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/local_music_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import 'album_screen.dart';
import 'package:jbaudio/screens/playlist_screen.dart';
import 'favorites_screen.dart';
import 'liked_albums_screen.dart';
import 'playlists_screen.dart';
import 'settings_screen.dart';
import 'artist_screen.dart';
import 'radio_screen.dart';
import 'all_songs_screen.dart';
import 'downloads_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/offline_service.dart';
import '../widgets/album_artwork.dart';
import '../utils/genre_translator.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

enum _SortMode { alphabeticalAZ, alphabeticalZA, recentlyAdded }

class _LibraryScreenState extends State<LibraryScreen> {
  String _selectedFilter = 'Faves';
  _SortMode _currentSort = _SortMode.alphabeticalAZ;

  List<String> _getFilters(BuildContext context) {
    final libraryProvider =
    Provider.of<LibraryProvider>(context, listen: false);
    if (libraryProvider.isLocalOnlyMode) {
      return ['Faves', 'Albums', 'Artists', 'Songs', 'Genres', 'Years'];
    }
    return ['Faves', 'Albums', 'Artists', 'Songs'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 60,
            backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourLibrary,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Consumer<LibraryProvider>(
                  builder: (context, provider, _) {
                    final count = _getCategoryCount(provider);
                    if (count == null) return const SizedBox.shrink();
                    return Text(
                      count,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              if (_selectedFilter != 'Faves' && _selectedFilter != 'Genres' && _selectedFilter != 'Years')
                PopupMenuButton<_SortMode>(
                  icon: Icon(
                    CupertinoIcons.sort_down,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onSelected: (mode) {
                    setState(() {
                      _currentSort = mode;
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _SortMode.alphabeticalAZ,
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.sort_up),
                          const SizedBox(width: 8),
                          Text(l10n.sortAZ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _SortMode.alphabeticalZA,
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.sort_down),
                          const SizedBox(width: 8),
                          Text(l10n.sortZA),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _SortMode.recentlyAdded,
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.time),
                          const SizedBox(width: 8),
                          Text(l10n.sortRecent),
                        ],
                      ),
                    ),
                  ],
                ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.refresh,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  final libraryProvider = Provider.of<LibraryProvider>(
                    context,
                    listen: false,
                  );
                  libraryProvider.refresh();
                },
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.plus,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showCreatePlaylistDialog(context),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.gear,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final filters = _getFilters(context);
                final filterLabels = {
                  'Faves': l10n.faves,
                  'Albums': l10n.filterAlbums,
                  'Artists': l10n.filterArtists,
                  'Songs': l10n.songs,
                  'Genres': l10n.genres,
                  'Years': l10n.years,
                };
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filterLabels[filter] ?? filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = selected ? filter : 'Faves';
                            });
                          },
                          backgroundColor: isDark
                              ? const Color(0xFF282828)
                              : Colors.grey[200],
                          selectedColor: isDark ? Colors.white : Colors.black,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          if (_selectedFilter == 'Faves')
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                ),
                delegate: SliverChildListDelegate([
                  _LibraryGridCard(
                    icon: CupertinoIcons.list_bullet,
                    iconColor: const Color(0xFF3B82F6),
                    title: l10n.playlists,
                    subtitle: l10n.yourPlaylists,
                    onTap: () => _navigate(context, const PlaylistsScreen()),
                  ),
                  _LibraryGridCard(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: const Color(0xFF8B5CF6),
                    title: l10n.likedSongs,
                    subtitle: l10n.playlist,
                    isGradient: true,
                    onTap: () => _navigate(context, const FavoritesScreen()),
                  ),
                  _LibraryGridCard(
                    icon: CupertinoIcons.music_note_list,
                    iconColor: const Color(0xFF34C759),
                    title: l10n.songs,
                    subtitle: l10n.songs,
                    onTap: () => _navigate(context, const AllSongsScreen()),
                  ),
                  _LibraryGridCard(
                    icon: CupertinoIcons.star_fill,
                    iconColor: const Color(0xFFFF9500),
                    title: l10n.likedAlbums,
                    subtitle: l10n.albums,
                    onTap: () => _navigate(context, const LikedAlbumsScreen()),
                  ),
                  _LibraryGridCard(
                    icon: CupertinoIcons.antenna_radiowaves_left_right,
                    iconColor: const Color(0xFF34C759),
                    title: l10n.radioStations,
                    subtitle: l10n.internetRadio,
                    onTap: () => _navigate(context, const RadioScreen()),
                  ),
                  _LibraryGridCard(
                    icon: CupertinoIcons.arrow_down_circle_fill,
                    iconColor: const Color(0xFF00C7BE),
                    title: 'Téléchargements',
                    subtitle: 'Titres hors-ligne',
                    onTap: () => _navigate(context, const DownloadsScreen()),
                  ),
                ]),
              ),
            ),
          Consumer<LibraryProvider>(
            builder: (context, libraryProvider, _) {
              final items = _getFilteredItems(context, libraryProvider);

              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _LibraryEmptyState(
                    isLocalMode: libraryProvider.isLocalOnlyMode,
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return _buildLibraryItem(context, item);
                }, childCount: items.length),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 150)),
        ],
      ),
    );
  }

  String? _getCategoryCount(LibraryProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return switch (_selectedFilter) {
      'Albums' => l10n.albumsCount(provider.cachedAllAlbums.length),
      'Artists' => l10n.artistsCount(provider.artists.length),
      'Songs' => l10n.songsCount(provider.cachedAllSongs.length),
      _ => null,
    };
  }

  List<_LibraryItem> _getFilteredItems(
      BuildContext context,
      LibraryProvider provider,
      ) {
    final l10n = AppLocalizations.of(context)!;
    List<_LibraryItem> items = [];

    if (_selectedFilter == 'Faves') {
      items.addAll(
        provider.playlists.map(
              (p) => _LibraryItem(
            type: 'Playlist',
            id: p.id,
            name: p.name,
            subtitle: l10n.songsCount(p.songCount ?? 0),
            coverArt: p.coverArt,
          ),
        ),
      );
      final recent = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums.take(10).toList()
          : provider.recentAlbums.take(10).toList();
      items.addAll(
        recent.map(
              (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle:
            a.artistParticipants != null && a.artistParticipants!.isNotEmpty
                ? a.artistParticipants!.map((r) => r.name).join(', ')
                : (a.artist ?? ''),
            coverArt: a.coverArt,
          ),
        ),
      );
      return items;
    }

    if (_selectedFilter == 'Albums') {
      final albums = List<Album>.from(provider.isLocalOnlyMode
          ? provider.cachedAllAlbums
          : (provider.cachedAllAlbums.isNotEmpty
          ? provider.cachedAllAlbums
          : provider.recentAlbums));

      _sortAlbums(albums);

      items.addAll(
        albums.map(
              (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle: () {
              final artistStr = a.artistParticipants != null &&
                  a.artistParticipants!.isNotEmpty
                  ? a.artistParticipants!.map((r) => r.name).join(', ')
                  : (a.artist ?? '');
              if (a.year != null && artistStr.isNotEmpty) {
                return '$artistStr • ${a.year}';
              }
              return artistStr.isNotEmpty
                  ? artistStr
                  : (a.year?.toString() ?? '');
            }(),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Artists') {
      final artists = List<Artist>.from(provider.artists);
      _sortArtists(artists);

      items.addAll(
        artists.map(
              (a) => _LibraryItem(
            type: 'Artist',
            id: a.id,
            name: a.name,
            subtitle: l10n.albumsCount(a.albumCount ?? 0),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Songs') {
      final songs = List<Song>.from(provider.cachedAllSongs);
      _sortSongs(songs);

      items.addAll(
        songs.map(
              (s) => _LibraryItem(
            type: 'Song',
            id: s.id,
            name: s.title,
            subtitle: s.artist ?? '',
            coverArt: s.coverArt,
          ),
        ),
      );
    }

    if (_selectedFilter == 'Genres') {
      final genreMap = <String, List<Song>>{};
      for (final s in provider.cachedAllSongs) {
        final g = (s.genre ?? 'Unknown').trim();
        if (g.isEmpty) continue;
        genreMap.putIfAbsent(g, () => []).add(s);
      }
      final sortedGenres = genreMap.keys.toList()..sort();
      items.addAll(
        sortedGenres.map(
              (g) => _LibraryItem(
            type: 'Genre',
            id: 'genre_$g',
            name: g,
            displayName: GenreTranslator.translate(l10n, g),
            subtitle: l10n.songsCount(genreMap[g]!.length),
            coverArt: genreMap[g]!
                .firstWhere(
                  (s) => s.coverArt != null,
              orElse: () => genreMap[g]!.first,
            )
                .coverArt ??
                '',
          ),
        ),
      );
    }

    if (_selectedFilter == 'Years') {
      final yearMap = <int, List<Album>>{};
      for (final a in provider.cachedAllAlbums) {
        if (a.year != null) {
          yearMap.putIfAbsent(a.year!, () => []).add(a);
        }
      }
      final sortedYears = yearMap.keys.toList()..sort((a, b) => b.compareTo(a));
      items.addAll(
        sortedYears.map(
              (y) => _LibraryItem(
            type: 'Year',
            id: 'year_$y',
            name: y.toString(),
            subtitle: l10n.albumsCount(yearMap[y]!.length),
            coverArt: yearMap[y]!
                .firstWhere(
                  (a) => a.coverArt != null,
              orElse: () => yearMap[y]!.first,
            )
                .coverArt ??
                '',
          ),
        ),
      );
    }

    return items;
  }

  void _sortAlbums(List<Album> albums) {
    switch (_currentSort) {
      case _SortMode.alphabeticalAZ:
        albums.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortMode.alphabeticalZA:
        albums.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortMode.recentlyAdded:
        albums.sort((a, b) => (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)));
        break;
    }
  }

  void _sortArtists(List<Artist> artists) {
    switch (_currentSort) {
      case _SortMode.alphabeticalAZ:
        artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortMode.alphabeticalZA:
        artists.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case _SortMode.recentlyAdded:
        // Artist model doesn't have created date, keep AZ
        artists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
  }

  void _sortSongs(List<Song> songs) {
    switch (_currentSort) {
      case _SortMode.alphabeticalAZ:
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case _SortMode.alphabeticalZA:
        songs.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case _SortMode.recentlyAdded:
        songs.sort((a, b) => (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)));
        break;
    }
  }

  Widget _buildLibraryItem(BuildContext context, _LibraryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    final String typeLabel = switch (item.type) {
      'Playlist' => l10n.filterPlaylists,
      'Album' => l10n.filterAlbums,
      'Artist' => l10n.filterArtists,
      'Song' => l10n.songs,
      _ => item.type,
    };

    final Widget artwork = item.coverArt != null && item.coverArt!.isNotEmpty
        ? AlbumArtwork(
            coverArt: item.coverArt,
            size: 56,
            borderRadius: item.type == 'Artist' ? 28 : 4,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(item.type == 'Artist' ? 28 : 4),
            child: SizedBox(
              width: 56,
              height: 56,
              child: _buildPlaceholder(item.type, isDark),
            ),
          );

    return InkWell(
      onTap: () => _openItem(context, item),
      onLongPress: item.type == 'Playlist'
          ? () => _showDeletePlaylistDialog(context, item)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            artwork,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.displayName ?? item.name,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel • ${item.subtitle}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.type == 'Playlist')
              ValueListenableBuilder<Set<String>>(
                valueListenable: OfflineService().downloadedPlaylistIds,
                builder: (context, downloaded, _) {
                  return ValueListenableBuilder<Set<String>>(
                    valueListenable: OfflineService().queuedPlaylistIds,
                    builder: (context, queued, _) {
                      if (downloaded.contains(item.id)) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle, color: Colors.green, size: 18),
                        );
                      }
                      if (queued.contains(item.id)) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type, bool isDark) {
    IconData icon;
    switch (type) {
      case 'Playlist':
        icon = Icons.queue_music;
        break;
      case 'Album':
        icon = Icons.album;
        break;
      case 'Artist':
        icon = Icons.person;
        break;
      case 'Song':
        icon = Icons.music_note;
        break;
      case 'Genre':
        icon = Icons.local_offer;
        break;
      case 'Year':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.music_note;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
        ),
        borderRadius: BorderRadius.circular(type == 'Artist' ? 28 : 4),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

  void _openItem(BuildContext context, _LibraryItem item) {
    switch (item.type) {
      case 'Playlist':
        NavigationHelper.push(
          context,
          PlaylistScreen(playlistId: item.id, playlistName: item.name),
        );
        break;
      case 'Album':
        NavigationHelper.push(context, AlbumScreen(albumId: item.id));
        break;
      case 'Artist':
        NavigationHelper.push(context, ArtistScreen(artistId: item.id));
        break;
      case 'Song':
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs;
        final index = songs.indexWhere((s) => s.id == item.id);
        if (index >= 0) {
          playerProvider.playSong(
            songs[index],
            playlist: songs,
            startIndex: index,
          );
        }
        break;
      case 'Genre':
        final genreName = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs
            .where((s) => s.genre == genreName)
            .toList();
        if (songs.isNotEmpty) {
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
        }
        break;
      case 'Year':
        final yearStr = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final albums = libraryProvider.cachedAllAlbums
            .where((a) => a.year?.toString() == yearStr)
            .toList();
        if (albums.isNotEmpty) {
          NavigationHelper.push(context, AlbumScreen(albumId: albums.first.id));
        }
        break;
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    NavigationHelper.push(context, screen);
  }

  void _showDeletePlaylistDialog(BuildContext context, _LibraryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(
          AppLocalizations.of(context)!.deletePlaylistConfirmation(item.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final libraryProvider = Provider.of<LibraryProvider>(
                context,
                listen: false,
              );
              try {
                OfflineService().cancelPlaylistDownload(item.id);
                await libraryProvider.deletePlaylist(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .playlistDeleted(item.name),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.errorDeletingPlaylist(e),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newPlaylist),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.playlistName,
              filled: true,
              fillColor:
              isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final libraryProvider = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                try {
                  await libraryProvider.createPlaylist(controller.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .playlistCreated(controller.text),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(
                            context,
                          )!
                              .errorCreatingPlaylist(e),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void _showSettings(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final bool isLocalMode;

  const _LibraryEmptyState({required this.isLocalMode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            isLocalMode ? l10n.localLibraryEmpty : l10n.libraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocalMode
                ? l10n.localLibraryEmptySubtitle
                : l10n.libraryEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (isLocalMode) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final localService = Provider.of<LocalMusicService>(
                  context,
                  listen: false,
                );
                if (!localService.isScanning) {
                  localService.scanForMusic();
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.scanForMusic),
              style: ElevatedButton.styleFrom(
                foregroundColor: isDark ? Colors.black : Colors.white,
                backgroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LibraryItem {
  final String type;
  final String id;
  final String name;
  final String? displayName;
  final String subtitle;
  final String? coverArt;

  _LibraryItem({
    required this.type,
    required this.id,
    required this.name,
    this.displayName,
    required this.subtitle,
    this.coverArt,
  });
}

class _LibraryGridCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isGradient;
  final VoidCallback? onTap;

  const _LibraryGridCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: isGradient
                        ? LinearGradient(
                            colors: [iconColor.withValues(alpha: 0.8), iconColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isGradient ? null : iconColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    icon,
                    color: isGradient ? Colors.white : iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
