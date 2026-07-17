import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  final headers = {
    'User-Agent': 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:49.0) Gecko/20100101 Firefox/49.0',
    'Accept': 'application/json, text/plain, */*',
    'Referer': 'https://www.jiosaavn.com/',
  };
  
  try {
    print("Searching...");
    final searchUrl = Uri.parse('https://www.jiosaavn.com/api.php?__call=search.getResults&q=anirudh&n=5&p=1&_format=json&_marker=0&ctx=web6dot0');
    final searchRes = await http.get(searchUrl, headers: headers);
    final searchData = jsonDecode(searchRes.body);
    
    final songId = searchData['results'][0]['id'];
    print("Found song ID: $songId");
    
    print("\nTest 1: reco.getreco");
    final url = Uri.parse('https://www.jiosaavn.com/api.php?__call=reco.getreco&pid=$songId&api_version=4&_format=json&_marker=0&ctx=web6dot0');
    final response = await http.get(url, headers: headers);
    print("reco.getreco: " + response.body.substring(0, response.body.length > 200 ? 200 : response.body.length));

    print("\nTest 2: webradio.createEntityStation");
    final url2 = Uri.parse('https://www.jiosaavn.com/api.php?__call=webradio.createEntityStation&entity_id=$songId&entity_type=queue&api_version=4&_format=json&_marker=0&ctx=web6dot0');
    final response2 = await http.get(url2, headers: headers);
    print("webradio queue: " + response2.body.substring(0, response2.body.length > 200 ? 200 : response2.body.length));

    final url3 = Uri.parse('https://www.jiosaavn.com/api.php?__call=webradio.createEntityStation&entity_id=$songId&entity_type=song&api_version=4&_format=json&_marker=0&ctx=web6dot0');
    final response3 = await http.get(url3, headers: headers);
    print("webradio song: " + response3.body.substring(0, response3.body.length > 200 ? 200 : response3.body.length));

  } catch (e) {
    print('Error: $e');
  }
}
