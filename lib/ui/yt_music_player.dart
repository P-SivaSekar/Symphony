import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../providers/app_provider.dart';
import '../models/song_model.dart';
import '../utils/song_options_bottom_sheet.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomNavHeight,
      height: 64.0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(hideCover: false),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(
                  position: animation.drive(tween),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
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
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _MiniPlayerContent extends StatelessWidget {
  final dynamic song;
  final PlayerService playerService;
  final bool isDark;
  
  const _MiniPlayerContent({
    required this.song,
    required this.playerService,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (song.coverUrl.isEmpty) {
      image = Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20));
    } else if (song.coverUrl.startsWith('asset:')) {
      image = Image.asset(song.coverUrl.replaceFirst('asset:', ''), fit: BoxFit.cover);
    } else {
      image = Image.network(song.coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.black12, child: const Icon(Icons.music_note, size: 20)));
    }

    final textColor = Theme.of(context).colorScheme.onSurface;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    final controlsRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: isWide ? 32 : 24,
          icon: Icon(
            Icons.skip_previous,
            color: textColor,
          ),
          onPressed: playerService.hasPrevious ? () => playerService.playPrevious() : null,
        ),
        IconButton(
          iconSize: isWide ? 44 : 24,
          icon: Icon(
            playerService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: textColor,
          ),
          onPressed: () {
            if (playerService.isPlaying) playerService.pause();
            else playerService.play();
          },
        ),
        IconButton(
          iconSize: isWide ? 32 : 24,
          icon: Icon(
            Icons.skip_next,
            color: textColor,
          ),
          onPressed: playerService.hasNext ? () => playerService.playNext() : null,
        ),
      ],
    );

    if (isWide) {
      return GlassContainer(
        height: 64.0,
        width: double.infinity,
        borderRadius: 0,
        blurSigmaX: 20,
        blurSigmaY: 20,
        blurColor: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
            width: 0.5,
          )
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  Hero(
                    tag: 'cover_mini_${song.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: image,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          selectable: false,
                        ),
                        if (song.artist.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: textColor.withOpacity(0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: controlsRow,
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Consumer<AppProvider>(
                    builder: (context, appProvider, _) {
                      final isLiked = appProvider.isSongLiked(song);
                      return IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : textColor,
                        ),
                        onPressed: () => appProvider.toggleFavorite(song),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.queue_music,
                      color: textColor,
                    ),
                    onPressed: () {
                      final appProvider = Provider.of<AppProvider>(context, listen: false);
                      _showQueueBottomSheet(context, playerService, appProvider);
                    },
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GlassContainer(
      height: 64.0,
      width: double.infinity,
      borderRadius: 0,
      blurSigmaX: 20,
      blurSigmaY: 20,
      blurColor: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85),
      border: Border(
        top: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
          width: 0.5,
        )
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Hero(
            tag: 'cover_mini_${song.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: SizedBox(
                width: 44,
                height: 44,
                child: image,
              ),
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
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  selectable: false,
                ),
                if (song.artist.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          controlsRow,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showQueueBottomSheet(BuildContext context, PlayerService playerService, AppProvider appProvider) {
    if (playerService.autoplayEnabled && playerService.autoplayQueue.isEmpty) {
      playerService.populateAutoplayQueue(appProvider.trendingSongs);
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
        List<Song>? localQueue;
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
                        color: textColor.withOpacity(0.2),
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
                            IconButton(
                              tooltip: 'Shuffle',
                              icon: Icon(
                                playerService.isShuffleModeEnabled ? Icons.shuffle : Icons.shuffle_outlined,
                                color: playerService.isShuffleModeEnabled ? primaryColor : textColor.withOpacity(0.6),
                              ),
                              onPressed: () {
                                playerService.toggleShuffle(appProvider.allSongs);
                                setState(() {});
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Autoplay',
                              style: TextStyle(color: textColor.withOpacity(0.7)),
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
                      child: StatefulBuilder(
                        builder: (context, setSheetState) {
                          final fullPlaylist = playerService.fullEffectivePlaylist;
                          final autoQueue = playerService.autoplayQueue;
                          final autoplayLength = playerService.autoplayEnabled ? autoQueue.length : 0;
                          final hasAutoplay = autoplayLength > 0;
                          
                          // Lazily initialize localQueue so it persists across rebuilds
                          localQueue ??= List<Song>.from(fullPlaylist);
                          final queueLength = localQueue!.length;
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
                                setSheetState(() {});
                              }
                            },
                            itemBuilder: (context, index) {
                              if (index == totalItems - 1) {
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
                                final song = localQueue![index];
                                final isPlaying = index == playerService.currentEffectiveIndex;

                                return Dismissible(
                                  key: ValueKey('queue_${song.id}_$index'),
                                  direction: DismissDirection.horizontal,
                                  onDismissed: (direction) {
                                    playerService.removeFromQueue(index);
                                    localQueue!.removeAt(index);
                                    setSheetState(() {});
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
                                          child: Stack(
                                            children: [
                                              song.coverUrl.isEmpty
                                                  ? Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: isDark ? Colors.white10 : Colors.black12,
                                                      child: Icon(Icons.music_note, color: textColor.withOpacity(0.5)),
                                                    )
                                                  : (song.coverUrl.startsWith('asset:')
                                                      ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 50, height: 50, fit: BoxFit.cover)
                                                      : Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                                              if (isPlaying)
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.black45,
                                                  child: Center(
                                                    child: Icon(Icons.equalizer, color: primaryColor, size: 24),
                                                  ),
                                                ),
                                            ],
                                          ),
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
                                        trailing: isPlaying
                                            ? const SizedBox(width: 24)
                                            : IconButton(
                                                icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                                                onPressed: () => showSongOptionsBottomSheet(context, song, isQueueContext: true, queueIndex: index),
                                              ),
                                        onTap: () async {
                                          final indices = playerService.audioPlayer.effectiveIndices;
                                          final originalIndex = (indices != null && indices.length > index) ? indices[index] : index;
                                          await playerService.seekToTrack(originalIndex);
                                          if (context.mounted) Navigator.pop(context);
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              } else if (index == queueLength) {
                                return SizedBox(
                                  key: const ValueKey('autoplay_header'),
                                  height: 72,
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('— End of Queue —', style: TextStyle(color: textColor.withOpacity(0.5), fontWeight: FontWeight.bold)),
                                        Text('Autoplay Tracks', style: TextStyle(color: primaryColor.withOpacity(0.8), fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
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
                                                  child: Icon(Icons.music_note, color: textColor.withOpacity(0.5)),
                                                )
                                              : (song.coverUrl.startsWith('asset:')
                                                  ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 50, height: 50, fit: BoxFit.cover)
                                                  : Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                                        ),
                                      ),
                                      title: Text(
                                        song.title,
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.8),
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Icon(Icons.auto_awesome, color: primaryColor.withOpacity(0.5)),
                                      onTap: () async {
                                        playerService.autoplayQueue.removeAt(autoplayIndex);
                                        await playerService.addToQueue(song);
                                        final newIndex = playerService.playlist.length - 1;
                                        await playerService.seekToTrack(newIndex);
                                        playerService.populateAutoplayQueue(appProvider.trendingSongs);
                                        if (context.mounted) Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }
                      ),
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
}
