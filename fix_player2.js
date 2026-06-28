const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

code = code.replace(
  'final bottomNavHeight = (widget.hasBottomNav ? 66.0 : 0.0) + MediaQuery.of(context).padding.bottom;',
  'final bottomNavHeight = (widget.hasBottomNav ? 90.0 : 0.0) + MediaQuery.of(context).padding.bottom;'
);

code = code.replace(
  'final double miniTop = screenHeight - bottomNavHeight - miniHeight;',
  'final double miniTop = screenHeight - bottomNavHeight - miniHeight + 10.0;'
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
