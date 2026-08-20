import 'song.dart';
import 'album.dart';
import 'artist.dart';

class SearchResult {
  final List<Song> songs;
  final List<Album> albums;
  final List<Artist> artists;

  SearchResult({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      songs: (json['songs'] as List<dynamic>?)
          ?.map((e) => Song.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      albums: (json['albums'] as List<dynamic>?)
          ?.map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      artists: (json['artists'] as List<dynamic>?)
          ?.map((e) => Artist.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs': songs.map((e) => e.toJson()).toList(),
      'albums': albums.map((e) => e.toJson()).toList(),
      'artists': artists.map((e) => e.toJson()).toList(),
    };
  }

  bool get isEmpty => songs.isEmpty && albums.isEmpty && artists.isEmpty;

  // Permet d'utiliser searchResult['songs'], searchResult['albums'], searchResult['artists']
  List<dynamic> operator [](String key) {
    switch (key) {
      case 'songs':
        return songs;
      case 'albums':
        return albums;
      case 'artists':
        return artists;
      default:
        throw ArgumentError('Invalid key for SearchResult: $key');
    }
  }
}