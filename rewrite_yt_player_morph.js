const fs = require('fs');

const code = `import 'dart:ui';
import 'package:flutter/material.dart';
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

  Widget _buildFloatingCover(String url, double animationValue, double screenWidth, double screenHeight, double bottomNavHeight, double safeAreaTop) {
    // Miniplayer bounds
    final double miniSize = 44.0;
    final double miniLeft = 16.0;
    final double miniTop = screenHeight - bottomNavHeight - miniHeight + 10.0;
    final double miniRadius = 4.0;

    // Full screen bounds
    final double fullSize = screenWidth - 80.0;
    final double fullLeft = 40.0;
    final double fullTop = safeAreaTop + 76.0; // Approx top bar height
    final double fullRadius = 20.0;

    // Interpolate
    final double currentSize = lerpDouble(miniSize, fullSize, animationValue)!;
    final double currentLeft = lerpDouble(miniLeft, fullLeft, animationValue)!;
    final double currentTop = lerpDouble(miniTop, fullTop, animationValue)!;
    final double currentRadius = lerpDouble(miniRadius, fullRadius, animationValue)!;

    Widget image;
    if (url.isEmpty) {
      image = Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20));
    } else if (url.startsWith('asset:')) {
      image = Image.asset(url.replaceFirst('asset:', ''), fit: BoxFit.cover);
    } else {
      image = Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20)));
    }

    return Positioned(
      left: currentLeft,
      top: currentTop,
      width: currentSize,
      height: currentSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(currentRadius),
            boxShadow: animationValue > 0.5 ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.5 * animationValue),
                blurRadius: 30 * animationValue,
                spreadRadius: 10 * animationValue,
              )
            ] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(currentRadius),
            child: image,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    if (playerService.playlist.isEmpty || playerService.currentSong == null) {
      return const SizedBox.shrink();
    }
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final bottomNavHeight = (widget.hasBottomNav ? 56.0 : 0.0) + MediaQuery.of(context).padding.bottom;
    
    final miniScreen = _MiniPlayerContent(
      song: playerService.currentSong!,
      playerService: playerService,
      onTap: _toggle,
    );
    
    final fullScreen = PlayerScreen(
      onMinimize: _toggle,
      hideCover: true, // We draw the cover art manually over everything
    );

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_controller.value > 0) {
          _controller.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double fullScreenOffset = (1 - _controller.value) * screenHeight;
          final double miniPlayerBottom = (1 - _controller.value) * bottomNavHeight;
          
          return Stack(
            children: [
              // Full Screen Player
              if (_controller.value > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  top: fullScreenOffset,
                  height: screenHeight,
                  child: Opacity(
                    opacity: _controller.value,
                    child: fullScreen,
                  ),
                ),
              
              // Mini Player Base Layer
              if (_controller.value < 1.0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: miniPlayerBottom,
                  height: miniHeight,
                  child: GestureDetector(
                    onVerticalDragUpdate: _handleVerticalUpdate,
                    onVerticalDragEnd: _handleVerticalEnd,
                    onTap: _controller.value == 0.0 ? _toggle : null,
                    child: Material(
                      color: Colors.transparent,
                      child: Opacity(
                        opacity: 1.0 - _controller.value,
                        child: miniScreen,
                      ),
                    ),
                  ),
                ),

              // Floating Morphing Cover Art
              _buildFloatingCover(
                playerService.currentSong!.coverUrl, 
                _controller.value, 
                screenWidth, 
                screenHeight, 
                bottomNavHeight, 
                safeAreaTop
              ),
            ],
          );
        },
      ),
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
          // Empty space where cover art normally is (drawn by floating layer)
          const SizedBox(width: 44, height: 44),
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
