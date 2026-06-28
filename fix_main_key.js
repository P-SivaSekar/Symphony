const fs = require('fs');
let code = fs.readFileSync('lib/main.dart', 'utf8');

if (!code.includes('final GlobalKey bottomMenuKey')) {
  code = code.replace(
    'class _MainScreenState extends State<MainScreen> {',
    'class _MainScreenState extends State<MainScreen> {\n  final GlobalKey bottomMenuKey = GlobalKey();'
  );
  
  code = code.replace(
    'bottomNavigationBar: GlassContainer(',
    'bottomNavigationBar: GlassContainer(\n              key: bottomMenuKey,'
  );
  
  code = code.replace(
    'const YTMusicPlayer(hasBottomNav: true)',
    'YTMusicPlayer(hasBottomNav: true, bottomMenuKey: bottomMenuKey)'
  );
  
  fs.writeFileSync('lib/main.dart', code, 'utf8');
}
