import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  // Fix 3-dot menu padding
  content = content.replaceFirst(
    '''                                    ListTile(
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
                                    ),''',
    '''                                    ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
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
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                      leading: const Icon(Icons.download, color: Colors.white),
                                      title: const Text('Download', style: const TextStyle(color: Colors.white)),
                                      onTap: () {
                                        appProvider.downloadSong(song);
                                        Navigator.pop(context);
                                      },
                                    ),'''
  );

  file.writeAsStringSync(content);
  print('Patched formatting properly!');
}
