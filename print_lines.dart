import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  final lines = file.readAsLinesSync();
  for (int i = 360; i < 420; i++) {
    print((i + 1).toString() + ": " + lines[i]);
  }
}
