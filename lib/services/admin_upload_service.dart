import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUploadService {
  // Cloudinary configuration
  final String _cloudName = 'dx02qjcqn';
  final String _uploadPreset = 'symphony_preset';

  /// Uploads raw bytes to Cloudinary (works on both Web and Mobile).
  Future<String?> uploadAudioBytes(Uint8List bytes, String fileName) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
      );

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String?;
      } else {
        print("Cloudinary Upload Error: $responseData");
        return null;
      }
    } catch (e) {
      print("Upload exception: $e");
      return null;
    }
  }

  Future<void> autoFixDatabase() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('songs')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        String title = data['title'] ?? '';
        String artist = data['artist'] ?? '';
        String coverUrl = data['coverUrl'] ?? '';
        String id = doc.id;

        // 1. Delete "aadi pova aavani" if it has no cover and artist is unknown
        if (title.toLowerCase().contains('aadi pova aavani') &&
            (artist.toLowerCase() == 'unknown' ||
                artist.toLowerCase() == 'unknown artist') &&
            (coverUrl.isEmpty || coverUrl.contains('via.placeholder.com'))) {
          print("AutoFix: Deleting broken duplicate $title");
          await deleteSong(id);
          continue;
        }

        bool changed = false;
        String newTitle = title;

        // Strip "- Vijay Yesudas" or any other artist trailing name
        if (newTitle.contains(' - ')) {
          newTitle = newTitle.split(' - ').first.trim();
          changed = true;
        }

        // Map known songs to their movies
        if (newTitle.toLowerCase() == 'dheivangal ellam') {
          newTitle = 'Dheivangal Ellam - Deiva Thirumagal';
          changed = true;
        } else if (newTitle.toLowerCase() == 'aadi pova aavani') {
          newTitle = 'Aadi Pova Aavani - Thirumanam Enum Nikkah';
          changed = true;
        } else if (newTitle.toLowerCase().contains('o maara')) {
          newTitle = 'O Maara - Thug Life';
          changed = true;
        } else {
          // General case: if we don't know the movie, just ensure the artist is not in the title.
          // The user requested "songs name hypen the movie name". If we don't know it, we just leave the cleaned title.
          if (changed) {
            // Already stripped the trailing artist above
          }
        }

        if (changed && newTitle != title) {
          print("AutoFix: Renaming '$title' -> '$newTitle'");
          await updateSongMetadata(id, {'title': newTitle});
        }
      }
    } catch (e) {
      print("AutoFix Error: $e");
    }
  }

  Future<String> saveSongMetadata({
    required String title,
    required String artist,
    required String coverUrl,
    required String audioUrl,
    required bool isTrending,
  }) async {
    try {
      // 1. Save Song to Firestore
      final docRef = await FirebaseFirestore.instance.collection('songs').add({
        'title': title,
        'artist': artist,
        'coverUrl': coverUrl,
        'audioUrl': audioUrl,
        'isTrending': isTrending,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print("Firestore Save Error (Songs): $e");
      throw Exception('Failed to save song metadata.');
    }
    // Automatic notifications are disabled. 
    // The admin will now manually fulfill song requests and notify users from the dashboard.
  }

  Future<void> updateSongMetadata(
    String songId,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('songs')
          .doc(songId)
          .update(data);
    } catch (e) {
      print("Firestore Update Error: $e");
      throw Exception('Failed to update song metadata.');
    }
  }

  Future<void> deleteSong(String songId) async {
    try {
      await FirebaseFirestore.instance.collection('songs').doc(songId).delete();
    } catch (e) {
      print("Firestore Delete Error: $e");
      throw Exception('Failed to delete song.');
    }
  }
}
