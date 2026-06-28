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
      if (stack.isEmpty) {
        print('Extra ' + char + ' at ' + lineNumber.toString() + ':' + col.toString());
        return;
      }
      final top = stack.removeLast();
      final topChar = top['char'];
      if ((char == ')' && topChar != '(') ||
          (char == ']' && topChar != '[') ||
          (char == '}' && topChar != '{')) {
        print('Mismatch! Expected to close ' + topChar + ' from ' + top['line'].toString() + ':' + top['col'].toString() + ', but got ' + char + ' at ' + lineNumber.toString() + ':' + col.toString());
        return;
      }
    }
  }

  if (stack.isNotEmpty) {
    print('Unclosed: ' + stack.map((e) => e['char'] + ' at ' + e['line'].toString() + ':' + e['col'].toString()).join(', '));
  } else {
    print('All brackets match perfectly!');
  }
}
