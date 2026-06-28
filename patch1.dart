import 'dart:io';
void main() {
  final f = File('lib/services/player_service.dart');
  String c = f.readAsStringSync();
  
  c = c.replaceAll('''  int? _autoplayStartIndex;
  int? get autoplayStartIndex => _autoplayStartIndex;

  void markAutoplayStart() {
    if (_autoplayStartIndex == null) {
      _autoplayStartIndex = _playlist.length;
      notifyListeners();
    }
  }
  
  void clearAutoplayStart() {
    _autoplayStartIndex = null;
  }''', '''  List<Song> _autoplayQueue = [];
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
  }''');

  c = c.replaceAll('clearAutoplayStart();', '');
  f.writeAsStringSync(c);
}
