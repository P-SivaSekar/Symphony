const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

code = code.replace(
  '  void _handleVerticalUpdate(DragUpdateDetails details) {\n    FocusManager.instance.primaryFocus?.unfocus();\n    double fractionDragged = details.delta.dy / MediaQuery.of(context).size.height;\n    _controller.value -= fractionDragged;\n  }',
  '  double _lastDragDelta = 0;\n  void _handleVerticalUpdate(DragUpdateDetails details) {\n    FocusManager.instance.primaryFocus?.unfocus();\n    _lastDragDelta = details.delta.dy;\n    double fractionDragged = details.delta.dy / MediaQuery.of(context).size.height;\n    _controller.value -= fractionDragged;\n  }'
);

code = code.replace(
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
  }`,
  `  void _handleVerticalEnd(DragEndDetails details) {
    if (_controller.value > 0) {
      final dy = details.velocity.pixelsPerSecond.dy;
      if (dy > 300) {
        _controller.reverse();
      } else if (dy < -300) {
        _controller.forward();
      } else {
        if (_lastDragDelta > 0) {
          if (_controller.value <= 0.8) {
            _controller.reverse();
          } else {
            _controller.forward();
          }
        } else {
          if (_controller.value >= 0.2) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        }
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
  }`
);

code = code.replace(
  'final bottomNavHeight = (widget.hasBottomNav ? 56.0 : 0.0) + MediaQuery.of(context).padding.bottom;',
  'final bottomNavHeight = (widget.hasBottomNav ? 66.0 : 0.0) + MediaQuery.of(context).padding.bottom;'
);

code = code.replace(
  'final double miniTop = screenHeight - bottomNavHeight - miniHeight + 10.0;',
  'final double miniTop = screenHeight - bottomNavHeight - miniHeight;'
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
