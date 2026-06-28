import 'dart:io';

void main() {
  final file = File('lib/ui/profile_screen.dart');
  String content = file.readAsStringSync();
  
  final regex = RegExp(r"List<Widget> gridItems = \[\];");
  
  final replacement = '''List<Widget> gridItems = [];
                                  gridItems.add(
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlaylistScreen(
                                              playlist: Playlist(
                                                id: 'all_songs',
                                                name: 'All Songs',
                                                description: 'Every song available',
                                                creatorId: 'system',
                                                songIds: appProvider.allSongs.map((s) => s.id).toList(),
                                                coverUrl: '',
                                                createdAt: DateTime.now(),
                                                isPublic: true,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: GlassContainer(
                                        borderRadius: 16,
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(Icons.library_music, color: Theme.of(context).colorScheme.primary, size: 30),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'All Songs',
                                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );''';

  if (regex.hasMatch(content)) {
    // Check if we already injected it
    if (!content.contains("id: 'all_songs'")) {
      content = content.replaceFirst(regex, replacement);
      file.writeAsStringSync(content);
      print('Added All Songs playlist');
    } else {
      print('All Songs already exists');
    }
  } else {
    print('Could not find gridItems declaration');
  }
}
