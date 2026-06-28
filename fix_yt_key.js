const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

if (!code.includes('final GlobalKey? bottomMenuKey')) {
  code = code.replace(
    'class YTMusicPlayer extends StatefulWidget {',
    'class YTMusicPlayer extends StatefulWidget {\n  final GlobalKey? bottomMenuKey;'
  );
  
  code = code.replace(
    'final bool hasBottomNav;',
    'final bool hasBottomNav;'
  ); // just keeping structure
  
  code = code.replace(
    'const YTMusicPlayer({Key? key, this.hasBottomNav = false}) : super(key: key);',
    'const YTMusicPlayer({Key? key, this.hasBottomNav = false, this.bottomMenuKey}) : super(key: key);'
  );
  
  code = code.replace(
    'void initState() {',
    'void initState() {\n    super.initState();\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      if (mounted) setState(() {});\n    });'
  );
  code = code.replace('super.initState();\n    super.initState();', 'super.initState();'); // fix double super
}

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
