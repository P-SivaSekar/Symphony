import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import 'player_screen.dart';
import 'glassmorphic_component.dart';
import 'package:text_scroll/text_scroll.dart';

class YTMusicPlayer extends StatelessWidget {
  final GlobalKey? bottomMenuKey;
  final bool hasBottomNav;
  const YTMusicPlayer({super.key, this.hasBottomNav = false, this.bottomMenuKey});

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    if (playerService.playlist.isEmpty || playerService.currentSong == null) {
      return const SizedBox.shrink();
    }
    
    final bottomNavHeight = (hasBottomNav ? kBottomNavigationBarHeight : 0.0) + MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomNavHeight,
      height: 64.0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlayerScreen(hideCover: false),
            ),
          );
        },
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! > 300 && playerService.hasPrevious) {
              playerService.playPrevious();
            } else if (details.primaryVelocity! < -300 && playerService.hasNext) {
              playerService.playNext();
            }
          }
        },
        child: Material(
          color: Colors.transparent,
          child: _MiniPlayerContent(
            song: playerService.currentSong!,
            playerService: playerService,
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final dynamic song;
  final PlayerService playerService;
  
  const _MiniPlayerContent({
    required this.song,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (song.coverUrl.isEmpty) {
      image = Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20));
    } else if (song.coverUrl.startsWith('asset:')) {
      image = Image.asset(song.coverUrl.replaceFirst('asset:', ''), fit: BoxFit.cover);
    } else {
      image = Image.network(song.coverUrl, fit: BoxFit.cover, cacheWidth: 800, errorBuilder: (_,__,___) => Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20)));
    }

    return GlassContainer(
      height: 64.0,
      width: double.infinity,
      borderRadius: 0,
      border: Border(
        top: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 0.5,
        )
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: SizedBox(
              width: 44,
              height: 44,
              child: image,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextScroll(
                  song.title,
                  mode: TextScrollMode.endless,
                                          intervalSpaces: 40,
                  velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                  delayBefore: const Duration(seconds: 2),
                  pauseBetween: const Duration(seconds: 2),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  selectable: false,
                ),
                const SizedBox(height: 2),
                TextScroll(
                  song.artist,
                  mode: TextScrollMode.endless,
                                          intervalSpaces: 40,
                  velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                  delayBefore: const Duration(seconds: 2),
                  pauseBetween: const Duration(seconds: 2),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  selectable: false,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.skip_previous,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: playerService.hasPrevious ? () => playerService.playPrevious() : null,
          ),
          IconButton(
            icon: Icon(
              playerService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              if (playerService.isPlaying) playerService.pause();
              else playerService.play();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.skip_next,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: playerService.hasNext ? () => playerService.playNext() : null,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
