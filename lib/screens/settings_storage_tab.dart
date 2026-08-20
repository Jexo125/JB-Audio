import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../services/cache_settings_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import 'download_playlist_status_screen.dart';
import '../widgets/settings/settings_section_card.dart';
import '../widgets/settings/settings_icon_badge.dart';
import '../utils/context_extensions.dart';

class SettingsStorageTab extends StatefulWidget {
  const SettingsStorageTab({super.key});

  @override
  State<SettingsStorageTab> createState() => _SettingsStorageTabState();
}

class _SettingsStorageTabState extends State<SettingsStorageTab> {
  final _cacheSettings = CacheSettingsService();
  final _offlineService = OfflineService();

  bool _imageCacheEnabled = true;
  bool _musicCacheEnabled = true;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';
  int _parallelDownloads = 3;
  bool _keepScreenOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupDownloadListener();
  }

  @override
  void dispose() {
    _offlineService.downloadState.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _setupDownloadListener() {
    _offlineService.downloadState.addListener(_onDownloadStateChanged);
  }

  void _onDownloadStateChanged() {
    if (!mounted) return;
    final state = _offlineService.downloadState.value;
    setState(() {
      _downloadedCount = state.downloadedCount;
    });
  }

  Future<void> _loadSettings() async {
    await _cacheSettings.initialize();
    await _offlineService.initialize();
    await _loadOfflineInfo();

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _parallelDownloads = _offlineService.getParallelDownloadsCount();
      _keepScreenOn = _offlineService.getKeepScreenOn();
    });
  }

  Future<void> _loadOfflineInfo() async {
    final count = _offlineService.getDownloadedCount();
    final size = await _offlineService.getDownloadedSize();
    if (mounted) {
      setState(() {
        _downloadedCount = count;
        _downloadedSize = _offlineService.formatSize(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionCacheSettings,
          children: [
            _buildCacheToggle(
              icon: CupertinoIcons.photo,
              iconGradient: const [Color(0xFFFF3B30), Color(0xFFFF453A)],
              title: AppLocalizations.of(context)!.imageCacheTitle,
              subtitle: AppLocalizations.of(context)!.imageCacheSubtitle,
              value: _imageCacheEnabled,
              onChanged: _toggleImageCache,
            ),
            const SettingsDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.music_note,
              iconGradient: const [Color(0xFF34C759), Color(0xFF30D158)],
              title: AppLocalizations.of(context)!.musicCacheTitle,
              subtitle: AppLocalizations.of(context)!.musicCacheSubtitle,
              value: _musicCacheEnabled,
              onChanged: _toggleMusicCache,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionCacheCleanup,
          children: [_buildClearAllCacheButton()],
        ),
        const SizedBox(height: 24),
        SettingsSectionCard(
          title: AppLocalizations.of(context)!.sectionOfflineDownloads,
          children: [
            _buildParallelDownloadsTile(),
            const SettingsDivider(),
            _buildKeepScreenOnTile(),
            const SettingsDivider(),
            _buildOfflineInfo(),
            const SettingsDivider(),
            _buildActiveDownloadsRow(),
            const SettingsDivider(),
            _buildPlaylistStatusRow(),
            const SettingsDivider(),
            _buildDownloadAllLibraryButton(),
            const SettingsDivider(),
            _buildDeleteDownloadsButton(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCacheToggle({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: iconGradient),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  void _toggleImageCache(bool value) async {
    setState(() => _imageCacheEnabled = value);
    await _cacheSettings.setImageCacheEnabled(value);
    if (!value) await DefaultCacheManager().emptyCache();
  }

  void _toggleMusicCache(bool value) async {
    setState(() => _musicCacheEnabled = value);
    await _cacheSettings.setMusicCacheEnabled(value);
  }

  Widget _buildKeepScreenOnTile() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9500), Color(0xFFFFCC00)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.bolt_fill, color: Colors.white, size: 18),
      ),
      title: Text(l10n.keepScreenOnDuringDownload, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        l10n.keepScreenOnDuringDownloadSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: CupertinoSwitch(
        value: _keepScreenOn,
        activeTrackColor: Theme.of(context).colorScheme.primary,
        onChanged: (value) async {
          setState(() => _keepScreenOn = value);
          await _offlineService.setKeepScreenOn(value);
        },
      ),
    );
  }

  Widget _buildParallelDownloadsTile() {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5AC8FA)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(CupertinoIcons.arrow_down_to_line, color: Colors.white, size: 18),
      ),
      title: Text(l10n.parallelDownloads, style: const TextStyle(fontSize: 16)),
      subtitle: Text(
        l10n.parallelDownloadsSubtitle,
        style: TextStyle(
          fontSize: 13,
          color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_parallelDownloads',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
          ),
        ],
      ),
      onTap: _showParallelDownloadsDialog,
    );
  }

  Future<void> _showParallelDownloadsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parallelDownloads),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 5].map((count) {
            final isSelected = count == _parallelDownloads;
            return ListTile(
              title: Text('$count ${count == 1 ? l10n.downloadSingular : l10n.downloadPlural}'),
              subtitle: count == 1
                ? Text(l10n.slowerButStable)
                : count == 5
                  ? Text(l10n.fasterButMoreData)
                  : null,
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () => Navigator.pop(context, count),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selected != null && selected != _parallelDownloads) {
      await _offlineService.setParallelDownloadsCount(selected);
      setState(() {
        _parallelDownloads = selected;
      });
    }
  }

  Widget _buildClearAllCacheButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.clearAllCache,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: _clearAllCache,
    );
  }

  void _clearAllCache() async {
    await DefaultCacheManager().emptyCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.allCacheCleared)),
      );
      setState(() {});
    }
  }

  Widget _buildOfflineInfo() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF007AFF), Color(0xFF5AC8FA)],
        icon: CupertinoIcons.arrow_down_circle,
      ),
      title: Text(
        AppLocalizations.of(context)!.downloadedSongs,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: Text(
        AppLocalizations.of(
          context,
        )!.downloadedStats(_downloadedCount, _downloadedSize),
        style: TextStyle(
          fontSize: 14,
          color: context.isDark
              ? AppTheme.darkSecondaryText
              : AppTheme.lightSecondaryText,
        ),
      ),
    );
  }

  Widget _buildActiveDownloadsRow() {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<DownloadState>(
      valueListenable: _offlineService.downloadState,
      builder: (context, state, _) {
        final subtitle = state.isDownloading && state.currentSong != null
            ? '${state.currentSong!.artist ?? ''} – ${state.currentSong!.title}  (${state.currentProgress}/${state.totalCount})'
            : state.isDownloading
            ? '${state.currentProgress}/${state.totalCount}'
            : l10n.noDownloadsInProgress;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: state.isDownloading
                    ? const [Color(0xFF34C759), Color(0xFF30D158)]
                    : const [Color(0xFF8E8E93), Color(0xFFAEAEB2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              state.isDownloading
                  ? CupertinoIcons.arrow_down_circle_fill
                  : CupertinoIcons.arrow_down_circle,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(l10n.activeDownloads, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
          // Navigation wired up in feature/download-detail-screens
          onTap: null,
        );
      },
    );
  }

  Widget _buildPlaylistStatusRow() {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _offlineService.downloadedSongIds,
      builder: (context, ids, _) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: SettingsIconBadge(
            gradientColors: const [Color(0xFF5856D6), Color(0xFF7B68EE)],
            icon: CupertinoIcons.music_note_list,
          ),
          title: Text(l10n.playlistDownloads, style: const TextStyle(fontSize: 16)),
          subtitle: Text(
            l10n.songsDownloaded(ids.length),
            style: TextStyle(
              fontSize: 12,
              color: context.isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText,
            ),
          ),
          trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DownloadPlaylistStatusScreen(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadAllLibraryButton() {
    return ValueListenableBuilder<DownloadState>(
      valueListenable: _offlineService.downloadState,
      builder: (context, downloadState, _) {
        final isDownloading = downloadState.isDownloading;
        final progress = downloadState.totalCount > 0
            ? downloadState.currentProgress / downloadState.totalCount
            : 0.0;

        if (isDownloading) {
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.arrow_down_circle_fill,
      ),
                title: Text(
                  AppLocalizations.of(context)!.downloadingLibrary(
                    downloadState.currentProgress,
                    downloadState.totalCount,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _offlineService.cancelBackgroundDownload();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: context.isDark
                      ? AppTheme.darkCard
                      : AppTheme.lightDivider,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF34C759),
                  ),
                ),
              ),
            ],
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: SettingsIconBadge(
        gradientColors: const [Color(0xFF34C759), Color(0xFF30D158)],
        icon: CupertinoIcons.cloud_download,
      ),
          title: Text(
            AppLocalizations.of(context)!.downloadAllLibrary,
            style: const TextStyle(fontSize: 16, color: Color(0xFF34C759)),
          ),
          onTap: _downloadAllLibrary,
        );
      },
    );
  }

  Future<void> _downloadAllLibrary() async {
    try {
      final libraryProvider = context.read<LibraryProvider>();
      final subsonicService = context.read<SubsonicService>();

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loading library...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      await libraryProvider.ensureLibraryLoaded();

      // If still empty, try to refresh from server with a small delay
      if (libraryProvider.cachedAllSongs.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        // Force refresh by calling refresh method
        await libraryProvider.refresh();
      }

      final allSongs = libraryProvider.cachedAllSongs;

      if (allSongs.isEmpty) {
        if (!mounted) return;
        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.noSongsAvailable),
            content: const Text(
              'Library appears to be empty or failed to load. Make sure your server supports full library scanning.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
        if (retry == true) {
          await _downloadAllLibrary();
          return;
        }
        return;
      }

      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.downloadAllLibrary),
          content: Text(
            AppLocalizations.of(
              context,
            )!.downloadLibraryConfirm(allSongs.length),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.download),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      await _offlineService.startBackgroundDownload(allSongs, subsonicService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.libraryDownloadStarted),
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadOfflineInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorStartingDownload(e),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDeleteDownloadsButton() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF3B30), Color(0xFFFF453A)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          CupertinoIcons.trash_fill,
          color: Colors.white,
          size: 16,
        ),
      ),
      title: Text(
        AppLocalizations.of(context)!.deleteDownloads,
        style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
      ),
      onTap: () async {
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.downloadsDeleted),
            ),
          );
        }
      },
    );
  }
}
