import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();
  
  final regex = RegExp(r"children: \[\s*IconButton\(\s*icon: Icon\(\s*Icons\.shuffle,.*?\),\s*Text\(\s*'Up Next',.*?\),\s*IconButton\(\s*icon: Icon\(\s*ps\.loopMode\.name == 'one'.*?\),\s*\]", dotAll: true);
  
  final newRow = '''children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.shuffle,
                                                      color: ps.isShuffleModeEnabled
                                                          ? primaryColor
                                                          : textColor.withOpacity(
                                                              0.54,
                                                            ),
                                                    ),
                                                    onPressed: () =>
                                                        ps.toggleShuffle(
                                                          appProvider.allSongs,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.all_inclusive,
                                                      color: ps.autoplayEnabled
                                                          ? primaryColor
                                                          : textColor.withOpacity(0.54),
                                                    ),
                                                    onPressed: () => ps.toggleAutoplay(),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                'Up Next',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  ps.loopMode.name == 'one'
                                                      ? Icons.repeat_one
                                                      : Icons.repeat,
                                                  color:
                                                      ps.loopMode.name == 'off'
                                                      ? textColor.withOpacity(
                                                          0.54,
                                                        )
                                                      : primaryColor,
                                                ),
                                                onPressed: () =>
                                                    ps.toggleRepeat(),
                                              ),
                                            ]''';

  if (regex.hasMatch(content)) {
    content = content.replaceFirst(regex, newRow);
    file.writeAsStringSync(content);
    print('Updated player_screen.dart Autoplay UI via Regex');
  } else {
    print('Could not find row in player_screen.dart with Regex');
  }
}
