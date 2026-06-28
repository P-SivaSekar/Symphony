import 'dart:io';

void main() {
  final file = File('lib/utils/song_options_bottom_sheet.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains("import '../ui/glassmorphic_component.dart';")) {
    content = content.replaceFirst("import 'ui_utils.dart';", "import 'ui_utils.dart';\nimport '../ui/glassmorphic_component.dart';");
  }

  final regex = RegExp(r"backgroundColor: isDark\s*\?\s*const Color\(0xFF1E1E2C\)\s*:\s*theme\.colorScheme\.surface,");
  final newBg = "backgroundColor: Colors.transparent,";
  
  final wrapperNew = '''          return GlassContainer(
            borderRadius: 20,
            hasBlur: true,
            child: SafeArea(''';
            
  if (content.contains(regex)) {
    content = content.replaceFirst(regex, newBg);
    content = content.replaceFirst("          return SafeArea(", wrapperNew);
    content = content.replaceFirst('''            ),
          );
        },''', '''            ),
            ),
          );
        },''');
        
    file.writeAsStringSync(content);
    print("Fixed bottom sheet");
  } else {
    print("Could not find bottom sheet background color");
  }
}
