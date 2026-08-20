import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class SubsonicService {
  ServerConfig? _config;
  bool _isConfigured = false;

  bool get isConfigured => _isConfigured;
  ServerConfig? get config => _config;

  bool get isJellyfin => _config?.serverFamily == 'jellyfin';
  bool get isEmby => _config?.serverFamily == 'emby';
  bool get isNavidrome => _config?.serverType == 'navidrome';

  Future<void> configure(ServerConfig config) async {
    _config = config;
    _isConfigured = true;
  }

  Future<PingResult> pingWithError() async {
    if (_config == null) {
      return PingResult(
        success: false,
        error: 'Server configuration is missing',
      );
    }

    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/ping.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          final subsonicResponse = data['subsonic-response'];

          if (subsonicResponse != null && subsonicResponse['status'] == 'ok') {
            return PingResult(
              success: true,
              serverType: subsonicResponse['serverVersion'] != null ? 'subsonic' : null,
              serverVersion: subsonicResponse['version']?.toString(),
            );
          } else {
            final errorMsg = subsonicResponse?['error']?['message'] ?? 'Unknown Subsonic error';
            return PingResult(
              success: false,
              error: errorMsg,
            );
          }
        } catch (e) {
          return PingResult(
            success: false,
            error: 'Invalid JSON response from server',
          );
        }
      } else {
        return PingResult(
          success: false,
          error: 'HTTP Error: ${response.statusCode}',
        );
      }
    } on TimeoutException {
      return PingResult(
        success: false,
        error: 'Connection timed out',
      );
    } catch (e) {
      return PingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  String getCoverArtUrl(String? coverArtId, {int? size}) {
    if (_config == null || coverArtId == null || coverArtId.isEmpty) return '';
    final sizeParam = size != null ? '&size=$size' : '';
    return '${_config!.serverUrl}/rest/getCoverArt.view?u=${_config!.username}&p=${_config!.password ?? ''}&v=1.16.1&c=Musly&f=json&id=$coverArtId$sizeParam';
  }

  Future<List<Album>> getAlbumList({required String type, int size = 20, int offset = 0, String? genre}) async {
    if (_config == null) return [];
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
        'type': type,
        'size': size.toString(),
        'offset': offset.toString(),
      };
      if (genre != null) params['genre'] = genre;

      final url = Uri.parse('${_config!.serverUrl}/rest/getAlbumList2.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albumList = data['subsonic-response']?['albumList2']?['album'];
        if (albumList is List) {
          return albumList.map((json) => Album.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting album list: $e');
    }
    return [];
  }

  Future<List<Song>> getAllSongs({int size = 500, int offset = 0}) async {
    return getRandomSongs(size: size);
  }

  Future<List<Song>> getRandomSongs({int size = 50, String? genre}) async {
    if (_config == null) return [];
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
        'size': size.toString(),
      };
      if (genre != null) params['genre'] = genre;

      final url = Uri.parse('${_config!.serverUrl}/rest/getRandomSongs.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songsList = data['subsonic-response']?['randomSongs']?['song'];
        if (songsList is List) {
          return songsList.map((json) => Song.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting random songs: $e');
    }
    return [];
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getAlbum.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': albumId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songsList = data['subsonic-response']?['album']?['song'];
        if (songsList is List) {
          return songsList.map((json) => Song.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting album songs: $e');
    }
    return [];
  }

  Future<Album?> getAlbum(String albumId) async {
    if (_config == null) return null;
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getAlbum.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': albumId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albumJson = data['subsonic-response']?['album'];
        if (albumJson != null) {
          return Album.fromJson(albumJson);
        }
      }
    } catch (e) {
      debugPrint('Error getting album: $e');
    }
    return null;
  }

  Future<List<Artist>> getArtists() async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getArtists.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final indexes = data['subsonic-response']?['artists']?['index'];
        List<Artist> artists = [];
        if (indexes is List) {
          for (var index in indexes) {
            final artistList = index['artist'];
            if (artistList is List) {
              for (var art in artistList) {
                artists.add(Artist.fromJson(art));
              }
            }
          }
        }
        return artists;
      }
    } catch (e) {
      debugPrint('Error getting artists: $e');
    }
    return [];
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getArtist.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': artistId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final albumList = data['subsonic-response']?['artist']?['album'];
        if (albumList is List) {
          return albumList.map((json) => Album.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting artist albums: $e');
    }
    return [];
  }

  Future<Artist?> getArtist(String artistId) async {
    if (_config == null) return null;
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getArtist.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': artistId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final artistJson = data['subsonic-response']?['artist'];
        if (artistJson != null) {
          return Artist.fromJson(artistJson);
        }
      }
    } catch (e) {
      debugPrint('Error getting artist: $e');
    }
    return null;
  }

  Future<ArtistInfo?> getArtistInfo(String artistId) async {
    if (_config == null) return null;
    try {
      final url =
          Uri.parse('${_config!.serverUrl}/rest/getArtistInfo2.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': artistId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final infoJson = data['subsonic-response']?['artistInfo2'];
        if (infoJson != null) {
          return ArtistInfo.fromJson(infoJson);
        }
      }
    } catch (e) {
      debugPrint('Error getting artist info: $e');
    }
    return null;
  }

  Future<List<Playlist>> getPlaylists() async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getPlaylists.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlistList = data['subsonic-response']?['playlists']?['playlist'];
        if (playlistList is List) {
          return playlistList.map((json) => Playlist.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting playlists: $e');
    }
    return [];
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    if (_config == null) throw Exception('Not configured');
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getPlaylist.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': playlistId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final playlistJson = data['subsonic-response']?['playlist'];
        if (playlistJson != null) {
          return Playlist.fromJson(playlistJson);
        }
      }
    } catch (e) {
      debugPrint('Error getting playlist: $e');
    }
    throw Exception('Failed to load playlist');
  }

  Future<bool> createPlaylist({required String name, List<String>? songIds}) async {
    if (_config == null) return false;
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
        'name': name,
      };
      if (songIds != null) {
        for (int i = 0; i < songIds.length; i++) {
          params['songId[$i]'] = songIds[i];
        }
      }

      final url = Uri.parse('${_config!.serverUrl}/rest/createPlaylist.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error creating playlist: $e');
      return false;
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    if (_config == null) return false;
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/deletePlaylist.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': playlistId,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
      return false;
    }
  }

  Future<bool> updatePlaylist({
    required String playlistId,
    List<String>? songIdsToAdd,
    List<int>? songIndexesToRemove,
  }) async {
    if (_config == null) return false;
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
        'playlistId': playlistId,
      };
      if (songIdsToAdd != null) {
        for (int i = 0; i < songIdsToAdd.length; i++) {
          params['songIdToAdd[$i]'] = songIdsToAdd[i];
        }
      }
      if (songIndexesToRemove != null) {
        for (int i = 0; i < songIndexesToRemove.length; i++) {
          params['songIndexToRemove[$i]'] = songIndexesToRemove[i].toString();
        }
      }

      final url = Uri.parse('${_config!.serverUrl}/rest/updatePlaylist.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      return false;
    }
  }

  Future<List<Genre>> getGenres() async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getGenres.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final genresList = data['subsonic-response']?['genres']?['genre'];
        if (genresList is List) {
          return genresList.map((g) => Genre.fromJson(g is Map<String, dynamic> ? g : {'value': g.toString()})).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting genres: $e');
    }
    return [];
  }

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    if (_config == null) return SearchResult(songs: [], albums: [], artists: []);
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/search3.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'query': query,
          'artistCount': artistCount.toString(),
          'albumCount': albumCount.toString(),
          'songCount': songCount.toString(),
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchResult = data['subsonic-response']?['searchResult3'];
        if (searchResult != null) {
          return SearchResult(
            songs: (searchResult['song'] as List?)?.map((s) => Song.fromJson(s)).toList() ?? [],
            albums: (searchResult['album'] as List?)?.map((a) => Album.fromJson(a)).toList() ?? [],
            artists: (searchResult['artist'] as List?)?.map((ar) => Artist.fromJson(ar)).toList() ?? [],
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }
    return SearchResult(songs: [], albums: [], artists: []);
  }

  Future<SearchResult> getStarred() async {
    if (_config == null) return SearchResult(songs: [], albums: [], artists: []);
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getStarred2.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final starred = data['subsonic-response']?['starred2'];
        if (starred != null) {
          return SearchResult(
            songs: (starred['song'] as List?)?.map((s) => Song.fromJson(s)).toList() ?? [],
            albums: (starred['album'] as List?)?.map((a) => Album.fromJson(a)).toList() ?? [],
            artists: (starred['artist'] as List?)?.map((ar) => Artist.fromJson(ar)).toList() ?? [],
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting starred: $e');
    }
    return SearchResult(songs: [], albums: [], artists: []);
  }

  Future<bool> star({String? id, String? albumId, String? artistId}) async {
    if (_config == null) return false;
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
      };
      if (id != null) params['id'] = id;
      if (albumId != null) params['albumId'] = albumId;
      if (artistId != null) params['artistId'] = artistId;

      final url = Uri.parse('${_config!.serverUrl}/rest/star.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error starring: $e');
      return false;
    }
  }

  Future<bool> unstar({String? id, String? albumId, String? artistId}) async {
    if (_config == null) return false;
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
      };
      if (id != null) params['id'] = id;
      if (albumId != null) params['albumId'] = albumId;
      if (artistId != null) params['artistId'] = artistId;

      final url = Uri.parse('${_config!.serverUrl}/rest/unstar.view').replace(queryParameters: params);
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error unstarring: $e');
      return false;
    }
  }

  Future<List<Song>> getSongsByGenre(String genre, {int count = 50}) async {
    return getRandomSongs(size: count, genre: genre);
  }

  Future<List<Album>> getAlbumsByGenre(String genre, {int count = 20}) async {
    return getAlbumList(type: 'byGenre', size: count, genre: genre);
  }

  Future<Map<String, dynamic>> jukeboxGet() async {
    return _jukeboxCommand('get');
  }

  Future<Map<String, dynamic>> jukeboxStart() async {
    return _jukeboxCommand('start');
  }

  Future<Map<String, dynamic>> jukeboxStop() async {
    return _jukeboxCommand('stop');
  }

  Future<Map<String, dynamic>> jukeboxSkip(int index) async {
    return _jukeboxCommand('skip', params: {'index': index.toString()});
  }

  Future<Map<String, dynamic>> jukeboxAdd(String id) async {
    return _jukeboxCommand('add', params: {'id': id});
  }

  Future<Map<String, dynamic>> jukeboxClear() async {
    return _jukeboxCommand('clear');
  }

  Future<Map<String, dynamic>> jukeboxShuffle() async {
    return _jukeboxCommand('shuffle');
  }

  Future<Map<String, dynamic>> jukeboxRemove(int index) async {
    return _jukeboxCommand('remove', params: {'index': index.toString()});
  }

  Future<Map<String, dynamic>> jukeboxSet(List<String> ids) async {
    final params = <String, String>{};
    for (int i = 0; i < ids.length; i++) {
      params['id[$i]'] = ids[i];
    }
    return _jukeboxCommand('set', params: params);
  }

  Future<Map<String, dynamic>> jukeboxSetGain(double gain) async {
    return _jukeboxCommand('setGain', params: {'gain': gain.toString()});
  }

  Future<Map<String, dynamic>> _jukeboxCommand(String action,
      {Map<String, String>? params}) async {
    if (_config == null) throw Exception('Not configured');
    try {
      final queryParams = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
        'action': action,
      };
      if (params != null) queryParams.addAll(params);

      final url = Uri.parse('${_config!.serverUrl}/rest/jukeboxControl.view')
          .replace(queryParameters: queryParams);
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['subsonic-response']?['status'];
        if (status == 'ok') {
          return data['subsonic-response']?['jukeboxPlaylist'] ?? {};
        } else {
          final error = data['subsonic-response']?['error']?['message'] ??
              'Unknown jukebox error';
          throw Exception(error);
        }
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('Jukebox error ($action): $e');
      rethrow;
    }
  }

  Future<List<Song>> getSimilarSongs(String id, {int count = 20}) async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getSimilarSongs2.view')
          .replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': id,
          'count': count.toString(),
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songs = data['subsonic-response']?['similarSongs2']?['song'];
        if (songs is List) {
          return songs.map((s) => Song.fromJson(s)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting similar songs: $e');
    }
    return [];
  }

  Future<List<Song>> getArtistTopSongs(String artistId, {int count = 20}) async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getTopSongs.view')
          .replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'artist': artistId, 
          'count': count.toString(),
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songs = data['subsonic-response']?['topSongs']?['song'];
        if (songs is List) {
          return songs.map((s) => Song.fromJson(s)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting top songs: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> getLyricsBySongId(String id) async {
    if (_config == null) return null;
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getLyrics.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': id,
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['subsonic-response']?['lyrics'];
      }
    } catch (e) {
      debugPrint('Error getting lyrics by id: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getLyrics({String? artist, String? title}) async {
    if (_config == null) return null;
    try {
      final params = {
        'u': _config!.username,
        'p': _config!.password ?? '',
        'v': '1.16.1',
        'c': 'Musly',
        'f': 'json',
      };
      if (artist != null) params['artist'] = artist;
      if (title != null) params['title'] = title;

      final url = Uri.parse('${_config!.serverUrl}/rest/getLyrics.view').replace(
        queryParameters: params,
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['subsonic-response']?['lyrics'];
      }
    } catch (e) {
      debugPrint('Error getting lyrics: $e');
    }
    return null;
  }

  Future<List<RadioStation>> getInternetRadioStations() async {
    if (_config == null) return [];
    try {
      final url =
          Uri.parse('${_config!.serverUrl}/rest/getInternetRadioStations.view')
              .replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stations =
            data['subsonic-response']?['internetRadioStations']?['internetRadioStation'];
        if (stations is List) {
          return stations.map((s) => RadioStation.fromJson(s)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting radio stations: $e');
    }
    return [];
  }

  String getDownloadUrl(String id) {
    if (_config == null) return '';
    return '${_config!.serverUrl}/rest/download.view?u=${_config!.username}&p=${_config!.password ?? ''}&v=1.16.1&c=Musly&f=json&id=$id';
  }

  String getStreamUrl(String id, {int? maxBitRate}) {
    if (_config == null) throw Exception('Not configured');
    final bitrateParam = maxBitRate != null ? '&maxBitRate=$maxBitRate' : '';
    return '${_config!.serverUrl}/rest/stream.view?u=${_config!.username}&p=${_config!.password ?? ''}&v=1.16.1&c=Musly&f=json&id=$id$bitrateParam';
  }

  Future<String> resolveStreamUrlAsync(Song song) async {
    return getDownloadUrl(song.id);
  }

  Future<bool> setRating(String id, int rating) async {
    if (_config == null) return false;
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/setRating.view').replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
          'id': id,
          'rating': rating.toString(),
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error setting rating: $e');
      return false;
    }
  }

  Future<List<MusicFolder>> getMusicFolders() async {
    if (_config == null) return [];
    try {
      final url = Uri.parse('${_config!.serverUrl}/rest/getMusicFolders.view')
          .replace(
        queryParameters: {
          'u': _config!.username,
          'p': _config!.password ?? '',
          'v': '1.16.1',
          'c': 'Musly',
          'f': 'json',
        },
      );
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final folderList =
            data['subsonic-response']?['musicFolders']?['musicFolder'];
        if (folderList is List) {
          return folderList.map((json) => MusicFolder.fromJson(json)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting music folders: $e');
    }
    return [];
  }
}