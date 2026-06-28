import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  final oldBlock = '''                    Expanded(
                      child: ListView.builder(
                        itemCount: playerService.fullEffectivePlaylist.length,
                        itemBuilder: (context, index) {
                          final song = playerService.fullEffectivePlaylist[index];
                          final isPlaying = index == playerService.currentEffectiveIndex;
                          return ListTile(
                            leading: ClipRRect(
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
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isPlaying
                                ? Icon(Icons.equalizer, color: primaryColor)
                                : IconButton(
                                    icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                                    onPressed: () => showSongOptionsBottomSheet(context, song),
                                  ),
                            onTap: () {
                              playerService.audioPlayer.seek(Duration.zero, index: index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),''';

  final newBlock = '''                    Expanded(
                      child: Builder(builder: (context) {
                        final queueLength = playerService.fullEffectivePlaylist.length;
                        final showAutoplay = playerService.autoplayEnabled;
                        final autoplayLength = playerService.autoplayQueue.length;
                        final totalItems = queueLength + (showAutoplay && autoplayLength > 0 ? autoplayLength + 1 : 0);

                        final scrollController = ScrollController(
                          initialScrollOffset: playerService.currentEffectiveIndex * 72.0,
                        );

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: totalItems,
                          itemBuilder: (context, index) {
                            if (index < queueLength) {
                              final song = playerService.fullEffectivePlaylist[index];
                              final isPlaying = index == playerService.currentEffectiveIndex;
                              return SizedBox(
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
                                              child: Icon(Icons.music_note, color: textColor.withOpacity(0.5)),
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
                                      style: TextStyle(color: textColor.withOpacity(0.7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: isPlaying
                                        ? Icon(Icons.equalizer, color: primaryColor)
                                        : IconButton(
                                            icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                                            onPressed: () => showSongOptionsBottomSheet(context, song),
                                          ),
                                    onTap: () {
                                      playerService.audioPlayer.seek(Duration.zero, index: index);
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            } else if (index == queueLength) {
                              // End of Queue marker
                              return SizedBox(
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
                              // Autoplay songs
                              final autoIndex = index - queueLength - 1;
                              final song = playerService.autoplayQueue[autoIndex];
                              return SizedBox(
                                height: 72,
                                child: Center(
                                  child: ListTile(
                                    leading: Opacity(
                                      opacity: 0.5,
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
                                      style: TextStyle(color: textColor.withOpacity(0.6)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      style: TextStyle(color: textColor.withOpacity(0.4)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Icon(Icons.auto_awesome, color: primaryColor.withOpacity(0.5)),
                                    onTap: () {
                                       // Optional: jump straight to it, or ignore.
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }),
                    ),''';

  content = content.replaceFirst(oldBlock, newBlock);
  file.writeAsStringSync(content);
  print('Patched UI successfully!');
}
