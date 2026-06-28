import 'dart:io';

void main() {
  final file = File('lib/ui/playlist_screen.dart');
  final lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    print('\${i + 1}: \${lines[i]}');
  }
}
