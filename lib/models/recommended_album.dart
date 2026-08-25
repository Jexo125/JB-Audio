import 'album.dart';

class RecommendedAlbum {
  final Album album;
  final double score;
  final String? reason;

  const RecommendedAlbum({
    required this.album,
    required this.score,
    this.reason,
  });
}
