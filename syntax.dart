import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  final lines = file.readAsLinesSync();
  
  List<Map<String, dynamic>> stack = [];
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    for (int j = 0; j < line.length; j++) {
      final char = line[j];
      if (char == '{' || char == '(' || char == '[') {
        stack.add({'char': char, 'line': i + 1, 'col': j + 1});
      } else if (char == '}' || char == ')' || char == ']') {
        if (stack.isEmpty) {
          print("ERROR: Unmatched closing " + char + " at line " + (i + 1).toString() + ":" + (j + 1).toString());
          return;
        }
        final last = stack.removeLast();
        final expected = last['char'] == '{' ? '}' : last['char'] == '(' ? ')' : ']';
        if (char != expected) {
          print("ERROR: Mismatched closing " + char + " at line " + (i + 1).toString() + ":" + (j + 1).toString() + ". Expected " + expected + " to close " + last['char'].toString() + " from line " + last['line'].toString());
          return;
        }
      }
    }
  }
  
  if (stack.isNotEmpty) {
    print("ERROR: Unclosed brackets remaining:");
    for (var b in stack) {
      print("  " + b['char'].toString() + " at line " + b['line'].toString() + ":" + b['col'].toString());
    }
  } else {
    print("All brackets match!");
  }
}
