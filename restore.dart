import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();
  
  final broken = '''                        if (index != playerService.currentEffectiveIndex) {
                          final actualIndex =
                                                : qSong.coverUrl.startsWith(''';
                                                
  final fixed = '''                        if (index != playerService.currentEffectiveIndex) {
                          final actualIndex =
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
                                                    color: isDark
                                                        ? Colors.white10
                                                        : Colors.black12,
                                                    alignment: Alignment.center,
                                                    child: Icon(
                                                      Icons.music_note,
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black26,
                                                      size: 100,
                                                    ),
                                                  )
                                                : qSong.coverUrl.startsWith(''';

  content = content.replaceAll(broken, fixed);
  file.writeAsStringSync(content);
  print('Fixed!');
}
