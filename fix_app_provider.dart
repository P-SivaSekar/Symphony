import 'dart:io';
void main() {
  var file = File('d:/Studies/Projects/Music Player/lib/providers/app_provider.dart');
  var content = file.readAsStringSync();
  var idx1 = content.indexOf('  Future<void> logout() async {');
  var idx2 = content.indexOf('      // Add local fallback playlists');
  if (idx1 != -1 && idx2 != -1) {
    var fixedCode = '''  Future<void> logout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print("Logout error: \$e");
    } finally {
      _user = null;
      _userProfile = null;
      _allSongs = [];
      _trendingSongs = [];
      _globalPlaylists = [];
      _userPlaylists = [];
      _notifications = [];
      _notificationSubscription?.cancel();
      // Keep downloaded songs available offline even if logged out
      notifyListeners();
    }
  }

  void setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String themeStr = 'system';
    if (mode == ThemeMode.light) themeStr = 'light';
    if (mode == ThemeMode.dark) themeStr = 'dark';
    await prefs.setString('theme_mode', themeStr);
  }

  Future<void> fetchPlaylists() async {
    isPlaylistsLoading = true;
    notifyListeners();

    _globalPlaylists = [];
    _userPlaylists = [];

    try {
      final globalSnap = await FirebaseFirestore.instance
          .collection('playlists')
          .where('isGlobal', isEqualTo: true)
          .get();
      _globalPlaylists = globalSnap.docs
          .map((doc) => Playlist.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error fetching global playlists: \$e");
    }

    if (_user != null) {
      try {
        final userSnap = await FirebaseFirestore.instance
            .collection('playlists')
            .where('creatorId', isEqualTo: _user!.uid)
            .get();
        final fetchedUserPlaylists = userSnap.docs
            .map((doc) => Playlist.fromMap(doc.data(), doc.id))
            .toList();
        _userPlaylists = fetchedUserPlaylists.where((p) => !p.isGlobal).toList();
      } catch (e) {
        print("Error fetching user playlists: \$e");
      }

''';
    var newContent = content.substring(0, idx1) + fixedCode + content.substring(idx2);
    file.writeAsStringSync(newContent);
    print('Fixed successfully');
  } else {
    print('Could not find indices: idx1=\$idx1, idx2=\$idx2');
  }
}
