const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

// We need to export a ValueNotifier that tracks the expansion percentage
const replacement = `final MiniplayerController miniplayerController = MiniplayerController();
final ValueNotifier<double> playerExpandProgress = ValueNotifier(0.0);

class YTMusicPlayer extends StatelessWidget {`;

code = code.replace(`final MiniplayerController miniplayerController = MiniplayerController();

class YTMusicPlayer extends StatelessWidget {`, replacement);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
