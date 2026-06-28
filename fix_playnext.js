const fs = require('fs');
let code = fs.readFileSync('lib/services/player_service.dart', 'utf8');

// Add play next override queue
code = code.replace(
  '  bool _isInitialized = false;',
  '  bool _isInitialized = false;\n  final List<String> _playNextOverrideIds = [];'
);

code = code.replace(
  '  Future<void> addNext(Song song) async {',
  `  Future<void> addNext(Song song) async {
    _playNextOverrideIds.add(song.id);`
);

code = code.replace(
  '  Future<void> playNext() async {',
  `  Future<void> playNext() async {
    if (_playNextOverrideIds.isNotEmpty) {
      final nextId = _playNextOverrideIds.removeAt(0);
      final index = _playlist.indexWhere((s) => s.id == nextId);
      if (index != -1) {
        await _audioPlayer.seek(Duration.zero, index: index);
        return;
      }
    }`
);

// also in the stream listener:
code = code.replace(
  '        if (_loopMode == LoopMode.off && !_audioPlayer.hasNext) {',
  `        if (_playNextOverrideIds.isNotEmpty) {
          final nextId = _playNextOverrideIds.removeAt(0);
          final index = _playlist.indexWhere((s) => s.id == nextId);
          if (index != -1) {
            _audioPlayer.seek(Duration.zero, index: index);
            return;
          }
        }
        if (_loopMode == LoopMode.off && !_audioPlayer.hasNext) {`
);

fs.writeFileSync('lib/services/player_service.dart', code, 'utf8');
