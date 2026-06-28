const fs = require('fs');
let code = fs.readFileSync('lib/ui/player_screen.dart', 'utf8');

code = code.replace(
  'final VoidCallback? onMinimize;\n  final bool hideCover;\n  const PlayerScreen({super.key, this.onMinimize, this.hideCover = false});',
  'final VoidCallback? onMinimize;\n  final bool hideCover;\n  final Function(DragUpdateDetails)? onDragUpdate;\n  final Function(DragEndDetails)? onDragEnd;\n  const PlayerScreen({super.key, this.onMinimize, this.hideCover = false, this.onDragUpdate, this.onDragEnd});'
);

code = code.replace(
  /    return GestureDetector\(\n      onVerticalDragEnd: \(details\) \{[\s\S]*?      \},\n      child: Scaffold\(/,
  `    return GestureDetector(
      onVerticalDragUpdate: widget.onDragUpdate,
      onVerticalDragEnd: (details) {
        if (widget.onDragEnd != null) {
          widget.onDragEnd!(details);
        } else if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
          if (widget.onMinimize != null) {
            widget.onMinimize!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(`
);

fs.writeFileSync('lib/ui/player_screen.dart', code, 'utf8');
