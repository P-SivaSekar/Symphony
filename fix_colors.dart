import 'dart:io';

void main() {
  final dir = Directory('d:/Studies/Projects/Music Player/lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    // Replace specific ternary backgroundColor assignments
    content = content.replaceAll(RegExp(r'backgroundColor:\s*(?:theme\.brightness\s*==\s*Brightness\.dark|isDark)\s*\?\s*const\s*Color\(0xFF24243E\)\s*:\s*(?:Colors\.white|Theme\.of\(context\)\.colorScheme\.onSurface),?'), 'backgroundColor: Theme.of(context).colorScheme.surface,');

    // Replace specific always-dark backgroundColor assignments
    content = content.replaceAll(RegExp(r'backgroundColor:\s*const\s*Color\(0xFF24243E\),?'), 'backgroundColor: Theme.of(context).colorScheme.surface,');

    // Make sure we didn't mess up LinearGradients. We only targeted `backgroundColor:`.

    if (content != original) {
      print('Fixed \${file.path}');
      file.writeAsStringSync(content);
    }
  }
}
