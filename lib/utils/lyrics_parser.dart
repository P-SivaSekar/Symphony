class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class LyricsParser {
  static List<LyricLine> parse(String lrcText) {
    if (lrcText.isEmpty) return [];

    final lines = lrcText.split('\n');
    final List<LyricLine> lyricLines = [];
    final regExp = RegExp(r'^\[(\d+):(\d+)(?:\.(\d+))?\](.*)$');

    for (var line in lines) {
      final trimmed = line.trim();
      final match = regExp.firstMatch(trimmed);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final milliStr = match.group(3) ?? '00';
        // Normalize milliseconds representation (e.g. .3 -> 300, .30 -> 300, .03 -> 30)
        final milli = int.parse(milliStr.padRight(3, '0').substring(0, 3));

        final time = Duration(minutes: min, seconds: sec, milliseconds: milli);
        final text = match.group(4)!.trim();
        
        lyricLines.add(LyricLine(time: time, text: text));
      }
    }
    
    // Sort lines just in case
    lyricLines.sort((a, b) => a.time.compareTo(b.time));
    return lyricLines;
  }
}
