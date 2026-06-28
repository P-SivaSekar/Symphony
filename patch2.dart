import 'dart:io';
void main() {
  final f = File('lib/main.dart');
  String c = f.readAsStringSync();
  c = c.replaceAll('''      playerService.onQueueEmpty = () {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          playerService.markAutoplayStart();
          final availableSongs = appProvider.allSongs.where((s) => s.audioUrl.isNotEmpty).toList();
          if (availableSongs.isNotEmpty) {
            availableSongs.shuffle();
            final song = availableSongs.first;
            playerService.addToQueue(song).then((_) {
              playerService.playNext();
            });
          }
        }
      };''', '''      playerService.onQueueEmpty = () {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          playerService.consumeAutoplay(appProvider.allSongs);
        }
      };''');
  if (!c.contains('playerService.populateAutoplayQueue(appProvider.allSongs)')) {
    // Inject the prepopulation
    c = c.replaceFirst('    if (playerService.onQueueEmpty == null) {', '''    // Ensure the autoplay queue is pre-populated whenever the UI builds
    if (playerService.autoplayEnabled && playerService.autoplayQueue.isEmpty && appProvider.allSongs.isNotEmpty) {
      Future.microtask(() => playerService.populateAutoplayQueue(appProvider.allSongs));
    }

    if (playerService.onQueueEmpty == null) {''');
  }
  f.writeAsStringSync(c);
}
