import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Please provide a file path');
    return;
  }

  final file = File(args[0]);
  final content = file.readAsStringSync();

  final stack = <Map<String, dynamic>>[];
  int lineNumber = 1;

  for (int i = 0; i < content.length; i++) {
    final char = content[i];
    if (char == '\n') {
      lineNumber++;
    } else if (char == '(' || char == '[' || char == '{') {
      stack.add({'char': char, 'line': lineNumber});
    } else if (char == ')' || char == ']' || char == '}') {
      if (stack.isEmpty) {
        print(
          'Error: Unexpected ' + char + ' at line ' + lineNumber.toString(),
        );
        return;
      }
      final top = stack.removeLast();
      final topChar = top['char'];
      final topLine = top['line'];

      final matches = {'(': ')', '[': ']', '{': '}'};
      if (matches[topChar] != char) {
        print(
          'Error: Mismatched brackets at line ' +
              lineNumber.toString() +
              '. Expected ' +
              matches[topChar]! +
              ' but got ' +
              char +
              '. Unclosed bracket from line ' +
              topLine.toString(),
        );
        return;
      }
    }
  }

  if (stack.isNotEmpty) {
    print('Error: Unclosed brackets remaining: ' + stack.toString());
  } else {
    print('All brackets match perfectly!');
  }
}
