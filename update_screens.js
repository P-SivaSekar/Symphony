const fs = require('fs');

function replaceInFile(file) {
  if (fs.existsSync(file)) {
    let code = fs.readFileSync(file, 'utf8');
    code = code.replace(/import 'sliding_player_panel\.dart';/g, "import 'yt_music_player.dart';");
    code = code.replace(/const SlidingPlayerPanel\(hasBottomNav: false\)/g, "const YTMusicPlayer()");
    code = code.replace(/const SlidingPlayerPanel\(\)/g, "const YTMusicPlayer()");
    fs.writeFileSync(file, code, 'utf8');
  }
}

replaceInFile('lib/ui/admin_dashboard_screen.dart');
replaceInFile('lib/ui/playlist_screen.dart');
