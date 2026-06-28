const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

// Replace the drag update method
code = code.replace(
  '  void _handleVerticalUpdate(DragUpdateDetails details) {',
  '  void _handleVerticalUpdate(DragUpdateDetails details) {\n    FocusManager.instance.primaryFocus?.unfocus();\n    double fractionDragged = details.delta.dy / MediaQuery.of(context).size.height;\n    _controller.value -= fractionDragged;\n  }\n  void _old_handleVerticalUpdate(DragUpdateDetails details) {'
);

// Replace the drag end method
code = code.replace(
  '  void _handleVerticalEnd(DragEndDetails details) {',
  `  void _handleVerticalEnd(DragEndDetails details) {
    if (_controller.value > 0) {
      if (_controller.value >= 0.2 || (details.velocity.pixelsPerSecond.dy < -300)) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    } else {
      final dx = details.velocity.pixelsPerSecond.dx;
      final playerService = Provider.of<PlayerService>(context, listen: false);
      if (dx > 300 && playerService.hasPrevious) {
        playerService.playPrevious();
      } else if (dx < -300 && playerService.hasNext) {
        playerService.playNext();
      } else if (details.velocity.pixelsPerSecond.dy < -300) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }
  void _old_handleVerticalEnd(DragEndDetails details) {`
);

// Replace the GestureDetector in yt_music_player build method
code = code.replace(
  '                    child: GestureDetector(\n                      onVerticalDragUpdate: _handleVerticalUpdate,\n                      onVerticalDragEnd: _handleVerticalEnd,\n                      onHorizontalDragEnd: (details) {\n                        if (_controller.value > 0) return;\n                        if (details.primaryVelocity != null) {\n                          if (details.primaryVelocity! > 300 && playerService.hasPrevious) {\n                            playerService.playPrevious();\n                          } else if (details.primaryVelocity! < -300 && playerService.hasNext) {\n                            playerService.playNext();\n                          }\n                        }\n                      },',
  '                    child: GestureDetector(\n                      onPanUpdate: _handleVerticalUpdate,\n                      onPanEnd: _handleVerticalEnd,'
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
