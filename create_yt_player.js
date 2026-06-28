const fs = require('fs');
let code = `import 'package:flutter/material.dart';
import 'package:miniplayer/miniplayer.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import 'player_screen.dart';
import 'glassmorphic_component.dart';
import 'package:marquee/marquee.dart';

class YTMusicPlayer extends StatelessWidget {
  const YTMusicPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    if (playerService.playlist.isEmpty || playerService.currentSong == null) {
      return const SizedBox.shrink();
    }
    
    final miniHeight = 64.0 + MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height;
    
    return Miniplayer(
      minHeight: miniHeight,
      maxHeight: maxHeight,
      builder: (height, percentage) {
        final song = playerService.currentSong!;
        
        // Full Screen Threshold
        if (percentage > 0.1) {
          return Opacity(
            opacity: percentage,
            child: PlayerScreen(onMinimize: () {
               // We would need a MiniplayerController to animate to min.
               // Let's pass a controller later if needed, or PlayerScreen handles its own collapse.
            }),
          );
        }
        
        // Mini Player
        return GlassContainer(
          borderRadius: 0,
          border: const Border(),
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
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
                          child: const Icon(Icons.music_note, color: Colors.white24),
                        )
                      : song.coverUrl.startsWith('asset:')
                      ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 44, height: 44, fit: BoxFit.cover)
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
                            child: const Icon(Icons.music_note, color: Colors.white24),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      song.title.length > 20
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
                                blankSpace: 40.0,
                                velocity: 30.0,
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
                      song.artist.length > 30
                          ? SizedBox(
                              height: 14,
                              child: Marquee(
                                text: song.artist,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                                scrollAxis: Axis.horizontal,
                                blankSpace: 40.0,
                                velocity: 30.0,
                              ),
                            )
                          : Text(
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
                      icon: Icon(Icons.skip_previous, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      onPressed: playerService.hasPrevious ? () => playerService.playPrevious() : null,
                    ),
                    IconButton(
                      icon: Icon(playerService.isPlaying ? Icons.pause : Icons.play_arrow, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () {
                        if (playerService.isPlaying) playerService.pause();
                        else playerService.play();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      onPressed: playerService.hasNext ? () => playerService.playNext() : null,
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
`;
fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
