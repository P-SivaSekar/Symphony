import os

files = [
    r"d:\Studies\Projects\Music Player\lib\ui\admin_dashboard_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\admin_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\all_playlists_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\auth_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\change_password_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\notification_screen.dart",
    r"d:\Studies\Projects\Music Player\lib\ui\otp_screen.dart"
]

target1 = """                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF0F3460),"""

target2 = """                        Color(0xFF0F0C29),
                        Color(0xFF302B63),
                        Color(0xFF24243E),"""

replacement = """                        Colors.black,
                        Colors.black,
                        Colors.black,"""

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    
    new_content = content.replace(target1, replacement).replace(target2, replacement)
    
    with open(f, 'w', encoding='utf-8') as file:
        file.write(new_content)

print("Replacement done.")
