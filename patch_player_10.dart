import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  final oldBlock = '''                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      contentPadding: const EdgeInsets.only(left: 24, right: 4),
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
                                      contentPadding: const EdgeInsets.only(left: 24, right: 4),
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
                                      contentPadding: const EdgeInsets.only(left: 24, right: 4),
                                      leading: const Icon(Icons.download, color: Colors.white),
                                      title: const Text('Download', style: const TextStyle(color: Colors.white)),
                                      onTap: () {
                                        appProvider.downloadSong(song);
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],''';

  final newBlock = '''                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        appProvider.toggleFavorite(song);
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              appProvider.favoriteSongs.any((s) => s.id == song.id) ? Icons.favorite : Icons.favorite_border,
                                              color: appProvider.favoriteSongs.any((s) => s.id == song.id) ? Colors.pinkAccent : Colors.white,
                                              size: 24,
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              appProvider.favoriteSongs.any((s) => s.id == song.id) ? 'Unlike' : 'Like',
                                              style: const TextStyle(color: Colors.white, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
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
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.playlist_add, color: Colors.white, size: 24),
                                            SizedBox(width: 16),
                                            Text('Add to Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        appProvider.downloadSong(song);
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.download, color: Colors.white, size: 24),
                                            SizedBox(width: 16),
                                            Text('Download', style: TextStyle(color: Colors.white, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],''';

  content = content.replaceFirst(oldBlock, newBlock);

  file.writeAsStringSync(content);
  print('Patched custom rows properly!');
}
