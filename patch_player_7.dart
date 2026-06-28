import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    'contentPadding: const EdgeInsets.only(left: 24, right: 8)',
    'contentPadding: const EdgeInsets.only(left: 24, right: 0)'
  );

  file.writeAsStringSync(content);
  print('Patched padding properly!');
}
