import 'dart:io';
import 'dart:convert';

void main() {
  final brainDir = Directory(r'C:\Users\psiva\.gemini\antigravity\brain');
  final dirs = brainDir.listSync().whereType<Directory>().toList();
  
  // Sort by modified time descending to get the most recent valid file
  dirs.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  
  for (var dir in dirs) {
    if (dir.path.endsWith('tempmediaStorage')) continue;
    final logFile = File('\${dir.path}\\.system_generated\\logs\\transcript.jsonl');
    if (!logFile.existsSync()) continue;
    
    print("Checking \${dir.path}...");
    final lines = logFile.readAsLinesSync();
    
    // Look from end to start for a TOOL_RESPONSE view_file of player_screen.dart or anything that has full player_screen.dart
    for (int i = lines.length - 1; i >= 0; i--) {
      try {
        final Map<String, dynamic> step = jsonDecode(lines[i]);
        if (step['type'] == 'TOOL_RESPONSE' && step['tool_calls'] != null) {
          final calls = step['tool_calls'] as List;
          for (var call in calls) {
            final String output = call['response']?['output'] ?? '';
            // We need a fairly large file content
            if (output.contains('class PlayerScreen extends StatefulWidget') && 
                output.contains('class _PlayerScreenState extends State<PlayerScreen>') &&
                output.contains('Widget build(BuildContext context)') &&
                output.contains('// Bottom Row')) {
               print("FOUND full player_screen.dart in \${dir.path} at line \$i!");
               File('extracted_player_screen.txt').writeAsStringSync(output);
               return;
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }
  print("Could not find full player_screen.dart in any transcript.");
}
