class Playlist {
  final String id;
  final String name;
  final String creatorId; // User ID who created it, or 'admin' for global
  final bool isGlobal; // If true, visible to everyone
  final List<String> songIds;
  final String coverUrl;

  Playlist({
    required this.id,
    required this.name,
    required this.creatorId,
    this.isGlobal = false,
    this.songIds = const [],
    this.coverUrl = '',
  });

  factory Playlist.fromMap(Map<String, dynamic> map, String id) {
    return Playlist(
      id: id,
      name: map['name'] ?? 'Unknown Playlist',
      creatorId: map['creatorId'] ?? '',
      isGlobal: map['isGlobal'] ?? false,
      songIds: List<String>.from(map['songIds'] ?? []),
      coverUrl: map['coverUrl'] ?? '',
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
    };
  }
}
