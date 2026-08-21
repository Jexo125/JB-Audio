import 'song.dart';

class BulkSyncResult {
  final List<Song> songs;
  final int? totalSongs;
  final int? totalAlbums;
  final int? totalArtists;

  BulkSyncResult({
    required this.songs,
    this.totalSongs,
    this.totalAlbums,
    this.totalArtists,
  });
}
