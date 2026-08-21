
enum SyncCategory { artists, albums, songs, cleanup, complete }

class SyncProgress {
  final int artistsCurrent;
  final int? artistsTotal;
  final int albumsCurrent;
  final int? albumsTotal;
  final int songsCurrent;
  final int? songsTotal;
  final SyncCategory currentCategory;
  final String statusMessage;

  SyncProgress({
    this.artistsCurrent = 0,
    this.artistsTotal,
    this.albumsCurrent = 0,
    this.albumsTotal,
    this.songsCurrent = 0,
    this.songsTotal,
    this.currentCategory = SyncCategory.artists,
    this.statusMessage = '',
  });

  double get overallProgress {
    if (currentCategory == SyncCategory.complete) return 1.0;
    
    // Weighted progress calculation
    // Artists: 10%, Albums: 20%, Songs: 70%
    double progress = 0.0;
    
    if (artistsTotal != null && artistsTotal! > 0) {
      progress += (artistsCurrent / artistsTotal!) * 0.1;
    }
    
    if (albumsTotal != null && albumsTotal! > 0) {
      progress += (albumsCurrent / albumsTotal!) * 0.2;
    }
    
    if (songsTotal != null && songsTotal! > 0) {
      progress += (songsCurrent / songsTotal!) * 0.7;
    }
    
    return progress.clamp(0.0, 1.0);
  }

  SyncProgress copyWith({
    int? artistsCurrent,
    int? artistsTotal,
    int? albumsCurrent,
    int? albumsTotal,
    int? songsCurrent,
    int? songsTotal,
    SyncCategory? currentCategory,
    String? statusMessage,
  }) {
    return SyncProgress(
      artistsCurrent: artistsCurrent ?? this.artistsCurrent,
      artistsTotal: artistsTotal ?? this.artistsTotal,
      albumsCurrent: albumsCurrent ?? this.albumsCurrent,
      albumsTotal: albumsTotal ?? this.albumsTotal,
      songsCurrent: songsCurrent ?? this.songsCurrent,
      songsTotal: songsTotal ?? this.songsTotal,
      currentCategory: currentCategory ?? this.currentCategory,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}
