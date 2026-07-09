import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = '424668629472834';
  final apiSecret = 'Ln3kEROFIDnMSimvM4n27EgavfI';
  final cloudName = 'dx02qjcqn';

  final auth = base64Encode(utf8.encode('\$apiKey:\$apiSecret'));
  final url = Uri.parse('https://api.cloudinary.com/v1_1/\$cloudName/resources/video?max_results=500');

  final request = await HttpClient().getUrl(url);
  request.headers.add('Authorization', 'Basic \$auth');
  
  final response = await request.close();
  final resBody = await response.transform(utf8.decoder).join();
  
  print(resBody);
}
