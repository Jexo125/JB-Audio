import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/sync_progress.dart';
import '../theme/app_theme.dart';

class LibrarySyncScreen extends StatelessWidget {
  const LibrarySyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, child) {
          final progress = libraryProvider.syncProgress;
          if (progress == null && libraryProvider.isInitialized) {
            // Should not happen if logic is correct, but safety first
            return const Center(child: CircularProgressIndicator());
          }

          final syncProgress = progress ?? SyncProgress(statusMessage: 'Initialisation...');
          final overallValue = syncProgress.overallProgress;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.arrow_2_circlepath,
                  size: 64,
                  color: AppTheme.appleMusicRed,
                ),
                const SizedBox(height: 32),
                Text(
                  'Synchronisation de votre bibliothèque',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  syncProgress.statusMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                // Overall Progress Bar
                Stack(
                  children: [
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.8 * overallValue,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.appleMusicRed, AppTheme.appleMusicPink],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.appleMusicRed.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${(overallValue * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Counters
                _buildCounterRow(
                  context,
                  'Artistes',
                  syncProgress.artistsCurrent,
                  syncProgress.artistsTotal,
                  syncProgress.currentCategory == SyncCategory.artists,
                ),
                const Divider(height: 24),
                _buildCounterRow(
                  context,
                  'Albums',
                  syncProgress.albumsCurrent,
                  syncProgress.albumsTotal,
                  syncProgress.currentCategory == SyncCategory.albums,
                ),
                const Divider(height: 24),
                _buildCounterRow(
                  context,
                  'Morceaux',
                  syncProgress.songsCurrent,
                  syncProgress.songsTotal,
                  syncProgress.currentCategory == SyncCategory.songs,
                ),
                
                const SizedBox(height: 64),
                const Text(
                  'Veuillez patienter...',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCounterRow(
    BuildContext context,
    String label,
    int current,
    int? total,
    bool isActive,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        isActive 
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              current > 0 && (total == null || current >= total)
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.circle,
              size: 18,
              color: current > 0 && (total == null || current >= total)
                ? Colors.green
                : Colors.grey,
            ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? theme.colorScheme.primary : null,
          ),
        ),
        const Spacer(),
        Text(
          total != null ? '$current / $total' : '$current',
          style: TextStyle(
            fontFamily: 'monospace',
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}
