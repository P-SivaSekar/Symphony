import 'dart:io';

void main() async {
  final files = [
    r"d:\Studies\Projects\Music Player\lib\ui\admin_dashboard_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\admin_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\all_playlists_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\auth_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\change_password_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\notification_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\otp_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\intro_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\profile_setup_screen.dart"
  ];

  final target1 = '''                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF0F3460),''';

  final target2 = '''                        Color(0xFF0F0C29),
                        Color(0xFF302B63),
                        Color(0xFF24243E),''';

  final target3 = '''                        Color(0xFF141E30),
                        Color(0xFF243B55),''';

  final target4 = '''                        Color(0xFF0F2027),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),''';

  final replacement = '''                        Colors.black,
                        Colors.black,
                        Colors.black,''';
  
  final replacement2 = '''                        Colors.black,
                        Colors.black,''';

  for (final f in files) {
    final file = File(f);
    if (await file.exists()) {
      var content = await file.readAsString();
      content = content.replaceAll(target1, replacement);
      content = content.replaceAll(target2, replacement);
      content = content.replaceAll(target3, replacement2);
      content = content.replaceAll(target4, replacement);
      await file.writeAsString(content);
      print('Updated \$f');
    }
  }
  print('Done');
}
