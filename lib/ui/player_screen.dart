import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/player_service.dart';
import '../providers/app_provider.dart';
import 'glassmorphic_component.dart';
import '../utils/song_options_bottom_sheet.dart';
import 'package:text_scroll/text_scroll.dart';
import 'synced_lyrics_view.dart';

class PlayerScreen extends StatefulWidget {
  final bool hideCover;
  const PlayerScreen({super.key, this.hideCover = false});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PageController _pageController;
  bool _isProgrammaticScroll = false;
  bool _showLyrics = false;
  double? _dragValue;
  
  @override
  void initState() {
    super.initState();
    final playerService = Provider.of<PlayerService>(context, listen: false);
    _pageController = PageController(
      initialPage: playerService.currentEffectiveIndex,
    );
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playerService = Provider.of<PlayerService>(context, listen: false);
    if (_pageController.hasClients &&
        _pageController.page?.round() != playerService.currentEffectiveIndex) {
      _isProgrammaticScroll = true;
      _pageController
          .animateToPage(
            playerService.currentEffectiveIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) {
        _isProgrammaticScroll = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:$seconds";
    }
    return "$minutes:$seconds";
  }



  void _showQueueBottomSheet(BuildContext context, PlayerService playerService, AppProvider appProvider) {
    if (playerService.autoplayEnabled && playerService.autoplayQueue.isEmpty) {
      playerService.populateAutoplayQueue(appProvider.allSongs);
    }
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GlassContainer(
              borderRadius: 20,
              hasBlur: true,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Up Next',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Autoplay',
                              style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                            ),
                            Switch(
                              value: playerService.autoplayEnabled,
                              activeColor: primaryColor,
                              onChanged: (val) {
                                playerService.toggleAutoplay();
                                setState(() {}); // update sheet UI
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Builder(builder: (context) {
                        final fullPlaylist = playerService.fullEffectivePlaylist;
                        final queueLength = fullPlaylist.length;
                        final autoQueue = playerService.autoplayQueue;
                        final autoplayLength = playerService.autoplayEnabled ? autoQueue.length : 0;
                        final hasAutoplay = autoplayLength > 0;
                        
                        // queue + (marker + autoplay) + padding
                        final totalItems = queueLength + (hasAutoplay ? autoplayLength + 1 : 0) + 1; 

                        final scrollController = ScrollController(
                          initialScrollOffset: playerService.currentEffectiveIndex * 72.0,
                        );

                        return ReorderableListView.builder(
                          scrollController: scrollController,
                          itemCount: totalItems,
                          onReorder: (oldIndex, newIndex) {
                            if (oldIndex < newIndex) {
                              newIndex -= 1;
                            }
                            if (oldIndex < queueLength) {
                              if (newIndex >= queueLength) newIndex = queueLength - 1;
                              playerService.reorderQueue(oldIndex, newIndex);
                              setState(() {});
                            }
                          },
                          itemBuilder: (context, index) {
                            if (index == totalItems - 1) {
                              // Bottom Padding to ensure the current item can be scrolled to the top, but leave bottom empty if it's the last item
                              final viewportHeight = MediaQuery.of(context).size.height * 0.7;
                              final itemsAfterCurrent = totalItems - 1 - playerService.currentEffectiveIndex;
                              final heightAfterCurrent = itemsAfterCurrent * 72.0;
                              final paddingHeight = (viewportHeight - heightAfterCurrent).clamp(0.0, viewportHeight);
                              
                              return SizedBox(
                                key: const ValueKey('padding'),
                                height: paddingHeight,
                              );
                            }

                            if (index < queueLength) {
                              // Normal queue song
                              final song = fullPlaylist[index];
                              final isPlaying = index == playerService.currentEffectiveIndex;

                              return Dismissible(
                                key: ValueKey('queue_${song.id}_$index'),
                                direction: DismissDirection.horizontal,
                                onDismissed: (direction) {
                                  playerService.removeFromQueue(index);
                                  setState(() {});
                                },
                                background: Container(
                                  color: Colors.redAccent,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(left: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.redAccent,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                child: SizedBox(
                                  height: 72,
                                  child: Center(
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: song.coverUrl.isEmpty
                                            ? Container(
                                                width: 50,
                                                height: 50,
                                                color: isDark ? Colors.white10 : Colors.black12,
                                                child: Icon(Icons.music_note, color: textColor.withValues(alpha: 0.5)),
                                              )
                                            : (song.coverUrl.startsWith('asset:')
                                                ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 50, height: 50, fit: BoxFit.cover)
                                                : Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                                      ),
                                      title: Text(
                                        song.title,
                                        style: TextStyle(
                                          color: isPlaying ? primaryColor : textColor,
                                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        song.artist,
                                        style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: isPlaying
                                          ? Icon(Icons.equalizer, color: primaryColor)
                                          : IconButton(
                                              icon: Icon(Icons.more_vert, color: textColor.withValues(alpha: 0.7)),
                                              onPressed: () => showSongOptionsBottomSheet(context, song, isQueueContext: true, queueIndex: index),
                                            ),
                                      onTap: () {
                                        final indices = playerService.audioPlayer.effectiveIndices;
                                        final originalIndex = (indices != null && indices.length > index) ? indices[index] : index;
                                        playerService.audioPlayer.seek(Duration.zero, index: originalIndex);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            } else if (index == queueLength) {
                              // Marker
                              return SizedBox(
                                key: const ValueKey('autoplay_header'),
                                height: 72,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('— End of Queue —', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
                                      Text('Autoplay Tracks', style: TextStyle(color: primaryColor.withValues(alpha: 0.8), fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // Autoplay song
                              final autoplayIndex = index - queueLength - 1;
                              final song = autoQueue[autoplayIndex];

                              return SizedBox(
                                key: ValueKey('autoplay_${song.id}_$index'),
                                height: 72,
                                child: Center(
                                  child: ListTile(
                                    leading: Opacity(
                                      opacity: 0.7,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: song.coverUrl.isEmpty
                                            ? Container(
                                                width: 50,
                                                height: 50,
                                                color: isDark ? Colors.white10 : Colors.black12,
                                                child: Icon(Icons.music_note, color: textColor.withValues(alpha: 0.5)),
                                              )
                                            : (song.coverUrl.startsWith('asset:')
                                                ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 50, height: 50, fit: BoxFit.cover)
                                                : Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                                      ),
                                    ),
                                    title: Text(
                                      song.title,
                                      style: TextStyle(
                                        color: textColor.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      style: TextStyle(color: textColor.withValues(alpha: 0.4)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(Icons.auto_awesome, color: primaryColor.withValues(alpha: 0.5)),
                                    onTap: () async {
                                      playerService.autoplayQueue.removeAt(autoplayIndex);
                                      await playerService.addToQueue(song);
                                      final newIndex = playerService.fullEffectivePlaylist.length - 1;
                                      playerService.audioPlayer.seek(Duration.zero, index: newIndex);
                                      playerService.populateAutoplayQueue(appProvider.allSongs);
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final fullPlaylist = playerService.fullEffectivePlaylist;

    // Ensure PageView animates to the correct page when the song changes externally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && !_isProgrammaticScroll) {
        final currentPage = _pageController.page?.round() ?? 0;
        if (currentPage != playerService.currentEffectiveIndex) {
          _isProgrammaticScroll = true;
          _pageController.animateToPage(
            playerService.currentEffectiveIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ).then((_) => _isProgrammaticScroll = false);
        }
      }
    });

    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final song = playerService.currentSong;
    if (song == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(title: Text('Now Playing', style: TextStyle(color: textColor))),
        body: Center(child: Text('No song playing', style: TextStyle(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: widget.hideCover
            ? const SizedBox()
            : Column(
                children: [
                  // Top App Bar Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.keyboard_arrow_down, color: textColor, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'NOW PLAYING',
                                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12, letterSpacing: 2),
                              ),
                              Text(
                                song.title,
                                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_vert, color: textColor),
                          onPressed: () => showSongOptionsBottomSheet(context, song, isFullScreenPlayer: true),
                        ),
                      ],
                    ),
                  ),
                  // Cover Art Pager or Synced Lyrics
                  Expanded(
                    child: _showLyrics
                        ? SyncedLyricsView(song: song)
                        : PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              if (_isProgrammaticScroll) return;
                              if (index != playerService.currentEffectiveIndex) {
                                final indices = playerService.audioPlayer.effectiveIndices;
                                final actualIndex = indices.isNotEmpty ? indices[index] : index;
                                playerService.audioPlayer.seek(
                                  Duration.zero,
                                  index: actualIndex,
                                );
                              }
                            },
                            itemCount: fullPlaylist.length,
                            itemBuilder: (context, index) {
                              final qSong = fullPlaylist[index];
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Hero(
                                        tag: 'cover_${qSong.id}',
                                        child: AnimatedArtworkCard(
                                          song: qSong,
                                          isPlaying: playerService.isPlaying,
                                          isDark: isDark,
                                          textColor: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                    child: Column(
                                      children: [
                                        TextScroll(
                                          qSong.title,
                                          mode: TextScrollMode.endless,
                                          intervalSpaces: 40,
                                          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                                          delayBefore: const Duration(seconds: 2),
                                          pauseBetween: const Duration(seconds: 2),
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          selectable: false,
                                        ),
                                        const SizedBox(height: 8),
                                        TextScroll(
                                          qSong.artist,
                                          mode: TextScrollMode.endless,
                                          intervalSpaces: 40,
                                          velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
                                          delayBefore: const Duration(seconds: 2),
                                          pauseBetween: const Duration(seconds: 2),
                                          style: TextStyle(
                                            color: textColor.withValues(alpha: 0.7),
                                            fontSize: 16,
                                          ),
                                          selectable: false,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        StreamBuilder<Duration>(
                          stream: playerService.audioPlayer.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? playerService.currentPosition;
                            final duration = playerService.totalDuration;
                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    activeTrackColor: primaryColor,
                                    inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                                    thumbColor: primaryColor,
                                    overlayColor: primaryColor.withValues(alpha: 0.2),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  ),
                                  child: Slider(
                                    value: _dragValue ?? position.inSeconds.toDouble().clamp(0.0, duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0),
                                    min: 0,
                                    max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                                    onChanged: (value) {
                                      setState(() {
                                        _dragValue = value;
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      playerService.seek(Duration(seconds: value.toInt()));
                                      _dragValue = null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(_dragValue != null ? Duration(seconds: _dragValue!.toInt()) : position),
                                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                  // Playback Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GlassContainer(
                          borderRadius: 30,
                          child: IconButton(
                            icon: Icon(
                              playerService.isShuffleModeEnabled ? Icons.shuffle : Icons.shuffle_outlined,
                              color: playerService.isShuffleModeEnabled ? primaryColor : textColor.withValues(alpha: 0.54),
                              size: 24,
                            ),
                            onPressed: () {
                              playerService.toggleShuffle(appProvider.allSongs);
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: textColor, size: 40),
                          onPressed: playerService.hasPrevious ? () => playerService.playPrevious() : null,
                        ),
                        MorphingPlayPauseButton(
                          isPlaying: playerService.isPlaying,
                          buttonColor: primaryColor,
                          iconColor: isDark ? Colors.black : Colors.white,
                          onPressed: () {
                            if (playerService.isPlaying) playerService.pause();
                            else playerService.play();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: textColor, size: 40),
                          onPressed: playerService.hasNext ? () => playerService.playNext() : null,
                        ),
                        GlassContainer(
                          borderRadius: 30,
                          child: IconButton(
                            icon: Icon(
                              playerService.loopMode.name == 'one' ? Icons.repeat_one : Icons.repeat,
                              color: playerService.loopMode.name != 'off' ? primaryColor : textColor.withValues(alpha: 0.54),
                              size: 24,
                            ),
                            onPressed: () => playerService.toggleRepeat(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom Row (Lyrics & Queue)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                            color: _showLyrics ? primaryColor : textColor.withOpacity(0.54),
                            size: 28,
                          ),
                          onPressed: () {
                            setState(() {
                              _showLyrics = !_showLyrics;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.queue_music,
                            color: textColor,
                            size: 28,
                          ),
                          onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

class AnimatedArtworkCard extends StatefulWidget {
  final dynamic song;
  final bool isPlaying;
  final bool isDark;
  final Color textColor;
  const AnimatedArtworkCard({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<AnimatedArtworkCard> createState() => _AnimatedArtworkCardState();
}

class _AnimatedArtworkCardState extends State<AnimatedArtworkCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _shadowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    if (widget.isPlaying) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedArtworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final shadowProgress = _shadowAnimation.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20 + (0.25 * shadowProgress)),
                  blurRadius: 12.0 + (16.0 * shadowProgress),
                  offset: Offset(0, 6.0 + (9.0 * shadowProgress)),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: widget.song.coverUrl.isEmpty
            ? Container(
                color: widget.isDark ? Colors.white10 : Colors.black12,
                child: Center(
                  child: Icon(Icons.music_note, size: 100, color: widget.textColor.withOpacity(0.54)),
                ),
              )
            : (widget.song.coverUrl.startsWith('asset:')
                ? Image.asset(widget.song.coverUrl.replaceFirst('asset:', ''), fit: BoxFit.cover)
                : Image.network(widget.song.coverUrl, fit: BoxFit.cover)),
      ),
    );
  }
}

class MorphingPlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;
  final Color buttonColor;
  final Color iconColor;
  const MorphingPlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    required this.buttonColor,
    required this.iconColor,
  });

  @override
  State<MorphingPlayPauseButton> createState() => _MorphingPlayPauseButtonState();
}

class _MorphingPlayPauseButtonState extends State<MorphingPlayPauseButton> with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.decelerate),
    );
    if (widget.isPlaying) {
      _iconController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant MorphingPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.buttonColor,
            boxShadow: [
              BoxShadow(
                color: widget.buttonColor.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _iconController,
              color: widget.iconColor,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}