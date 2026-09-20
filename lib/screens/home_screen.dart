import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../services/offline_service.dart';
import '../services/storage_service.dart';
import '../services/xp_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'playlist_screen.dart';
import 'music_quests_screen.dart';
import '../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _cachedMixes = const {};
  List<Song> _cachedPersonalized = const [];
  String _lastRandomKey = '';
  bool _isBadgeUnlocked = false;
  bool _shouldAnimateTrophy = false;
  static bool _sessionBadgeAnimated = false;

  @override
  void initState() {
    super.initState();
    _initBadgeStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final xpService = Provider.of<XpService>(context, listen: false);
        if (xpService.isEnabled) {
          GamificationIntroOverlay.showIfNeeded(context);
        }
      }
    });
  }

  Future<void> _initBadgeStatus() async {
    final storage = StorageService();
    final unlocked = await storage.getCuriousBadgeUnlocked();
    
    // Listen for real-time updates (from DeveloperCard)
    storage.curiousBadgeNotifier.addListener(_onBadgeChanged);

    if (mounted) {
      setState(() {
        _isBadgeUnlocked = unlocked;
        // If already unlocked at startup, we consider it "already seen/animated" for this session
        if (unlocked) {
          _sessionBadgeAnimated = true;
        }
      });
    }
  }

  void _onBadgeChanged() {
    if (!mounted) return;
    final unlocked = StorageService().curiousBadgeNotifier.value;
    
    if (unlocked && !_isBadgeUnlocked) {
      setState(() {
        _isBadgeUnlocked = true;
        if (!_sessionBadgeAnimated) {
          _shouldAnimateTrophy = true;
          _sessionBadgeAnimated = true;
        }
      });
    }
  }

  @override
  void dispose() {
    StorageService().curiousBadgeNotifier.removeListener(_onBadgeChanged);
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    String greeting;

    if (hour < 12) {
      greeting = AppLocalizations.of(context)!.goodMorning;
    } else if (hour < 17) {
      greeting = AppLocalizations.of(context)!.goodAfternoon;
    } else {
      greeting = AppLocalizations.of(context)!.goodEvening;
    }

    final subsonicService = Provider.of<SubsonicService>(context, listen: false);
    final username = subsonicService.config?.username;

    if (username != null && username.isNotEmpty) {
      return '$greeting $username';
    }

    return greeting;
  }

  String _computeRandomKey(List<Song> songs) {
    if (songs.isEmpty) return '';

    return songs.map((s) => s.id).join('|');
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _isDesktop;
    final hPad = isDesktop ? 32.0 : 16.0;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: isDesktop ? 80 : 70,
            backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: hPad, bottom: 14),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: isDesktop ? 28 : 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (_isBadgeUnlocked) ...[
                    const SizedBox(width: 8),
                    _TrophyBadge(
                      title: l10n.badgeCuriousTitle,
                      description: l10n.badgeCuriousDesc,
                      shouldAnimate: _shouldAnimateTrophy,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              Consumer<XpService>(
                builder: (context, xpService, _) {
                  if (!xpService.isEnabled) return const SizedBox.shrink();
                  return IconButton(
                    icon: Icon(
                      CupertinoIcons.flag_fill,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      NavigationHelper.push(context, const MusicQuestsScreen());
                    },
                  );
                },
              ),
              if (isDesktop) const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer2<LibraryProvider, RecommendationService>(
              builder: (context, libraryProvider, recommendationService, _) {
                if (libraryProvider.isLoading &&
                    !libraryProvider.isInitialized) {
                  return _buildLoadingState(isDesktop, hPad);
                }

                final allSongs = libraryProvider.randomSongs;
                final key = _computeRandomKey(allSongs);

                if (recommendationService.enabled && key.isNotEmpty) {
                  if (key != _lastRandomKey) {
                    _cachedMixes = recommendationService.generateMixes(
                      allSongs,
                    );
                    _cachedPersonalized = recommendationService
                        .getPersonalizedFeed(allSongs, limit: 10);
                    _lastRandomKey = key;
                  }
                } else {
                  _cachedMixes = const {};
                  _cachedPersonalized = const [];
                  _lastRandomKey = '';
                }

                Map<String, List<Song>> mixes = _cachedMixes;
                List<Song> personalizedFeed = _cachedPersonalized;
                List<Album> recentAlbums = libraryProvider.recentAlbums;
                List<Playlist> playlists = libraryProvider.playlists;

                final isOffline = Provider.of<AuthProvider>(context, listen: false).state == AuthState.offlineMode;
                final offlineService = OfflineService();

                if (isOffline) {
                  final downloadedIds =
                      offlineService.getDownloadedSongIds().toSet();
                  final downloadedPlaylistIds =
                      offlineService.downloadedPlaylistIds.value.toSet();

                  final allSongs = libraryProvider.cachedAllSongs;
                  final Set<String> downloadedAlbumIds = {};
                  for (final song in allSongs) {
                    if (downloadedIds.contains(song.id) &&
                        song.albumId != null) {
                      downloadedAlbumIds.add(song.albumId!);
                    }
                  }

                  recentAlbums = recentAlbums
                      .where((a) => downloadedAlbumIds.contains(a.id))
                      .toList();
                  playlists = playlists
                      .where((p) => downloadedPlaylistIds.contains(p.id))
                      .toList();

                  final Map<String, List<Song>> offlineMixes = {};
                  for (final entry in mixes.entries) {
                    final filtered = entry.value
                        .where((s) => downloadedIds.contains(s.id))
                        .toList();
                    if (filtered.isNotEmpty) {
                      offlineMixes[entry.key] = filtered;
                    }
                  }
                  mixes = offlineMixes;

                  personalizedFeed = personalizedFeed
                      .where((s) => downloadedIds.contains(s.id))
                      .toList();
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const XpSummaryCard(),
                      
                      if (libraryProvider.recentAlbums.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        HorizontalScrollSection(
                          title: AppLocalizations.of(context)!.recentlyPlayed,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          cardSize: isDesktop ? 180 : 150,
                          children: libraryProvider.recentAlbums
                              .take(10)
                              .map(
                                (album) => AlbumCard(
                                  album: album,
                                  size: isDesktop ? 180 : 150,
                                  onTap: () => _openAlbum(context, album.id),
                                ),
                              )
                              .toList(),
                        ),
                      ],

                      if (libraryProvider.recommendedAlbums.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        RecommendedCarousel(hPad: hPad),
                      ],

                      const SizedBox(height: 24),

                      // Favorite Playlists Section
                      const FavoritePlaylistsSection(),
                      const SizedBox(height: 24),

                      if (mixes.containsKey('Quick Picks'))
                        _buildMixSection(
                          context: context,
                          title: AppLocalizations.of(context)!.quickPicks,
                          icon: Icons.bolt_rounded,
                          songs: mixes['Quick Picks']!,
                          isDesktop: isDesktop,
                          hPad: hPad,
                        ),

                      if (mixes.containsKey('Discover Mix'))
                        _buildMixSection(
                          context: context,
                          title: AppLocalizations.of(context)!.discoverMix,
                          icon: Icons.explore_rounded,
                          songs: mixes['Discover Mix']!,
                          isDesktop: isDesktop,
                          hPad: hPad,
                        ),

                      for (final entry in mixes.entries.where(
                        (e) =>
                            e.key != 'Quick Picks' && e.key != 'Discover Mix',
                      ))
                        _buildMixSection(
                          context: context,
                          title: entry.key,
                          icon: Icons.auto_awesome,
                          songs: entry.value,
                          isDesktop: isDesktop,
                          hPad: hPad,
                        ),

                      for (final entry in mixes.entries.where(
                        (e) => e.key.contains('Vibes'),
                      ))
                        _buildMixSection(
                          context: context,
                          title: entry.key,
                          icon: Icons.nightlight_round,
                          songs: entry.value,
                          isDesktop: isDesktop,
                          hPad: hPad,
                        ),

                      if (libraryProvider.playlists.isNotEmpty) ...[
                        HorizontalScrollSection(
                          title: AppLocalizations.of(context)!.yourPlaylists,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          cardSize: isDesktop ? 180 : 150,
                          children: libraryProvider.playlists
                              .take(10)
                              .map(
                                (playlist) => _PlaylistCard(
                                  playlist: playlist,
                                  size: isDesktop ? 180 : 150,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaylistScreen(
                                        playlistId: playlist.id,
                                        playlistName: playlist.name,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (!recommendationService.enabled &&
                          libraryProvider.randomSongs.isNotEmpty) ...[
                        HorizontalScrollSection(
                          title: AppLocalizations.of(context)!.madeForYou,
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          cardSize: isDesktop ? 180 : 150,
                          children: libraryProvider.randomSongs
                              .take(10)
                              .map(
                                (song) => _DesktopSongCard(
                                  song: song,
                                  playlist: libraryProvider.randomSongs,
                                  index: libraryProvider.randomSongs.indexOf(song),
                                  size: isDesktop ? 180 : 150,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (libraryProvider.recentAlbums.isEmpty &&
                          libraryProvider.playlists.isEmpty &&
                          libraryProvider.randomSongs.isEmpty &&
                          mixes.isEmpty) ...[
                        const SizedBox(height: 48),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.music_note_rounded,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!
                                    .noContentAvailable,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.tryRefreshing,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => libraryProvider.refresh(),
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  AppLocalizations.of(context)!.refresh,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 150),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDesktop, double hPad) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: List.generate(
              isDesktop ? 6 : 6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        HorizontalShimmerList(
          count: 5,
          child: AlbumCardShimmer(size: isDesktop ? 180 : 150),
        ),
      ],
    );
  }

  void _openAlbum(BuildContext context, String albumId) {
    NavigationHelper.push(context, AlbumScreen(albumId: albumId));
  }

  Widget _buildMixSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Song> songs,
    required bool isDesktop,
    required double hPad,
  }) {
    final cardSize = isDesktop ? 180.0 : 150.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HorizontalScrollSection(
          title: title,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          cardSize: cardSize,
          children: songs.take(10).map((song) => _DesktopSongCard(
            song: song,
            playlist: songs,
            index: songs.indexOf(song),
            size: cardSize,
          )).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TrophyBadge extends StatefulWidget {
  final String title;
  final String description;
  final bool shouldAnimate;

  const _TrophyBadge({
    required this.title,
    required this.description,
    this.shouldAnimate = false,
  });

  @override
  State<_TrophyBadge> createState() => _TrophyBadgeState();
}

class _TrophyBadgeState extends State<_TrophyBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    
    if (widget.shouldAnimate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showBadgeInfo(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () => _showBadgeInfo(context),
        child: Tooltip(
          message: widget.title,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 14, // Adjusted for AppBar title scale
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback? onTap;
  final double size;

  const _PlaylistCard({required this.playlist, this.onTap, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverArtUrl = playlist.coverArt != null
        ? subsonicService.getCoverArtUrl(playlist.coverArt!, size: 300)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverArtUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverArtUrl,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                        errorWidget: (ctx, err, stack) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color:
                            isDark ? const Color(0xFF2C2C2E) : Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 50,
                            color: Colors.white30,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (playlist.songCount != null)
              Text(
                '${playlist.songCount} songs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}



class _DesktopSongCard extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final int index;
  final double size;

  const _DesktopSongCard({
    required this.song,
    required this.playlist,
    required this.index,
    required this.size,
  });

  @override
  State<_DesktopSongCard> createState() => _DesktopSongCardState();
}

class _DesktopSongCardState extends State<_DesktopSongCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          final p = context.read<PlayerProvider>();
          p.playSong(widget.song, playlist: widget.playlist, startIndex: widget.index);
        },
        child: SizedBox(
          width: widget.size,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.04 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [],
                  ),
                  child: Stack(
                    children: [
                      AlbumArtwork(
                        coverArt: widget.song.coverArt,
                        size: widget.size,
                        borderRadius: 8,
                      ),
                      if (_isHovered)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.appleMusicRed,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.song.title,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.song.artist ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
