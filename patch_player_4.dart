import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  // Fix 1: Play button glow reduction
  content = content.replaceFirst(
    '''                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],''',
    '''                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],'''
  );

  // Fix 2: 3-dot menu position via PopupMenuButton
  content = content.replaceFirst(
    '''                        child: IconButton(
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
                        ),''',
    '''                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: Colors.transparent,
                          elevation: 0,
                          offset: const Offset(0, 40),
                          itemBuilder: (context) => [
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
                        ),'''
  );

  file.writeAsStringSync(content);
  print('Patched formatting properly!');
}
