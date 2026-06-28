import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  // Fix 1: Change IconButton with more_vert to PopupMenuButton
  content = content.replaceFirst(
    '''                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            onPressed: () {
                              showSongOptionsBottomSheet(context, qSong, isFullScreenPlayer: true);
                            },
                          ),''',
    '''                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF24243E) : Colors.white,
                            onSelected: (value) {
                              if (value == 'like') {
                                appProvider.toggleFavorite(qSong);
                              } else if (value == 'download') {
                                appProvider.downloadSong(qSong);
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
                                                appProvider.addSongToPlaylist(playlist.id, qSong.id);
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
                                child: Text(appProvider.favoriteSongs.any((s) => s.id == qSong.id) ? 'Unlike' : 'Like'),
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
                          ),'''
  );

  // Fix 2: Revert to using the actual PositionStream so Duration updates
  content = content.replaceFirst(
    '''                      StreamBuilder<int>(
                        stream: Stream.periodic(const Duration(milliseconds: 200), (i) => i),
                        builder: (context, snapshot) {
                          final position = playerService.currentPosition;
                          final duration = playerService.totalDuration;''',
    '''                      StreamBuilder<Duration>(
                        stream: playerService.audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? playerService.currentPosition;
                          final duration = playerService.totalDuration;'''
  );

  // Also replace 'theme.colorScheme.onPrimary' in playlist_screen.dart
  final file2 = File('lib/ui/playlist_screen.dart');
  String content2 = file2.readAsStringSync();
  content2 = content2.replaceAll('theme.colorScheme.onPrimary', 'Colors.white');
  file2.writeAsStringSync(content2);

  file.writeAsStringSync(content);
  print('Patched successfully.');
}
