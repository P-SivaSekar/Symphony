class UserModel {
  final String id;
  final String email;
  final String username;
  final String profilePicUrl;
  final List<String> likedSongs;
  final bool isOtpVerified;
  final bool isAdmin;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.profilePicUrl,
    required this.likedSongs,
    this.isOtpVerified = true,
    this.isAdmin = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      profilePicUrl: map['profilePicUrl'] ?? '',
      likedSongs: List<String>.from(map['likedSongs'] ?? []),
      isOtpVerified:
          map['isOtpVerified'] ??
          true, // defaults to true for backwards compatibility
      isAdmin: map['isAdmin'] == true || map['email'] == 'psivasekar1@gmail.com',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'profilePicUrl': profilePicUrl,
      'likedSongs': likedSongs,
      'isOtpVerified': isOtpVerified,
      'isAdmin': isAdmin,
    };
  }
}
