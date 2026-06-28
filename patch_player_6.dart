import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  content = content.replaceAll(
    'contentPadding: const EdgeInsets.symmetric(horizontal: 24)',
    'contentPadding: const EdgeInsets.only(left: 24, right: 8)'
  );

  file.writeAsStringSync(content);
  print('Patched padding properly!');
}
