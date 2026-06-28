const fs = require('fs');
let code = fs.readFileSync('lib/ui/yt_music_player.dart', 'utf8');

// Replace the play/pause button row in _MiniPlayerContent to include the previous button
code = code.replace(
  /          IconButton\(\n            icon: Icon\(\n              playerService\.isPlaying \? Icons\.pause : Icons\.play_arrow,\n              color: Theme\.of\(context\)\.colorScheme\.onSurface,\n            \),\n            onPressed: \(\) \{\n              if \(playerService\.isPlaying\) playerService\.pause\(\);\n              else playerService\.play\(\);\n            \},\n          \),/,
  `          IconButton(
            icon: Icon(
              Icons.skip_previous,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: playerService.hasPrevious ? () => playerService.playPrevious() : null,
          ),
          IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              if (playerService.isPlaying) playerService.pause();
              else playerService.play();
            },
          ),`
);

// Add horizontal swiping gesture to the entire MiniPlayer Base Layer
// Wait, the Mini Player Base Layer is in _YTMusicPlayerState build. It has GestureDetector for onVerticalDragUpdate.
// We can just add onHorizontalDragEnd to it!
code = code.replace(
  '                    onVerticalDragEnd: _handleVerticalEnd,\n                    onTap: _controller.value == 0.0 ? _toggle : null,',
  `                    onVerticalDragEnd: _handleVerticalEnd,
                    onHorizontalDragEnd: (details) {
                      if (_controller.value > 0) return;
                      if (details.primaryVelocity != null) {
                        if (details.primaryVelocity! > 300 && playerService.hasPrevious) {
                          playerService.playPrevious();
                        } else if (details.primaryVelocity! < -300 && playerService.hasNext) {
                          playerService.playNext();
                        }
                      }
                    },
                    onTap: _controller.value == 0.0 ? _toggle : null,`
);

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
