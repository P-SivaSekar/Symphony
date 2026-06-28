const fs = require('fs');
const content = fs.readFileSync('lib/ui/sliding_player_panel.dart', 'utf8');

// The file is currently broken because the fuzzy matcher deleted everything from `: null,` to `// Lever UI`.
// I need to use the original file content to restore the entire `Mini Player Row` block.

const target = /                  \/\/ Mini Player Row[\s\S]*?                  \/\/ Lever UI/m;

const replacement = `                  // Mini Player Row
                  if (collapseProgress < 1.0)
                    Opacity(
                      opacity: 1.0 - collapseProgress,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openPlayerScreen,
                        onHorizontalDragEnd: (details) {
                          if (details.primaryVelocity! > 0) {
                            playerService.playPrevious();
                          } else if (details.primaryVelocity! < 0) {
                            playerService.playNext();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: OverflowBox(
                            minHeight: 62,
                            maxHeight: 62,
                            alignment: Alignment.topCenter,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: song.coverUrl.isEmpty
                                      ? Container(
                                          color: Colors.white10,
                                          alignment: Alignment.center,
                                          width: 44,
                                          height: 44,
                                          child: Icon(
                                            Icons.music_note,
                                            color: Colors.white24,
                                          ),
                                        )
                                      : song.coverUrl.startsWith('asset:')
                                      ? Image.asset(
                                          song.coverUrl.replaceFirst('asset:', ''),
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          song.coverUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.white10,
                                            alignment: Alignment.center,
                                            width: 44,
                                            height: 44,
                                            child: Icon(
                                              Icons.music_note,
                                              color: Colors.white24,
                                            ),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      kIsWeb
                                          ? SizedBox(
                                              height: 18,
                                              child: Marquee(
                                                text: song.title,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                scrollAxis: Axis.horizontal,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                blankSpace: 30.0,
                                                velocity: 30.0,
                                                pauseAfterRound: const Duration(seconds: 2),
                                              ),
                                            )
                                          : Text(
                                              song.title,
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      Text(
                                        song.artist,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_previous,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      onPressed: playerService.hasPrevious
                                          ? () => playerService.playPrevious()
                                          : null,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        playerService.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      onPressed: () {
                                        if (playerService.isPlaying) {
                                          playerService.pause();
                                        } else {
                                          playerService.play();
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.skip_next,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                      onPressed: playerService.hasNext
                                          ? () => playerService.playNext()
                                          : null,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Lever UI`;

if (target.test(content)) {
    fs.writeFileSync('lib/ui/sliding_player_panel.dart', content.replace(target, replacement), 'utf8');
    console.log('SUCCESS');
} else {
    console.log('TARGET NOT FOUND');
}
