import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/song_model.dart';
import 'saavn_service.dart';
import 'dart:math';

class AIRecommendationService {
  static const String _systemPrompt = '''
You are the core recommendation engine for a premium Tamil-only music streaming application. Your task is to act as an intelligent Autoplay Feature. When given a currently playing song, its genre, and a list of recently played song IDs, you must generate a highly relevant, non-repetitive queue of next tracks.

Strictly adhere to the following operational guardrails:

1. Language Constraint:
- You must ONLY suggest Tamil songs. No other languages are permitted.

2. Micro-Genre & Mood Matching:
- The suggested songs must strictly align with the specific sub-genre and mood of the source song. 
- For example:
  * Devotional/Spiritual (e.g., If source is "Seval Kodi", suggestions must be iconic devotional tracks like "Siva Sivaya Potri", "Ullam Uruguthaiya", "Mannanalum", "Azhagendra Sollukku").
  * Romance/Melody (e.g., If source is a Harris Jayaraj melody, suggest similar era romantic melodies).
  * High-Energy/Kuthu/Item Songs (e.g., Anirudh or Vidyasagar dance tracks).
  * Tamil Rap/Indie (e.g., Arivu, Yogi B).

3. Dynamic Variety (Anti-Repetition):
- You will receive a list of "Recently Played/Suggested IDs". Do NOT suggest any song present in this list.
- To prevent the algorithm from feeling "stuck" or repetitive when the same song is searched hours or days later, utilize the provided timestamp/session seed to rotate between different "clusters" of the same genre. 
- If Cluster A (e.g., Lord Murugan devotional classics) was used recently, pivot to Cluster B (e.g., Modern devotional or alternate classic artists of the same genre) on the next request.

4. Output Format:
- Return the response strictly as a JSON array of objects containing the song details. This will be used to query the JioSaavn API.
- Do not include conversational filler.
- Ensure the output strictly matches this schema:
[
  {
    "title": "Suggested Song Title 1",
    "artist": "Artist Name",
    "search_keywords": "Optimized string for JioSaavn API search"
  }
]
''';

  /// Fetch recommendations from Gemini and then query JioSaavn for the songs.
  static Future<List<Song>> fetchAutoplayRecommendations({
    required Song currentSong,
    required List<String> recentlyPlayedIds,
    required int sessionSeed,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty) {
      print("Gemini API Key is empty. Cannot fetch AI recommendations.");
      return [];
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7, // Add some randomness for variety
        ),
      );

      // Create the JSON payload
      final inputPayload = {
        "current_song": {
          "title": currentSong.title,
          "artist": currentSong.artist,
          "album": "Unknown",
          "genre": "Tamil", // Or pass specific genre if available
        },
        "session_seed": sessionSeed,
        "recently_played": recentlyPlayedIds,
      };

      final content = [Content.text(jsonEncode(inputPayload))];
      final response = await model.generateContent(content);
      
      String responseText = response.text ?? '[]';
      print("Gemini Response: $responseText");
      
      responseText = responseText.trim();
      if (responseText.startsWith('```')) {
        responseText = responseText.replaceAll(RegExp(r'^```(json)?'), '');
        responseText = responseText.replaceAll(RegExp(r'```$'), '');
        responseText = responseText.trim();
      }

      final List<dynamic> jsonList;
      try {
        jsonList = jsonDecode(responseText);
      } catch (e) {
        print("JSON Decode error: $e");
        return [];
      }

      List<Song> recommendedSongs = [];
      
      // For each recommendation, search Saavn to get the real Song object
      for (var item in jsonList) {
        final searchKeyword = item['search_keywords'] ?? '${item['title']} ${item['artist']}';
        
        try {
          final searchResults = await SaavnService.searchTamilSongs(searchKeyword, page: 1);
          if (searchResults.isNotEmpty) {
            // Add the best match (first one)
            recommendedSongs.add(searchResults.first);
          }
        } catch (e) {
          print("Error searching for recommended song $searchKeyword: $e");
        }
      }

      // Filter out anything that's already in the recently played list (fallback check)
      return recommendedSongs.where((s) => !recentlyPlayedIds.contains(s.id)).toList();
      
    } catch (e) {
      print('Error in AI Recommendation Service: $e');
      return [];
    }
  }
}
