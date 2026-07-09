import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File(r'D:\Studies\Projects\Music Player\firestore_songs.json');
  final text = await file.readAsString();
  final List<dynamic> songs = jsonDecode(text);

  int saavnAudioCount = 0;
  int cloudinaryAudioCount = 0;
  List<Map<String, dynamic>> wrongTitles = [];

  for (var song in songs) {
    String audioUrl = song['audioUrl'] ?? '';
    String title = song['title'] ?? '';
    if (audioUrl.contains('saavncdn')) saavnAudioCount++;
    if (audioUrl.contains('cloudinary')) cloudinaryAudioCount++;

    if (title.toLowerCase().contains('manjanathi') || title.toLowerCase().contains('chillax')) {
      wrongTitles.add(song);
    }
  }

  print('Total Songs: \${songs.length}');
  print('Saavn Audio URLs: \$saavnAudioCount');
  print('Cloudinary Audio URLs: \$cloudinaryAudioCount');
  print('Found mismatched titles: \$wrongTitles');
}
