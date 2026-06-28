import 'dart:io';

void main() {
  final files = [
    'd:/Studies/Projects/Music Player/lib/ui/yt_music_player.dart',
    'd:/Studies/Projects/Music Player/lib/ui/player_screen.dart'
  ];

  for (final path in files) {
    final file = File(path);
    String content = file.readAsStringSync();
    
    // Use regex to replace TextScrollMode.endless, with TextScrollMode.endless, intervalSpaces: 40,
    content = content.replaceAll(
      'mode: TextScrollMode.endless,', 
      'mode: TextScrollMode.endless,\n                                          intervalSpaces: 40,'
    );
    
    file.writeAsStringSync(content);
  }

  print("Updated intervalSpaces");
}
