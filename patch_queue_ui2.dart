import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  final startMarker = 'Expanded(';
  final endMarker = '                    ),';
  
  // Find where Expanded( child: Builder(builder: (context) { ... starts
  final pattern = RegExp(r'Expanded\(\s*child: Builder\(builder: \(context\) \{\s*final queueLength = playerService\.fullEffectivePlaylist\.length;.*?(?=\n                    \},\n                  \),\n                \),)', dotAll: true);
  
  final newBlock = '''Expanded(
                      child: Builder(builder: (context) {
                        final hasMarker = playerService.autoplayStartIndex != null;
                        final queueLength = playerService.fullEffectivePlaylist.length;
                        final totalItems = queueLength + (hasMarker ? 1 : 0) + 1; // +1 for bottom padding

                        // We need an offset to keep current playing song visible.
                        // If current song is after marker, add 1.
                        int currentIndexOffset = playerService.currentEffectiveIndex;
                        if (hasMarker && currentIndexOffset >= playerService.autoplayStartIndex!) {
                          currentIndexOffset += 1;
                        }

                        final scrollController = ScrollController(
                          initialScrollOffset: currentIndexOffset * 72.0,
                        );

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            if (index == totalItems - 1) {
                              // Bottom Padding to ensure the last item can be scrolled to the top
                              return SizedBox(
                                height: MediaQuery.of(context).size.height * 0.7 - 72,
                              );
                            }

                            bool isMarker = false;
                            int songIndex = index;

                            if (hasMarker) {
                              if (index == playerService.autoplayStartIndex!) {
                                isMarker = true;
                              } else if (index > playerService.autoplayStartIndex!) {
                                songIndex = index - 1;
                              }
                            }

                            if (isMarker) {
                              return SizedBox(
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
                            }

                            final song = playerService.fullEffectivePlaylist[songIndex];
                            final isPlaying = songIndex == playerService.currentEffectiveIndex;
                            final isAutoplayTrack = hasMarker && songIndex >= playerService.autoplayStartIndex!;

                            return SizedBox(
                              height: 72,
                              child: Center(
                                child: ListTile(
                                  leading: Opacity(
                                    opacity: isAutoplayTrack ? 0.7 : 1.0,
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
                                      color: isPlaying ? primaryColor : (isAutoplayTrack ? textColor.withValues(alpha: 0.8) : textColor),
                                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: TextStyle(color: textColor.withValues(alpha: isAutoplayTrack ? 0.4 : 0.7)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: isPlaying
                                      ? Icon(Icons.equalizer, color: primaryColor)
                                      : (isAutoplayTrack
                                          ? Icon(Icons.auto_awesome, color: primaryColor.withValues(alpha: 0.5))
                                          : IconButton(
                                              icon: Icon(Icons.more_vert, color: textColor.withValues(alpha: 0.7)),
                                              onPressed: () => showSongOptionsBottomSheet(context, song),
                                            )),
                                  onTap: () {
                                    playerService.audioPlayer.seek(Duration.zero, index: songIndex);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    )''';

  final replaced = content.replaceFirst(pattern, newBlock);
  if (replaced == content) {
    print("Failed to match pattern!");
  } else {
    file.writeAsStringSync(replaced);
    print("Patched UI successfully!");
  }
}
