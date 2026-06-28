import 'dart:io';

void main() {
  final serviceFile = File('d:/Studies/Projects/Music Player/lib/services/player_service.dart');
  String serviceContent = serviceFile.readAsStringSync();
  
  // Remove notifyListeners() from positionStream
  serviceContent = serviceContent.replaceAll('''
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
''', '''
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      // Removed notifyListeners() to prevent UI lag on every position tick
    });
''');

  serviceFile.writeAsStringSync(serviceContent);

  final screenFile = File('d:/Studies/Projects/Music Player/lib/ui/player_screen.dart');
  String screenContent = screenFile.readAsStringSync();

  // Replace ProgressBar with StreamBuilder
  final progressBarOld = '''
                    child: ProgressBar(
                      progress: playerService.currentPosition,
                      total: playerService.totalDuration,
                      onSeek: (duration) => playerService.seek(duration),
                      progressBarColor: primaryColor,
                      baseBarColor: isDark ? Colors.white24 : Colors.black26,
                      bufferedBarColor: isDark
                          ? Colors.white12
                          : Colors.black12,
                      thumbColor: primaryColor,
                      thumbRadius: 6,
                      timeLabelPadding: 10,
                      timeLabelTextStyle: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),''';

  final progressBarNew = '''
                    child: StreamBuilder<Duration>(
                      stream: playerService.audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? playerService.currentPosition;
                        return ProgressBar(
                          progress: position,
                          total: playerService.totalDuration,
                          onSeek: (duration) => playerService.seek(duration),
                          progressBarColor: primaryColor,
                          baseBarColor: isDark ? Colors.white24 : Colors.black26,
                          bufferedBarColor: isDark
                              ? Colors.white12
                              : Colors.black12,
                          thumbColor: primaryColor,
                          thumbRadius: 6,
                          timeLabelPadding: 10,
                          timeLabelTextStyle: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        );
                      }
                    ),''';

  screenContent = screenContent.replaceAll(progressBarOld, progressBarNew);
  screenFile.writeAsStringSync(screenContent);

  print("Refactoring complete");
}
