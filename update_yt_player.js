const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');
code = code.replace('class YTMusicPlayer extends StatelessWidget {', 'final MiniplayerController miniplayerController = MiniplayerController();\n\nclass YTMusicPlayer extends StatelessWidget {');
code = code.replace('return Miniplayer(', 'return Miniplayer(\n      controller: miniplayerController,');
code = code.replace('PlayerScreen(onMinimize: () {', 'PlayerScreen(onMinimize: () {\n                miniplayerController.animateToHeight(state: PanelState.MIN);');
fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
