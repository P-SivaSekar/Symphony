import 'dart:io';

void main() {
  final files = ['lib/ui/playlist_screen.dart', 'lib/ui/home_screen.dart'];
  
  for (var path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    
    String content = file.readAsStringSync();
    
    // Replace trailing IconButton with GlassContainer wrapper
    final regex = RegExp(r"IconButton\(\s*icon: Icon\(\s*Icons\.more_vert,\s*color: textColor\.withOpacity\(\s*0\.5,\s*\),\s*\),\s*onPressed:");
    final newText = '''GlassContainer(
                                              borderRadius: 30,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: textColor.withOpacity(0.5),
                                                ),
                                                onPressed:''';
                                                
    if (regex.hasMatch(content)) {
      content = content.replaceAll(regex, newText);
      file.writeAsStringSync(content);
      print("Updated \$path");
    } else {
      print("Could not find match in \$path");
    }
  }
}
