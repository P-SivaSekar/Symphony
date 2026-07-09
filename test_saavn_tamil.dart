import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';

void main() async {
  final baseUrl = 'https://www.jiosaavn.com/api.php';
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Referer': 'https://www.jiosaavn.com/',
    'Cookie': 'L=tamil; B=tamil;'
  };

  try {
    // Try passing language in cookie or in URL
    final url = Uri.parse('$baseUrl?__call=webapi.getLaunchData&api_version=4&_format=json&_marker=0&ctx=web6dot0');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['new_trending'] != null) {
        final trending = data['new_trending'] as List;
        print('Trending items: ${trending.length}');
        for (var item in trending) {
          print('Language: ${item['language']}, Type: ${item['type']}');
        }
      } else {
        print('new_trending is null');
      }
    } else {
      print('Failed with status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
