const fs = require('fs');

const code = `import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import 'player_screen.dart';
import 'package:marquee/marquee.dart';

final ValueNotifier<double> playerExpandProgress = ValueNotifier(0.0);
final ValueNotifier<bool> isPlayerExpanded = ValueNotifier(false);

class YTMusicPlayer extends StatefulWidget {
  final bool hasBottomNav;
  const YTMusicPlayer({super.key, this.hasBottomNav = false});

  @override
  State<YTMusicPlayer> createState() => _YTMusicPlayerState();
}

class _YTMusicPlayerState extends State<YTMusicPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final double miniHeight = 64.0;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _controller.addListener(() {
      playerExpandProgress.value = _controller.value;
      if (_controller.value > 0.9 && !isPlayerExpanded.value) isPlayerExpanded.value = true;
      if (_controller.value < 0.1 && isPlayerExpanded.value) isPlayerExpanded.value = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _handleVerticalUpdate(DragUpdateDetails details) {
    double fractionDragged = details.primaryDelta! / MediaQuery.of(context).size.height;
    _controller.value -= fractionDragged;
  }

  void _handleVerticalEnd(DragEndDetails details) {
    if (_controller.value >= 0.5 || details.primaryVelocity! < -500) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    if (playerService.playlist.isEmpty || playerService.currentSong == null) {
      return const SizedBox.shrink();
    }
    
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = (widget.hasBottomNav ? 56.0 : 0.0) + MediaQuery.of(context).padding.bottom;
    
    return AnimatedBuilder(
      animation: _controller,
      child: _MiniPlayerContent(
        song: playerService.currentSong!,
        playerService: playerService,
        onTap: _toggle,
      ),
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
                      child: PlayerScreen(onMinimize: _toggle),
                    ),
                  
                  // Mini Player
                  if (_controller.value < 1.0)
                    Opacity(
                      opacity: 1.0 - _controller.value,
                      child: child,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final dynamic song;
  final PlayerService playerService;
  final VoidCallback onTap;
  
  const _MiniPlayerContent({
    required this.song,
    required this.playerService,
    required this.onTap,
  });

  Widget _buildCover(String url) {
    if (url.isEmpty) return Container(width: 44, height: 44, color: Colors.black12, child: const Icon(Icons.music_note, size: 20));
    if (url.startsWith('asset:')) return Image.asset(url.replaceFirst('asset:', ''), width: 44, height: 44, fit: BoxFit.cover);
    return Image.network(url, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 44, height: 44, color: Colors.black12, child: const Icon(Icons.music_note, size: 20)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 0.5,
          )
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildCover(song.coverUrl),
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
                            fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                const SizedBox(height: 2),
                song.artist.length > 30
                    ? SizedBox(
                        height: 14,
                        child: Marquee(
                          text: song.artist,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          scrollAxis: Axis.horizontal,
                          blankSpace: 40.0,
                          velocity: 30.0,
                        ),
                      )
                    : Text(
                        song.artist,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
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
`;

fs.writeFileSync('lib/ui/yt_music_player.dart', code, 'utf8');
