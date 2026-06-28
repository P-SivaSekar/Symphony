import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  final lines = file.readAsLinesSync();
  
  // Find where it's broken
  int brokenStart = -1;
  int brokenEnd = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains("final actualIndex =")) {
      if (i + 1 < lines.length && lines[i+1].contains(": qSong.coverUrl.startsWith(")) {
        brokenStart = i;
        brokenEnd = i + 1;
        break;
      }
    }
  }
  
  if (brokenStart != -1) {
    final fixedCode = '''                          final actualIndex =
                              playerService.audioPlayer.effectiveIndices != null
                              ? playerService
                                    .audioPlayer
                                    .effectiveIndices![index]
                              : index;
                          playerService.audioPlayer.seek(
                            Duration.zero,
                            index: actualIndex,
                          );
                        }
                      },
                      itemCount: playerService.fullEffectivePlaylist.length,
                      itemBuilder: (context, index) {
                        final qSong =
                            playerService.fullEffectivePlaylist[index];
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40.0,
                                    vertical: 16.0,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      decoration: widget.hideCover ? null : BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: Hero(
                                          tag: 'cover_\${qSong.id}',
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(20),
                                            child: widget.hideCover ? const SizedBox.expand() : qSong.coverUrl.isEmpty
                                                ? Container(
                                                    color: Theme.of(context).brightness == Brightness.dark
                                                        ? Colors.white10
                                                        : Colors.black12,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.music_note,
                                                      color: Theme.of(context).brightness == Brightness.dark
                                                          ? Colors.white24
                                                          : Colors.black26,
                                                      size: 100,
                                                    ),
                                                  )
                                                : qSong.coverUrl.startsWith(''';
                                                
    // Replace lines from brokenStart to brokenEnd with fixedCode
    lines[brokenStart] = fixedCode;
    lines.removeAt(brokenEnd);
    
    file.writeAsStringSync(lines.join('\\n'));
    print("Fixed player_screen.dart structural issue!");
  } else {
    print("Broken section not found.");
  }
}
