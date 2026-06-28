import 'dart:io';

void main() {
  final dir = Directory('lib/ui');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int totalReplaced = 0;

  for (final file in files) {
    String content = file.readAsStringSync();
    if (!content.contains('ElevatedButton(') && !content.contains('ElevatedButton.icon(')) {
      continue;
    }

    bool modified = false;

    // A very rough regex to find ElevatedButton and wrap it in GlassContainer
    // Because regexing nested parenthesis in Dart is hard, we will do a simpler string replacement
    // actually, wait, replacing nested brackets with regex is error prone.
    // Let's do it manually using a stack parser.
    content = _replaceElevatedButtons(content, (match) {
      modified = true;
      totalReplaced++;
      return '''GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ''' + match.replaceAll(RegExp(r'style:\s*ElevatedButton\.styleFrom\([^)]*\),?'), 'style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),') + '''
      )''';
    });

    if (modified) {
      // make sure to import glassmorphic_component.dart if not present
      if (!content.contains('glassmorphic_component.dart')) {
         content = "import 'glassmorphic_component.dart';\n" + content;
      }
      file.writeAsStringSync(content);
      print('Updated \${file.path}');
    }
  }
  print('Total ElevatedButtons replaced: \$totalReplaced');
}

String _replaceElevatedButtons(String content, String Function(String) replacer) {
  int i = 0;
  while (true) {
    int idx = content.indexOf('ElevatedButton(', i);
    int idxIcon = content.indexOf('ElevatedButton.icon(', i);
    
    int startIdx = -1;
    if (idx != -1 && idxIcon != -1) {
      startIdx = idx < idxIcon ? idx : idxIcon;
    } else if (idx != -1) {
      startIdx = idx;
    } else if (idxIcon != -1) {
      startIdx = idxIcon;
    }

    if (startIdx == -1) break;

    // Find the end of this ElevatedButton(...) by balancing parentheses
    int parenCount = 0;
    int endIdx = -1;
    bool inString = false;
    String stringChar = '';

    for (int j = startIdx; j < content.length; j++) {
      String c = content[j];
      
      // Basic string handling (ignoring escapes for simplicity, assuming decent formatting)
      if ((c == "'" || c == '"') && content[j-1] != '\\') {
        if (!inString) {
          inString = true;
          stringChar = c;
        } else if (c == stringChar) {
          inString = false;
        }
      }

      if (!inString) {
        if (c == '(') parenCount++;
        if (c == ')') {
          parenCount--;
          if (parenCount == 0) {
            endIdx = j;
            break;
          }
        }
      }
    }

    if (endIdx != -1) {
      String match = content.substring(startIdx, endIdx + 1);
      
      // If it's already inside a GlassContainer, skip it.
      // We look back a few characters.
      int lookBack = startIdx > 30 ? startIdx - 30 : 0;
      String before = content.substring(lookBack, startIdx);
      if (before.contains('GlassContainer(') || before.contains('child: ') && before.contains('GlassContainer')) {
         i = endIdx + 1;
         continue;
      }

      String replacement = replacer(match);
      content = content.substring(0, startIdx) + replacement + content.substring(endIdx + 1);
      i = startIdx + replacement.length;
    } else {
      break;
    }
  }
  return content;
}
