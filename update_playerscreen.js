const fs = require('fs');

let playerScreen = fs.readFileSync('lib/ui/player_screen.dart', 'utf8');

playerScreen = playerScreen.replace('final VoidCallback? onMinimize;', 'final VoidCallback? onMinimize;\n  final bool hideCover;');
playerScreen = playerScreen.replace('const PlayerScreen({super.key, this.onMinimize});', 'const PlayerScreen({super.key, this.onMinimize, this.hideCover = false});');

playerScreen = playerScreen.replace(/child: qSong\.coverUrl\.isEmpty/g, 'child: widget.hideCover ? const SizedBox.expand() : qSong.coverUrl.isEmpty');

fs.writeFileSync('lib/ui/player_screen.dart', playerScreen, 'utf8');

console.log('Done player_screen');
