import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('found_log.json');
  final String content = file.readAsStringSync();
  final Map<String, dynamic> step = jsonDecode(content);
  
  if (step['type'] == 'TOOL_RESPONSE') {
    // maybe view_file output?
    final String output = step['tool_calls'][0]['response']['output'] ?? '';
    // if the output has the file content, it might start with "Created At: ..."
    // Let's print the first 200 chars.
    print("TOOL_RESPONSE output starts with: " + output.substring(0, output.length < 200 ? output.length : 200));
    // Let's write the whole output to a text file
    File('extracted_content.txt').writeAsStringSync(output);
  } else if (step['type'] == 'TOOL_CALL') {
    // maybe it's write_to_file or replace_file_content
    final toolCall = step['tool_calls'][0];
    if (toolCall['name'] == 'default_api:replace_file_content') {
      print("It is a replace_file_content! We can't get the full file from this.");
    } else {
      print("Tool name: " + toolCall['name']);
    }
  } else {
    print("Step type: " + step['type']);
  }
}
