class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final bool isTrending;
  final bool isAutoplay;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    this.isTrending = false,
    this.isAutoplay = false,
  });

  factory Song.fromMap(Map<String, dynamic> data, String documentId) {
    return Song(
      id: documentId,
      title: data['title'] ?? 'Unknown Title',
      artist: data['artist'] ?? 'Unknown Artist',
      coverUrl: (data['coverUrl'] as String?)?.trim() ?? '',
      audioUrl: (data['audioUrl'] as String?)?.trim() ?? '',
      isTrending: data['isTrending'] ?? false,
      isAutoplay: data['isAutoplay'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'audioUrl': audioUrl,
      'isTrending': isTrending,
      'isAutoplay': isAutoplay,
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? coverUrl,
    String? audioUrl,
    bool? isTrending,
    bool? isAutoplay,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      isTrending: isTrending ?? this.isTrending,
      isAutoplay: isAutoplay ?? this.isAutoplay,
    );
  }
}
