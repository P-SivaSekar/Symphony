import 'song_model.dart';

class Playlist {
  final String id;
  final String name;
  final String creatorId; // User ID who created it, or 'admin' for global
  final bool isGlobal; // If true, visible to everyone
  final List<String> songIds;
  final String coverUrl;
  final String description;
  final List<Song> songs; // Stores actual songs for Saavn playlists

  Playlist({
    required this.id,
    required this.name,
    this.creatorId = 'saavn',
    this.isGlobal = true,
    this.songIds = const [],
    this.coverUrl = '',
    this.description = '',
    this.songs = const [],
  });

  factory Playlist.fromMap(Map<String, dynamic> map, String id) {
    return Playlist(
      id: id,
      name: map['name'] ?? 'Unknown Playlist',
      creatorId: map['creatorId'] ?? '',
      isGlobal: map['isGlobal'] ?? false,
      songIds: List<String>.from(map['songIds'] ?? []),
      coverUrl: map['coverUrl'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'isGlobal': isGlobal,
      'songIds': songIds,
      'coverUrl': coverUrl,
      'description': description,
    };
  }
}
