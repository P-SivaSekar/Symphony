const fs = require('fs');

let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

const regex = /    return AnimatedBuilder\([\s\S]*?    \);\n  \}/;

const replacement = `    final miniScreen = _MiniPlayerContent(
      song: playerService.currentSong!,
      playerService: playerService,
      onTap: _toggle,
    );
    
    final fullScreen = PlayerScreen(onMinimize: _toggle);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double currentHeight = miniHeight + (_controller.value * (screenHeight - miniHeight));
        final double currentBottomOffset = (1 - _controller.value) * bottomNavHeight;
        
        return Positioned(
          left: 0,
          right: 0,
          bottom: currentBottomOffset,
          height: currentHeight,
          child: GestureDetector(
            onVerticalDragUpdate: _handleVerticalUpdate,
            onVerticalDragEnd: _handleVerticalEnd,
            onTap: _controller.value == 0.0 ? _toggle : null,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Full Screen Player
                  if (_controller.value > 0)
                    Opacity(
                      opacity: _controller.value,
                      child: fullScreen,
                    ),
                  
                  // Mini Player
                  if (_controller.value < 1.0)
                    Opacity(
                      opacity: 1.0 - _controller.value,
                      child: miniScreen,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }`;

code = code.replace(regex, replacement);
fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
