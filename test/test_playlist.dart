import 'dart:convert';
import 'package:http/http.dart' as http;

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
    
    // Testing with n=50
    final pUrl = Uri.parse('https://www.jiosaavn.com/api.php?__call=playlist.getDetails&listid=${p['id']}&n=50&_format=json&_marker=0&ctx=web6dot0');
    final pRes = await http.get(pUrl, headers: headers);
    final pData = jsonDecode(pRes.body);
    if (pData['list'] != null) {
      print('Songs found: ${pData['list'].length}');
    } else {
      print('Failed with n=50. Response: $pData');
    }
  }
}
