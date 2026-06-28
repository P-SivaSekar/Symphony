import 'dart:io';
import 'dart:convert';

void main() {
  final logFile = File(r'C:\Users\psiva\.gemini\antigravity\brain\8edb297c-47eb-4d17-8a72-1e7dda5dee70\.system_generated\logs\transcript.jsonl');
  final lines = logFile.readAsLinesSync();
  
  for (int i = 0; i < lines.length; i++) {
    try {
      final Map<String, dynamic> step = jsonDecode(lines[i]);
      if (step['type'] == 'TOOL_RESPONSE' && step['tool_calls'] != null) {
        final calls = step['tool_calls'] as List;
        for (var call in calls) {
          if (call['name'] == 'default_api:run_command') {
            final String output = call['response']['output'] ?? '';
            if (output.contains('class PlayerScreen extends StatefulWidget') && output.contains('import')) {
               print("Found run_command response at line " + i.toString());
               File('extracted_player_screen.txt').writeAsStringSync(output);
               return;
            }
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }
  print("Could not find full player_screen.dart in transcript.");
}
