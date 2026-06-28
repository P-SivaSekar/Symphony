import 'dart:io';

void main() {
  final file = File('lib/services/player_service.dart');
  String content = file.readAsStringSync();

  final oldVar = '''  List<Song> _autoplayQueue = [];
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

  final newVar = '''  int? _autoplayStartIndex;
  int? get autoplayStartIndex => _autoplayStartIndex;

  void markAutoplayStart() {
    if (_autoplayStartIndex == null) {
      _autoplayStartIndex = _playlist.length;
      notifyListeners();
    }
  }
  
  void clearAutoplayStart() {
    _autoplayStartIndex = null;
  }''';

  if (content.contains('List<Song> _autoplayQueue')) {
    content = content.replaceFirst(oldVar, newVar);
  }

  final oldLoadPlaylist = '''  Future<void> loadPlaylist(List<Song> songs, {int initialIndex = 0}) async {''';
  final newLoadPlaylist = '''  Future<void> loadPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    clearAutoplayStart();''';
  if (!content.contains('clearAutoplayStart();')) {
    content = content.replaceFirst(oldLoadPlaylist, newLoadPlaylist);
  }

  file.writeAsStringSync(content);
}
