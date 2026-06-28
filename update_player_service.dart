import 'dart:io';

void main() {
  final file = File('lib/services/player_service.dart');
  String content = file.readAsStringSync();
  
  // 1. Add fields
  final stateVars = '''  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;''';
  final stateVarsNew = '''  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  bool _autoplayEnabled = true;
  VoidCallback? onQueueEmpty;

  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  bool get autoplayEnabled => _autoplayEnabled;

  Future<void> toggleAutoplay() async {
    _autoplayEnabled = !_autoplayEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoplay_enabled', _autoplayEnabled);
    notifyListeners();
  }''';
  
  if (content.contains(stateVars)) {
    // Wait, the file already has `bool get isShuffleModeEnabled => _isShuffleModeEnabled;`
    // Let's replace the getters too to avoid duplication.
    final stateVarsAndGetters = '''  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;

  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;''';
    if (content.contains(stateVarsAndGetters)) {
      content = content.replaceAll(stateVarsAndGetters, stateVarsNew);
    } else {
      print("Could not find stateVarsAndGetters");
      return;
    }
  } else {
    print("Could not find stateVars");
    return;
  }

  // 2. Add load prefs
  final loadPrefs = '''      final savedIndex = prefs.getInt('saved_index') ?? 0;''';
  final loadPrefsNew = '''      final savedIndex = prefs.getInt('saved_index') ?? 0;
      final savedAutoplay = prefs.getBool('autoplay_enabled');
      if (savedAutoplay != null) _autoplayEnabled = savedAutoplay;''';
  if (content.contains(loadPrefs)) {
    content = content.replaceAll(loadPrefs, loadPrefsNew);
  }

  // 3. Update initPlayer
  final completedState = '''        if (_loopMode == LoopMode.off && !_audioPlayer.hasNext) {
          // If we reached the end and not looping, stop. JustAudio handles looping internally.
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero, index: 0);
        }''';
  final completedStateNew = '''        if (_loopMode == LoopMode.off && !_audioPlayer.hasNext) {
          if (_autoplayEnabled && onQueueEmpty != null) {
            onQueueEmpty!();
          } else {
            // If we reached the end and not looping, stop. JustAudio handles looping internally.
            _audioPlayer.pause();
            _audioPlayer.seek(Duration.zero, index: 0);
          }
        }''';
  if (content.contains(completedState)) {
    content = content.replaceAll(completedState, completedStateNew);
  } else {
    print("Could not find completedState");
    return;
  }
  
  // Update skipNext to also use autoplay when at end
  final skipNextStr = '''  Future<void> skipNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
    } else {
      await _audioPlayer.seek(Duration.zero, index: 0);
    }
    await play();
  }''';
  final skipNextNew = '''  Future<void> skipNext() async {
    if (_audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      await play();
    } else {
      if (_autoplayEnabled && onQueueEmpty != null) {
        onQueueEmpty!();
      } else {
        await _audioPlayer.seek(Duration.zero, index: 0);
        await play();
      }
    }
  }''';
  if (content.contains(skipNextStr)) {
    content = content.replaceAll(skipNextStr, skipNextNew);
  } else {
    print("Could not find skipNextStr");
  }

  file.writeAsStringSync(content);
  print('player_service.dart updated!');
}
