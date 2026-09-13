import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/statistics_service.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import '../utils/navigation_helper.dart';
import 'screens.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late Future<_FullStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadAllStats();
  }

  Future<_FullStats> _loadAllStats() async {
    final statsService = Provider.of<StatisticsService>(context, listen: false);
    
    // Using a wide range for lifetime metrics that require bounds
    final start = DateTime(2000);
    final end = DateTime(2100);

    // Last 7 days for history
    final now = DateTime.now();
    final historyStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));

    final results = await Future.wait([
      statsService.getGlobalStats(),
      statsService.getActiveDayCount(start: start, end: end),
      statsService.getDiscoveryCount(start: start, end: end),
      statsService.getTopSongs(limit: 10),
      statsService.getTopArtists(limit: 10),
      statsService.getTopAlbums(limit: 10),
      statsService.getTopGenres(limit: 10),
      statsService.getListeningHistory(
        start: historyStart,
        end: now,
        interval: 'day',
      ),
    ]);

    return _FullStats(
      global: results[0] as GlobalStats,
      activeDays: results[1] as int,
      discoveries: results[2] as int,
      topSongs: results[3] as List<StatItem>,
      topArtists: results[4] as List<StatItem>,
      topAlbums: results[5] as List<StatItem>,
      topGenres: results[6] as List<StatItem>,
      history: results[7] as List<TimeDataPoint>,
    );
  }

  String _formatListenTime(int seconds, AppLocalizations l10n) {
    if (seconds < 60) return "< 1m";
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return l10n.durationHoursMinutes(hours, minutes);
    }
    return l10n.durationMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statisticsTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
      ),
      body: FutureBuilder<_FullStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      l10n.errorLoadingSongs, 
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _statsFuture = _loadAllStats();
                      }),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final stats = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: l10n.recentActivity),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          StatMetricCard(
                            icon: CupertinoIcons.time,
                            label: l10n.listeningTime,
                            value: _formatListenTime(stats.global.totalListenTime, l10n),
                          ),
                          StatMetricCard(
                            icon: CupertinoIcons.play_circle,
                            label: l10n.plays,
                            value: stats.global.totalPlays.toString(),
                          ),
                          StatMetricCard(
                            icon: CupertinoIcons.music_note_list,
                            label: l10n.uniqueTitles,
                            value: stats.global.uniqueSongs.toString(),
                          ),
                          StatMetricCard(
                            icon: CupertinoIcons.calendar,
                            label: l10n.activeDays,
                            value: stats.activeDays.toString(),
                          ),
                          StatMetricCard(
                            icon: CupertinoIcons.sparkles,
                            label: l10n.discoveries,
                            value: stats.discoveries.toString(),
                          ),
                          StatMetricCard(
                            icon: CupertinoIcons.checkmark_circle,
                            label: l10n.completedTracks,
                            value: stats.global.totalCompleted.toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SectionHeader(
                      title: l10n.listeningHistoryTitle,
                      // We don't have a subtitle parameter in SectionHeader, 
                      // and SectionHeader implementation shows it might be different.
                      // Let's check SectionHeader again.
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        l10n.last7Days,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HistoryChart(data: stats.history),
                    const SizedBox(height: 32),
                    
                    if (stats.topSongs.isNotEmpty) ...[
                      SectionHeader(title: l10n.topSongs),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.topSongs.length,
                        itemBuilder: (context, index) {
                          final item = stats.topSongs[index];
                          return _RankedSongTile(
                            rank: index + 1,
                            item: item,
                            onTap: () {
                              final song = Song(
                                id: item.id,
                                title: item.name,
                                artist: item.subName,
                                coverArt: item.imageUrl,
                              );
                              context.read<PlayerProvider>().playSong(song, playlist: [song]);
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (stats.topArtists.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: l10n.topArtists,
                        cardSize: 140,
                        children: stats.topArtists.map((item) {
                          return ArtistCard(
                            artist: Artist(
                              id: item.id,
                              name: item.name,
                              coverArt: item.imageUrl,
                            ),
                            size: 140,
                            onTap: () => NavigationHelper.push(context, ArtistScreen(artistId: item.id)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (stats.topAlbums.isNotEmpty) ...[
                      HorizontalScrollSection(
                        title: l10n.topAlbums,
                        cardSize: 160,
                        children: stats.topAlbums.map((item) {
                          return AlbumCard(
                            album: Album(
                              id: item.id,
                              name: item.name,
                              artist: item.subName,
                              coverArt: item.imageUrl,
                            ),
                            size: 160,
                            onTap: () => NavigationHelper.push(context, AlbumScreen(albumId: item.id)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (stats.topGenres.isNotEmpty) ...[
                      SectionHeader(title: l10n.topGenres),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: stats.topGenres.map((item) {
                            return Chip(
                              label: Text(item.name),
                              avatar: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                child: Text(
                                  item.playCount.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              backgroundColor: isDark ? const Color(0xFF282828) : Colors.grey[200],
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<TimeDataPoint> data;

  const _HistoryChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Text(
            l10n.noHistoryData,
            style: TextStyle(color: theme.disabledColor),
          ),
        ),
      );
    }

    final maxTime = data.map((e) => e.listenTime).reduce(max);
    final displayMax = maxTime > 0 ? maxTime : 1;

    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1C1C1E) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((point) {
          final heightFactor = point.listenTime / displayMax;
          final dateStr = "${point.timestamp.day}/${point.timestamp.month}";
          
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: FractionallySizedBox(
                    heightFactor: max(heightFactor, 0.05),
                    widthFactor: 0.6,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dateStr,
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankedSongTile extends StatelessWidget {
  final int rank;
  final StatItem item;
  final VoidCallback onTap;

  const _RankedSongTile({
    required this.rank,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AlbumArtwork(
            coverArt: item.imageUrl,
            size: 48,
            borderRadius: 4,
          ),
        ],
      ),
      title: Text(
        item.name,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${item.subName ?? ""} • ${l10n.playsCount(item.playCount)}',
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(CupertinoIcons.play_fill, size: 16),
    );
  }
}

class _FullStats {
  final GlobalStats global;
  final int activeDays;
  final int discoveries;
  final List<StatItem> topSongs;
  final List<StatItem> topArtists;
  final List<StatItem> topAlbums;
  final List<StatItem> topGenres;
  final List<TimeDataPoint> history;

  _FullStats({
    required this.global,
    required this.activeDays,
    required this.discoveries,
    required this.topSongs,
    required this.topArtists,
    required this.topAlbums,
    required this.topGenres,
    required this.history,
  });
}
