const fs = require('fs');
let code = fs.readFileSync('lib/main.dart', 'utf8');

code = code.replace("import 'ui/sliding_player_panel.dart';", "import 'ui/yt_music_player.dart';");
code = code.replace("const SlidingPlayerPanel()", "const YTMusicPlayer()");

fs.writeFileSync('lib/main.dart', code, 'utf8');
