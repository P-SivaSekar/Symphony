import 'dart:io';

void main() {
  final file = File('lib/ui/playlist_screen.dart');
  String content = file.readAsStringSync();
  
  final oldLine = "color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),";
  final newLine = "color: Colors.transparent,";
  
  if (content.contains(oldLine)) {
    content = content.replaceFirst(oldLine, newLine);
    file.writeAsStringSync(content);
    print("Fixed PopupMenuButton color");
  } else {
    print("Could not find PopupMenuButton color");
  }
}
