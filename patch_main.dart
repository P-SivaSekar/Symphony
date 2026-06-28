import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();

  final oldBlock = '''    if (playerService.onQueueEmpty == null) {
      playerService.onQueueEmpty = () {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          playerService.consumeAutoplay(appProvider.allSongs);
        }
      };
    }

    // Ensure the autoplay queue is pre-populated whenever the UI builds
    if (playerService.autoplayEnabled && playerService.autoplayQueue.isEmpty && appProvider.allSongs.isNotEmpty) {
      // populate asynchronously so we don't trigger state changes during build
      Future.microtask(() => playerService.populateAutoplayQueue(appProvider.allSongs));
    }''';

  final newBlock = '''    if (playerService.onQueueEmpty == null) {
      playerService.onQueueEmpty = () {
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
      };
    }''';

  if (content.contains('playerService.consumeAutoplay')) {
    content = content.replaceFirst(oldBlock, newBlock);
    file.writeAsStringSync(content);
  } else {
    print('main.dart already patched');
  }
}
