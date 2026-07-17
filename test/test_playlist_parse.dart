import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

final HtmlUnescape _unescape = HtmlUnescape();

String _cleanString(String? text) {
  if (text == null) return '';
  return _unescape.convert(text).trim();
}

void main() async {
  final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=webapi.getLaunchData&api_version=4&_format=json&_marker=0&ctx=web6dot0');
  final headers = {
    'User-Agent': 'Mozilla/5.0',
    'Cookie': 'L=tamil; B=tamil;'
  };
  
  final res = await http.get(url, headers: headers);
  final data = jsonDecode(res.body);
  
  var pList = data['top_playlists'] as List;
  if (pList.isNotEmpty) {
    var p = pList[0];
    print('Trying playlist: ${p['title']} (id: ${p['id']})');
    
    final pUrl = Uri.parse('https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=${p['id']}&n=50&_format=json&_marker=0&ctx=web6dot0');
    final pRes = await http.get(pUrl, headers: headers);
    final pData = jsonDecode(pRes.body);
    if (pData['list'] != null) {
      List<dynamic> songs = [];
      for (var item in pData['list']) {
        if (item['language'] != null && item['language'].toString().toLowerCase() == 'tamil') {
          // parse song
          String artist = 'Unknown Artist';
          if (item['more_info'] != null && item['more_info']['artistMap'] != null) {
            // handle artist
          } else if (item['subtitle'] != null) {
             artist = item['subtitle'];
          }
          
          songs.add({
            'id': item['id'],
            'title': _cleanString(item['title'] ?? item['song']),
            'artist': _cleanString(artist),
          });
        }
      }
      print('Parsed songs: ${songs.length}');
      print('First song: ${songs.first}');
    } else {
      print('Failed. Response: $pData');
    }
  }
}
