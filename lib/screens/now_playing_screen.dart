import 'package:flutter/material.dart' hide RepeatMode;
import '../widgets/blurred_gradient_background.dart';
import '../widgets/now_playing/album_art_view.dart';
import '../widgets/now_playing/marquee_text.dart';
import '../widgets/now_playing/playback_controls.dart';
import '../widgets/now_playing/playback_progress_slider.dart';
import '../widgets/now_playing/volume_slider.dart';
import '../widgets/now_playing/now_playing_bottom_actions.dart';
import 'lyrics_screen.dart';
import '../models/lyric_line.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/song.dart';
import '../services/palette_service.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/lrc_ttml_parser.dart';
import '../widgets/now_playing/queue_view.dart';
import '../widgets/now_playing/now_playing_more_menu.dart';
import '../widgets/now_playing/add_to_menu.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NowPlayingScreen extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final String artist;
  final String heroTag;
  final List<LyricLine> lyrics;
  final Song? song;
  final double topPadding;

  const NowPlayingScreen({
    super.key,
    required this.image,
    required this.title,
    required this.artist,
    required this.heroTag,
    this.lyrics = const [],
    this.song,
    this.topPadding = 0.0,
  });

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {

  late PageController _pageController;
  int _currentPage = 0;
  List<Color> _bgColors = [];
  List<LyricLine> _fetchedLyrics = [];
  bool _isLoadingLyrics = true;
  Song? _lastSong;
  ImageProvider? _currentImageProvider;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fetchedLyrics = widget.lyrics;
    _currentImageProvider = widget.image;
    _lastSong = widget.song;
    _extractColors();
    _fetchLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<PlayerProvider>(context);
    if (provider.currentSong != null && _lastSong?.id != provider.currentSong?.id) {
      _lastSong = provider.currentSong;
      _updateImageProviderAndColors();
      _fetchLyrics();
    }
  }

  Future<void> _updateImageProviderAndColors() async {
    if (_lastSong == null) return;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final coverUrl = _lastSong!.coverArt != null ? subsonic.getCoverArtUrl(_lastSong!.coverArt, size: 600) : null;
    if (coverUrl != null) {
      _currentImageProvider = CachedNetworkImageProvider(coverUrl);
    } else {
      _currentImageProvider = const AssetImage('assets/default_cover.png');
    }
    _extractColors();
  }

  Future<void> _fetchLyrics() async {
    if (_lastSong == null) return;

    setState(() => _isLoadingLyrics = true);
    try {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final offlineService = Provider.of<OfflineService>(context, listen: false);

      Map<String, dynamic>? rawLyrics;

      if (offlineService.isOfflineMode || _lastSong!.isLocal || offlineService.isSongDownloaded(_lastSong!.id)) {
        rawLyrics = await offlineService.getLocalLyrics(_lastSong!.id);
      }

      if (rawLyrics == null && !offlineService.isOfflineMode && !_lastSong!.isLocal) {
        rawLyrics = await subsonic.getLyricsBySongId(_lastSong!.id) ??
            await subsonic.getLyrics(artist: _lastSong!.artist, title: _lastSong!.title);
      }

      if (rawLyrics != null) {
        if (rawLyrics['value'] != null) {
          final lrcText = rawLyrics['value'] as String;
          if (mounted) {
            setState(() {
              _fetchedLyrics = LrcParser.parseLrc(lrcText);
              _isLoadingLyrics = false;
            });
          }
          return;
        } else if (rawLyrics['structuredLyrics'] != null) {
          final structured = rawLyrics['structuredLyrics'] as List?;
          if (structured != null && structured.isNotEmpty) {
            final lines = structured.first['line'] as List?;
            if (lines != null) {
              final parsedLines = lines.map((l) {
                return LyricLine(
                  startTime: Duration(milliseconds: l['start'] as int),
                  text: l['value'] as String,
                );
              }).toList();
              if (mounted) {
                setState(() {
                  _fetchedLyrics = parsedLines;
                  _isLoadingLyrics = false;
                });
              }
              return;
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _fetchedLyrics = [];
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching lyrics: $e');
    }

    if (mounted) {
      setState(() => _isLoadingLyrics = false);
    }
  }

  Future<void> _extractColors() async {
    if (_currentImageProvider == null || _lastSong == null) return;
    final imageId = _lastSong!.id;
    final colors = await PaletteService.extractColors(_currentImageProvider!, imageId);
    if (mounted) {
      setState(() {
        _bgColors = colors;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {}

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _bgColors.isNotEmpty ? _bgColors.first : Colors.white;

    return Theme(
      data: ThemeData.dark(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Stack(
            children: [
              // 1. Shared Animated Background
              Positioned.fill(
                child: BlurredGradientBackground(
                  colors: _bgColors,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // Page 0: Main Cover Art View
                      _buildMainView(accentColor),

                      // Page 1: Lyrics View
                      _fetchedLyrics.isNotEmpty
                          ? LyricsScreen(
                        lyrics: _fetchedLyrics,
                        currentTime: Provider.of<PlayerProvider>(context).position,
                        onSeek: (duration) {
                          Provider.of<PlayerProvider>(context, listen: false).seek(duration);
                        },
                      )
                          : Center(
                        child: _isLoadingLyrics
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                          Localizations.localeOf(context).languageCode == 'fr'
                              ? "Paroles non disponibles"
                              : "No lyrics available",
                          style: const TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ),

                      // Page 2: Queue View
                      const QueueView(),
                    ],
                  ),
                ),
              ),

              // 2. Drag Handle (Top)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 36,
                  height: 5,
                  margin: EdgeInsets.only(top: widget.topPadding > 0 ? widget.topPadding + 8 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // 3. Header
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      top: widget.topPadding > 0 ? widget.topPadding + 16 : 24,
                      left: 8.0,
                      right: 8.0
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                            _currentPage == 0 ? Icons.keyboard_arrow_down_rounded : Icons.close_rounded,
                            color: Colors.white,
                            size: 32
                        ),
                        onPressed: () {
                          if (_currentPage != 0) {
                            _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainView(Color accentColor) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, child) {
        final currentSong = provider.currentSong ?? widget.song;
        final title = currentSong?.title ?? widget.title;
        final artist = currentSong?.artist ?? widget.artist;
        final isStarred = currentSong?.starred ?? false;

        return SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 56), // Space for header

              // Album Art
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 8.0),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: AlbumArtView(
                        image: _currentImageProvider ?? widget.image,
                        tag: currentSong?.id ?? widget.heroTag,
                      ),
                    ),
                  ),
                ),
              ),

              // Badge Format Audio & Bitrate
              if (currentSong != null && currentSong.audioInfo.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      currentSong.audioInfo,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              // Title & Artist
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarqueeText(
                            text: title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (provider.hasSleepTimer || provider.sleepTimerEndCurrentSong)
                          StreamBuilder<int>(
                            stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
                            builder: (context, _) {
                              final remaining = provider.sleepTimerRemaining;
                              final endOfSong = provider.sleepTimerEndCurrentSong;
                              if (!provider.hasSleepTimer && !endOfSong) return const SizedBox.shrink();
                              
                              String text = "";
                              if (endOfSong) {
                                text = "Fin";
                              } else if (remaining != null) {
                                final m = remaining.inMinutes;
                                final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                                text = "$m:$s";
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            provider.hasSleepTimer || provider.sleepTimerEndCurrentSong
                                ? Icons.timer_rounded
                                : Icons.timer_outlined,
                            color: provider.hasSleepTimer || provider.sleepTimerEndCurrentSong
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const Dialog(
                                child: NowPlayingMoreMenu(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isStarred ? Icons.favorite_rounded : Icons.add_circle_outline_rounded,
                            color: isStarred ? Theme.of(context).colorScheme.primary : Colors.white,
                          ),
                          onPressed: () {
                            if (currentSong == null) return;
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: AddToMenu(
                                  song: currentSong,
                                  coverProvider: _currentImageProvider ?? widget.image,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: PlaybackProgressSlider(
                  position: provider.position,
                  duration: provider.duration,
                  accentColor: Colors.white,
                  onChanged: (val) {
                    provider.seek(val);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: PlaybackControls(
                  isPlaying: provider.isPlaying,
                  isShuffleEnabled: provider.shuffleEnabled,
                  repeatMode: provider.repeatMode,
                  accentColor: accentColor,
                  onPlayPause: () => provider.togglePlayPause(),
                  onNext: () => provider.skipNext(),
                  onPrevious: () => provider.skipPrevious(),
                  onShuffleToggle: () => provider.toggleShuffle(),
                  onRepeatToggle: () => provider.toggleRepeat(),
                ),
              ),

              const SizedBox(height: 24),

              // Volume
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: VolumeSlider(),
              ),

              // Bottom Actions
              NowPlayingBottomActions(
                isLyricsActive: _currentPage == 1,
                isQueueActive: _currentPage == 2,
                accentColor: accentColor,
                onLyricsTap: () {
                  if (_currentPage == 1) {
                    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
                onQueueTap: () {
                  if (_currentPage == 2) {
                    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}