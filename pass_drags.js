const fs = require('fs');

let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

code = code.replace(
  /    final fullScreen = PlayerScreen\(\n      onMinimize: _toggle,\n      hideCover: true, \/\/ We draw the cover art manually over everything\n    \);/,
  `    final fullScreen = PlayerScreen(
      onMinimize: _toggle,
      hideCover: true,
      onDragUpdate: _handleVerticalUpdate,
      onDragEnd: _handleVerticalEnd,
    );`
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
