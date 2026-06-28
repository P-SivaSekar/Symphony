const fs = require('fs');

const path = 'd:/Studies/Projects/Music Player/lib/providers/app_provider.dart';
let content = fs.readFileSync(path, 'utf8');

// Find the start of the broken part:
// `      default:\n        print('[AuthError] Unhandled Firebase code: $code');\n        return 'Auth error ($code). See SETUP_INSTRUCTIONS.md.';\n    }`
const searchStart = `      default:
        print('[AuthError] Unhandled Firebase code: $code');
        return 'Auth error ($code). See SETUP_INSTRUCTIONS.md.';
    }`;

const searchEnd = `      final docRef = FirebaseFirestore.instance.collection('playlists').doc();
      final playlist = Playlist(`;

const idx1 = content.indexOf(searchStart);
const idx2 = content.indexOf(searchEnd);

if (idx1 !== -1 && idx2 !== -1) {
  const correctBlock = `      default:
        print('[AuthError] Unhandled Firebase code: $code');
        return 'Auth error ($code). See SETUP_INSTRUCTIONS.md.';
    }
  }

  Future<void> logout() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      print("Logout error: $e");
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
      print("Error fetching global playlists: $e");
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
        print("Error fetching user playlists: $e");
      }

      // Add local fallback playlists
      try {
        final prefs = await SharedPreferences.getInstance();
        final localPlaylists =
            prefs.getStringList('local_playlists_\${_user!.uid}') ?? [];
        for (final pJson in localPlaylists) {
          try {
            final pMap = JSON.parse(pJson);
            _userPlaylists.add(Playlist.fromMap(pMap, pMap['id']));
          } catch (_) {}
        }
      } catch (e) {
        print("Error reading local playlists: $e");
      }
    }
    isPlaylistsLoading = false;
    notifyListeners();
  }

  Future<Playlist?> createPlaylist(String name, {bool isGlobal = false}) async {
    if (_user == null) return null;
    try {
      final docRef = FirebaseFirestore.instance.collection('playlists').doc();
      final playlist = Playlist(`;

  const newContent = content.substring(0, idx1) + correctBlock + content.substring(idx2 + searchEnd.length);
  fs.writeFileSync(path, newContent, 'utf8');
  console.log("Successfully restored app_provider.dart");
} else {
  console.log("Could not find markers. idx1: " + idx1 + ", idx2: " + idx2);
}
