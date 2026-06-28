import 'dart:io';

void main() {
  final content = File('lib/ui/profile_screen.dart').readAsStringSync();
  final stack = <Map<String, dynamic>>[];
  int lineNumber = 1;
  int col = 1;

  for (int i = 0; i < content.length; i++) {
    final char = content[i];
    if (char == '\n') {
      lineNumber++;
      col = 1;
    } else {
      col++;
    }

    if (char == '(' || char == '[' || char == '{') {
      stack.add({'char': char, 'line': lineNumber, 'col': col});
    } else if (char == ')' || char == ']' || char == '}') {
      if (stack.isEmpty) return;
      final top = stack.removeLast();
      final topChar = top['char'];
      if (topChar == '[' && top['line'] > 250) {
        print(
          'POPPED [ from line ' +
              top['line'].toString() +
              ' at line ' +
              lineNumber.toString() +
              ':' +
              col.toString(),
        );
      }
    }
  }
}
