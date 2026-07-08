import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FixCoversApp());
}

class FixCoversApp extends StatelessWidget {
  const FixCoversApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Fixing Covers...')),
        body: const FixCoversBody(),
      ),
    );
  }
}

class FixCoversBody extends StatefulWidget {
  const FixCoversBody({super.key});

  @override
  State<FixCoversBody> createState() => _FixCoversBodyState();
}

class _FixCoversBodyState extends State<FixCoversBody> {
  String status = "Starting...";
  int total = 0;
  int current = 0;

  @override
  void initState() {
    super.initState();
    _fixCovers();
  }

  Future<void> _fixCovers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('songs').get();
      final docs = snapshot.docs;
      
      setState(() {
        total = docs.length;
        status = "Fetched $total songs from Firestore.";
      });

      for (var i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final artist = data['artist'] as String? ?? '';
        
        setState(() {
          current = i + 1;
          status = "Processing: $title";
        });

        // Smart query
        String searchTerm = title;
        if (artist.isNotEmpty && 
            artist.toLowerCase() != 'unknown' && 
            !artist.toLowerCase().contains('unknown') && 
            !artist.toLowerCase().contains('various')) {
          searchTerm += ' $artist';
        } else {
          searchTerm += ' Tamil';
        }

        String? newCoverUrl;

        // Try query 1: Title + Artist/Tamil
        newCoverUrl = await _searchJioSaavn(searchTerm);

        // Fallback: Try just Title + Tamil
        if (newCoverUrl == null) {
          newCoverUrl = await _searchJioSaavn('$title Tamil');
        }

        // Fallback: Try just Title
        if (newCoverUrl == null) {
          newCoverUrl = await _searchJioSaavn(title);
        }

        if (newCoverUrl != null) {
          final currentCoverUrl = data['coverUrl'] as String? ?? '';
          if (currentCoverUrl != newCoverUrl) {
            await doc.reference.update({'coverUrl': newCoverUrl});
            print("Updated '$title' to $newCoverUrl");
          } else {
            print("Cover for '$title' is already correct.");
          }
        } else {
          print("Could not find cover for '$title'");
        }
        
        // Small delay to prevent rate limits
        await Future.delayed(const Duration(milliseconds: 300));
      }

      setState(() {
        status = "Finished processing all songs!";
      });
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
    }
  }

  Future<String?> _searchJioSaavn(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://www.jiosaavn.com/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0&n=5&p=1&q=$encodedQuery&__call=search.getResults';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['results'] != null && (data['results'] as List).isNotEmpty) {
          final firstResult = data['results'][0];
          String image = firstResult['image'] as String? ?? '';
          if (image.isNotEmpty) {
            // Upgrade resolution to 500x500
            image = image.replaceAll('150x150', '500x500');
            image = image.replaceAll('50x50', '500x500');
            return image;
          }
        }
      }
    } catch (e) {
      print("Error fetching $query: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          if (total > 0)
            LinearProgressIndicator(value: current / total),
          const SizedBox(height: 10),
          Text('$current / $total'),
        ],
      ),
    );
  }
}
