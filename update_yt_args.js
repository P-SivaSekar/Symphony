const fs = require('fs');

let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');
code = code.replace(/const YTMusicPlayer\(\{super\.key\}\);/, 'const YTMusicPlayer({super.key, this.hasBottomNav = false});\n  final bool hasBottomNav;');
code = code.replace(/final bottomNavHeight = 56\.0 \+ MediaQuery\.of\(context\)\.padding\.bottom;/, 'final bottomNavHeight = (widget.hasBottomNav ? 56.0 : 0.0) + MediaQuery.of(context).padding.bottom;');
fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');

code = fs.readFileSync('lib/main.dart', 'utf8');
code = code.replace(/const YTMusicPlayer\(\)/g, 'const YTMusicPlayer(hasBottomNav: true)');
fs.writeFileSync('lib/main.dart', code, 'utf8');

