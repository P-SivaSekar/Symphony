import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'package:html_unescape/html_unescape.dart';

class SaavnService {
  static const String baseUrl = 'https://www.jiosaavn.com/api.php';
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.jiosaavn.com/',
    'Cookie': 'L=tamil; B=tamil;'
  };
  static final HtmlUnescape _unescape = HtmlUnescape();

  static String _cleanString(String? text) {
    if (text == null) return '';
    return _unescape.convert(text).trim();
  }

  static String _getHighResCover(String? url) {
    if (url == null || url.isEmpty) return '';
    return url.replaceAll('50x50', '500x500').replaceAll('150x150', '500x500');
  }

  static List<Song> _filterUniqueSongs(List<Song> songs) {
    final uniqueSongs = <Song>[];
    final seenTitles = <String>{};
    for (var s in songs) {
      final baseTitle = s.title.split('(')[0].split('-')[0].split('[')[0].toLowerCase().trim();
      if (!seenTitles.contains(baseTitle)) {
        seenTitles.add(baseTitle);
        uniqueSongs.add(s);
      }
    }
    return uniqueSongs;
  }

  /// Fetches the Tamil launch data (trending, new albums, top playlists)
  static Future<Map<String, List<dynamic>>> fetchTamilHomeData() async {
    try {
      final url = Uri.parse('$baseUrl?__call=webapi.getLaunchData&api_version=4&_format=json&_marker=0&ctx=web6dot0');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<Song> trending = [];
        List<Playlist> playlists = [];

        // Parse New Trending (only Tamil)
        if (data['new_trending'] != null) {
          for (var item in data['new_trending']) {
            if (item['language'] != null && item['language'].toString().toLowerCase() == 'tamil') {
              if (item['type'] == 'song') {
                trending.add(_parseSongFromJson(item));
              }
            }
          }
        }
        
        // Parse Top Playlists (only Tamil)
        if (data['top_playlists'] != null) {
          for (var item in data['top_playlists']) {
            // Some playlists might not have explicit language, but we filter if present
            // Let's only add it if it's explicitly tamil or if its title implies Tamil
            bool isTamil = false;
            if (item['language'] != null && item['language'].toString().toLowerCase() == 'tamil') {
              isTamil = true;
            } else if (item['title'] != null && item['title'].toString().toLowerCase().contains('tamil')) {
              isTamil = true;
            }
            
            if (isTamil) {
              playlists.add(Playlist(
                id: item['id'] ?? '',
                name: _cleanString(item['title']),
                description: _cleanString(item['subtitle']),
                coverUrl: _getHighResCover(item['image']),
                songs: [],
              ));
            }
          }
        }

        playlists.add(Playlist(
          id: 'search:ilayaraja tamil hits',
          name: 'Ilayaraja Hits',
          description: 'Best of Maestro Ilayaraja',
          coverUrl: 'https://c.saavncdn.com/artists/Ilayaraja_005_20230825081033_500x500.jpg',
          songs: [],
        ));
        playlists.add(Playlist(
          id: 'search:harris jayaraj tamil hits',
          name: 'Harris Jayaraj Hits',
          description: 'Magical melodies of Harris',
          coverUrl: 'https://c.saavncdn.com/artists/Harris_Jayaraj_004_20230825081438_500x500.jpg',
          songs: [],
        ));
        playlists.add(Playlist(
          id: 'search:ar rahman tamil hits',
          name: 'A.R. Rahman Hits',
          description: 'Musical genius ARR',
          coverUrl: 'https://c.saavncdn.com/artists/A_R_Rahman_002_20230825080838_500x500.jpg',
          songs: [],
        ));
        playlists.add(Playlist(
          id: 'search:anirudh tamil hits',
          name: 'Anirudh Hits',
          description: 'Rockstar Anirudh Ravichander',
          coverUrl: 'https://c.saavncdn.com/artists/Anirudh_Ravichander_005_20230825081156_500x500.jpg',
          songs: [],
        ));        
        // Ensure we have enough trending songs by fetching top tamil songs (random page for freshness)
        if (trending.length < 15) {
          final randomPage = (DateTime.now().millisecondsSinceEpoch % 10) + 1; // Random page 1-10
          final topSongs = await searchTamilSongs('top tamil', page: randomPage);
          for (var s in topSongs) {
            if (!trending.any((t) => t.id == s.id)) {
              trending.add(s);
            }
          }
        }

        return {
          'trending': _filterUniqueSongs(trending),
          'playlists': playlists,
        };
      }
    } catch (e) {
      print('Error fetching Saavn home data: $e');
    }
    return {'trending': [], 'playlists': []};
  }

  static Future<List<Song>> searchTamilSongs(String query, {int page = 1}) async {
    try {
      final url = Uri.parse('$baseUrl?__call=search.getResults&q=${Uri.encodeComponent(query)}&n=50&p=$page&_format=json&_marker=0&ctx=web6dot0');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Song> results = [];
        if (data['results'] != null) {
          for (var item in data['results']) {
            if (item['language'] != null && item['language'].toString().toLowerCase() == 'tamil' && _isOfficialVersion(item)) {
              results.add(_parseSongFromJson(item));
            }
          }
        }
        return _filterUniqueSongs(results);
      }
    } catch (e) {
      print('Error searching Saavn: $e');
    }
    return [];
  }

  static Future<List<Song>> fetchPlaylistSongs(String playlistId) async {
    if (playlistId.startsWith('search:')) {
      final query = playlistId.substring(7);
      return await searchTamilSongs(query, page: 1);
    }
    try {
      final url = Uri.parse('$baseUrl?__call=playlist.getDetails&listid=$playlistId&n=50&_format=json&_marker=0&ctx=web6dot0');
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<Song> songs = [];
        final listData = data['list'] ?? data['songs'];
        if (listData != null) {
          for (var item in listData) {
            if (item['language'] != null && item['language'].toString().toLowerCase() == 'tamil') {
              songs.add(_parseSongFromJson(item));
            }
          }
        }
        return _filterUniqueSongs(songs);
      }
    } catch (e) {
      print('Error fetching playlist details: $e');
    }
    return [];
  }

  static Future<String?> getAudioUrl(String saavnId) async {
    try {
      final detailsUrl = '$baseUrl?__call=song.getDetails&pids=$saavnId&_format=json&_marker=0&api_version=4&ctx=web6dot0';
      final detailsResponse = await http.get(Uri.parse(detailsUrl), headers: headers);
      
      if (detailsResponse.statusCode == 200) {
        final detailsData = jsonDecode(detailsResponse.body);
        if (detailsData != null && detailsData['songs'] != null && (detailsData['songs'] as List).isNotEmpty) {
          final songObj = detailsData['songs'][0];
          final moreInfo = songObj['more_info'];
          if (moreInfo != null) {
            final encUrl = moreInfo['encrypted_media_url'] as String?;
            if (encUrl != null && encUrl.isNotEmpty) {
              final encodedUrl = Uri.encodeComponent(encUrl);
              final tokenUrl = '$baseUrl?__call=song.generateAuthToken&url=$encodedUrl&bitrate=320&api_version=4&_format=json&ctx=web6dot0&_marker=0';
              final tokenResponse = await http.get(Uri.parse(tokenUrl), headers: headers);
              if (tokenResponse.statusCode == 200) {
                final tokenData = jsonDecode(tokenResponse.body);
                if (tokenData != null && tokenData['status'] == 'success') {
                  return tokenData['auth_url'] as String?;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching Saavn audio URL: $e');
    }
    return null;
  }

  static bool _isOfficialVersion(Map<String, dynamic> item) {
    final title = (item['song'] ?? item['title'] ?? '').toString().toLowerCase();
    final album = (item['album'] ?? '').toString().toLowerCase();
    final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
    
    final blacklist = ['remix', 'cover', 'lofi', 'lo-fi', 'slowed', 'reverb', 'instrumental', 'mashup', '8d', 'bgm', 'bass boosted'];
    for (final term in blacklist) {
      if (title.contains(term) || subtitle.contains(term)) {
        return false;
      }
    }
    return true;
  }

  static Song _parseSongFromJson(Map<String, dynamic> json) {
    String artist = 'Unknown Artist';
    if (json['more_info'] != null && json['more_info']['artistMap'] != null) {
      final artistMap = json['more_info']['artistMap'];
      if (artistMap['primary_artists'] != null && (artistMap['primary_artists'] as List).isNotEmpty) {
        artist = artistMap['primary_artists'].map((a) => a['name']).join(', ');
      } else if (artistMap['featured_artists'] != null && (artistMap['featured_artists'] as List).isNotEmpty) {
        artist = artistMap['featured_artists'].map((a) => a['name']).join(', ');
      } else if (artistMap['singers'] != null && (artistMap['singers'] as List).isNotEmpty) {
        artist = artistMap['singers'].map((a) => a['name']).join(', ');
      }
    }
    
    // For search results, artists might be just a string
    if (artist == 'Unknown Artist' && json['more_info'] != null && json['more_info']['singers'] != null) {
      artist = json['more_info']['singers'].toString();
    }
    
    // Fallback if structure is flat
    if (artist == 'Unknown Artist' && json['subtitle'] != null) {
       artist = json['subtitle'];
    }

    String rawTitle = _cleanString(json['title'] ?? json['song']);
    String extractedMovie = '';
    
    final fromMatch = RegExp(r'\(\s*From\s+["' + "'" + r']([^"'"'"']+)' + r'["' + "'" + r']\s*\)|\(\s*From\s+([^)]+)\s*\)', caseSensitive: false).firstMatch(rawTitle);
    if (fromMatch != null) {
      extractedMovie = fromMatch.group(1) ?? fromMatch.group(2) ?? '';
      rawTitle = rawTitle.replaceAll(fromMatch.group(0)!, '').trim();
    }
    
    String displaySubtitle = artist;
    if (extractedMovie.isNotEmpty) {
      displaySubtitle = extractedMovie;
    } else if (json['more_info'] != null && json['more_info']['album'] != null && json['more_info']['album'].toString().isNotEmpty) {
      displaySubtitle = _cleanString(json['more_info']['album'].toString());
    } else if (json['album'] != null && json['album'].toString().isNotEmpty) {
      displaySubtitle = _cleanString(json['album'].toString());
    }

    return Song(
      id: json['id'] ?? '',
      title: rawTitle,
      artist: _cleanString(displaySubtitle),
      coverUrl: _getHighResCover(json['image']),
      audioUrl: '', // Will be fetched lazily on playback
      isTrending: false,
    );
  }
}
