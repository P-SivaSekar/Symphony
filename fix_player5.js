const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

code = code.replace(
  'final bottomNavHeight = (widget.hasBottomNav ? 75.0 : 0.0) + MediaQuery.of(context).padding.bottom;',
  'final bottomNavHeight = (widget.hasBottomNav ? kBottomNavigationBarHeight + 10.0 : 0.0) + MediaQuery.of(context).padding.bottom;'
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
