import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();

  final oldText = '''  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);

    final theme = Theme.of(context);''';

  final newText = '''  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (playerService.onQueueEmpty == null) {
      playerService.onQueueEmpty = () {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          import 'dart:math';
          final random = Random();
          // Filter songs that have audioUrl
          final availableSongs = appProvider.allSongs.where((s) => s.audioUrl.isNotEmpty).toList();
          if (availableSongs.isNotEmpty) {
             final song = availableSongs[random.nextInt(availableSongs.length)];
             playerService.addToQueue(song).then((_) {
               playerService.playNext();
             });
          }
        }
      };
    }

    final theme = Theme.of(context);''';

  // Dart syntax fix: `import 'dart:math';` inside method is illegal. I need to move it out or use `dart:math` globally.
  // Wait, `import 'dart:math';` is usually at the top. Let's do it properly without importing inside block.
  final newTextFixed = '''  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    if (playerService.onQueueEmpty == null) {
      playerService.onQueueEmpty = () {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          final availableSongs = appProvider.allSongs.where((s) => s.audioUrl.isNotEmpty).toList();
          if (availableSongs.isNotEmpty) {
             // Basic random without importing if possible? `availableSongs.shuffle(); availableSongs.first;`
             availableSongs.shuffle();
             final song = availableSongs.first;
             playerService.addToQueue(song).then((_) {
               playerService.playNext();
             });
          }
        }
      };
    }

    final theme = Theme.of(context);''';

  if (content.contains(oldText)) {
    content = content.replaceAll(oldText, newTextFixed);
    file.writeAsStringSync(content);
    print('Updated main.dart for Autoplay logic');
  } else {
    print('Could not find build method in main.dart');
  }
}
