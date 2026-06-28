import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  // Fix 1: _formatDuration
  content = content.replaceFirst(
    '''  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return "\\\$hours:\\\${twoDigits(minutes)}:\\\$seconds";
    }
    return "\\\$minutes:\\\$seconds";
  }''',
    '''  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (hours > 0) {
      return "\$hours:\${twoDigits(minutes)}:\$seconds";
    }
    return "\$minutes:\$seconds";
  }'''
  );

  // Fix 2: Bottom row arrow removal
  content = content.replaceFirst(
    '''                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // spacer
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white54,
                          size: 32,
                        ),
                        onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.queue_music,
                          color: Colors.white54,
                          size: 24,
                        ),
                        onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                      ),
                    ],''',
    '''                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.queue_music,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                      ),
                    ],'''
  );

  // Fix 3: Glassmorphic Menu
  content = content.replaceFirst(
    '''                      GlassContainer(
                        borderRadius: 30,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24243E) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'like') {
                              appProvider.toggleFavorite(song);
                            } else if (value == 'download') {
                              appProvider.downloadSong(song);
                            } else if (value == 'playlist') {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24243E) : Colors.white,
                                    title: const Text('Select Playlist'),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: appProvider.userPlaylists.length,
                                        itemBuilder: (context, index) {
                                          final playlist = appProvider.userPlaylists[index];
                                          return ListTile(
                                            title: Text(playlist.name),
                                            onTap: () {
                                              appProvider.addSongToPlaylist(playlist.id, song.id);
                                              Navigator.pop(context);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'like',
                              child: Text(appProvider.favoriteSongs.any((s) => s.id == song.id) ? 'Unlike' : 'Like'),
                            ),
                            const PopupMenuItem(
                              value: 'playlist',
                              child: Text('Add to Playlist'),
                            ),
                            const PopupMenuItem(
                              value: 'download',
                              child: Text('Download'),
                            ),
                          ],
                        ),
                      ),''',
    '''                      GlassContainer(
                        borderRadius: 30,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () {
                            final RenderBox button = context.findRenderObject() as RenderBox;
                            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                            final RelativeRect position = RelativeRect.fromRect(
                              Rect.fromPoints(
                                button.localToGlobal(Offset.zero, ancestor: overlay),
                                button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                              ),
                              Offset.zero & overlay.size,
                            );

                            showMenu(
                              context: context,
                              position: position,
                              color: Colors.transparent,
                              elevation: 0,
                              items: [
                                PopupMenuItem(
                                  enabled: false,
                                  padding: EdgeInsets.zero,
                                  child: GlassContainer(
                                    borderRadius: 15,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading: Icon(
                                            appProvider.favoriteSongs.any((s) => s.id == song.id) ? Icons.favorite : Icons.favorite_border,
                                            color: appProvider.favoriteSongs.any((s) => s.id == song.id) ? Colors.pinkAccent : Colors.white,
                                          ),
                                          title: Text(
                                            appProvider.favoriteSongs.any((s) => s.id == song.id) ? 'Unlike' : 'Like',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          onTap: () {
                                            appProvider.toggleFavorite(song);
                                            Navigator.pop(context);
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.playlist_add, color: Colors.white),
                                          title: const Text('Add to Playlist', style: const TextStyle(color: Colors.white)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24243E) : Colors.white,
                                                  title: const Text('Select Playlist'),
                                                  content: SizedBox(
                                                    width: double.maxFinite,
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount: appProvider.userPlaylists.length,
                                                      itemBuilder: (context, index) {
                                                        final playlist = appProvider.userPlaylists[index];
                                                        return ListTile(
                                                          title: Text(playlist.name),
                                                          onTap: () {
                                                            appProvider.addSongToPlaylist(playlist.id, song.id);
                                                            Navigator.pop(context);
                                                          },
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.download, color: Colors.white),
                                          title: const Text('Download', style: const TextStyle(color: Colors.white)),
                                          onTap: () {
                                            appProvider.downloadSong(song);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),'''
  );

  file.writeAsStringSync(content);
  print('Patched formatting properly!');
}
