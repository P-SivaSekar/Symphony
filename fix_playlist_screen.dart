import 'dart:io';

void main() {
  final file = File('lib/ui/playlist_screen.dart');
  String content = file.readAsStringSync();
  
  final regex = RegExp(r"GlassContainer\(\s*borderRadius: 30,\s*child: IconButton\(\s*icon: Icon\(\s*Icons\.more_vert,\s*color: textColor\.withOpacity\(0\.5\),\s*\),\s*song\.id,\s*\)\)\s*\{");
  final fixedSection = '''GlassContainer(
                                              borderRadius: 30,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: textColor.withOpacity(0.5),
                                                ),
                                                onPressed: () {
                                                  showSongOptionsBottomSheet(
                                                    context,
                                                    song,
                                                  );
                                                },
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        if (_isMultiSelectMode) {
                                          setState(() {
                                            if (_selectedSongs.contains(
                                              song.id,
                                            )) {''';

  if (regex.hasMatch(content)) {
    content = content.replaceFirst(regex, fixedSection);
    file.writeAsStringSync(content);
    print("Fixed playlist_screen.dart");
  } else {
    print("Could not find broken section in playlist_screen.dart with Regex");
  }
}
