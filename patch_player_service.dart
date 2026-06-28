import 'dart:io';

void main() {
  final file = File('lib/services/player_service.dart');
  String content = file.readAsStringSync();

  final oldVar = '  bool _autoplayEnabled = true;';
  final newVar = '''  bool _autoplayEnabled = true;
  List<Song> _autoplayQueue = [];
  List<Song> get autoplayQueue => _autoplayQueue;

  void populateAutoplayQueue(List<Song> allSongs) {
    if (_autoplayQueue.length < 10) {
      final available = allSongs.where((s) => s.audioUrl.isNotEmpty && !_autoplayQueue.any((aq) => aq.id == s.id)).toList();
      available.shuffle();
      _autoplayQueue.addAll(available.take(10 - _autoplayQueue.length));
      notifyListeners();
    }
  }

  void consumeAutoplay(List<Song> allSongs) {
    if (_autoplayQueue.isEmpty) populateAutoplayQueue(allSongs);
    if (_autoplayQueue.isNotEmpty) {
      final song = _autoplayQueue.removeAt(0);
      addToQueue(song).then((_) {
        playNext();
        populateAutoplayQueue(allSongs);
      });
    }
  }''';

  if (!content.contains('List<Song> _autoplayQueue = [];')) {
    content = content.replaceFirst(oldVar, newVar);
    file.writeAsStringSync(content);
    print('Patched PlayerService successfully!');
  } else {
    print('PlayerService already patched.');
  }
}
