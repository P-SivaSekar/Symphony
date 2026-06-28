import 'dart:io';

void main() {
  final file = File('lib/ui/playlist_screen.dart');
  String content = file.readAsStringSync();
  
  final oldDecoration = '''                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black12,
                            borderRadius: BorderRadius.circular(20),
                          ),''';
  final newDecoration = '''                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),''';
  
  if (content.contains(oldDecoration)) {
    content = content.replaceFirst(oldDecoration, newDecoration);
    file.writeAsStringSync(content);
    print("Fixed Sort wrapper shadow");
  } else {
    print("Could not find Sort wrapper");
  }
}
