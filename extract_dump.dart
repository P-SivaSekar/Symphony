import 'dart:io';

void main() async {
  final logPath = r"C:\Users\psiva\.gemini\antigravity\brain\197c61e5-ff1b-438e-9fd1-e5456ba699b8\.system_generated\tasks\task-625.log";
  final outputPath = r"D:\Studies\Projects\Music Player\firestore_songs.json";

  final file = File(logPath);
  final text = await file.readAsString();

  final startMarker = "=== FIRESTORE DUMP START ===";
  final endMarker = "=== FIRESTORE DUMP END ===";

  final startIdx = text.indexOf(startMarker);
  if (startIdx == -1) {
    print("Start marker not found.");
    exit(1);
  }

  final endIdx = text.indexOf(endMarker, startIdx);
  if (endIdx == -1) {
    print("End marker not found.");
    exit(1);
  }

  final dumpContent = text.substring(startIdx + startMarker.length, endIdx);

  final lines = dumpContent.split('\n');
  final cleanLines = <String>[];
  for (var line in lines) {
    final idx = line.indexOf("): ");
    if (idx != -1) {
      cleanLines.add(line.substring(idx + 3));
    } else {
      if (line.contains("I/flutter")) continue;
      cleanLines.add(line);
    }
  }

  final jsonStr = cleanLines.join("").trim();

  final outFile = File(outputPath);
  await outFile.writeAsString(jsonStr);
  print("Dump written to \$outputPath successfully!");
}
