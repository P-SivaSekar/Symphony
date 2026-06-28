const fs = require('fs');
let code = fs.readFileSync('lib/ui/player_screen.dart', 'utf8');

code = code.replace(
  '      onVerticalDragUpdate: widget.onDragUpdate,',
  '      onPanUpdate: widget.onDragUpdate,'
);

code = code.replace(
  '      onVerticalDragEnd: (details) {',
  '      onPanEnd: (details) {'
);

code = code.replace(
  '        } else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {',
  '        } else if (details.velocity.pixelsPerSecond.dy > 300) {'
);

fs.writeFileSync('lib/ui/player_screen.dart', code, 'utf8');
