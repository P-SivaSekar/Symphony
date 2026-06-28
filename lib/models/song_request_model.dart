class SongRequest {
  final String id;
  final String songName;
  final String movieName;
  final String requesterName;
  final String requesterEmail;
  final DateTime timestamp;
  final bool isDeleted;

  SongRequest({
    required this.id,
    required this.songName,
    required this.movieName,
    required this.requesterName,
    required this.requesterEmail,
    required this.timestamp,
    this.isDeleted = false,
  });

  factory SongRequest.fromMap(Map<String, dynamic> map, String id) {
    return SongRequest(
      id: id,
      songName: map['songName'] ?? '',
      movieName: map['movieName'] ?? '',
      requesterName: map['requesterName'] ?? 'Unknown',
      requesterEmail: map['requesterEmail'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'songName': songName,
      'movieName': movieName,
      'requesterName': requesterName,
      'requesterEmail': requesterEmail,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }
}
