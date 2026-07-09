import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../models/playlist_model.dart';
import '../models/song_request_model.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../services/saavn_service.dart';
import '../models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../main.dart';
class AppProvider extends ChangeNotifier {
  User? _user;
  UserModel? _userProfile;
  List<Song> _trendingSongs = [];
  List<Song> _allSongs = [];
  List<Song> _favoriteSongs = [];
  bool _isLoading = false;
  bool isPlaylistsLoading = false;
  bool _isOtpVerifiedSession = true; // Default true so auto-logins bypass OTP
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  List<Playlist> _globalPlaylists = [];
  List<Playlist> _userPlaylists = [];
  List<Song> _downloadedSongs = [];
  Set<String> _downloadingSongIds = {};
  List<Song> _playHistory = [];

  List<NotificationModel> _notifications = [];
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  // Admin Dashboard State
  int _adminTabIndex = 0;
  Map<String, dynamic>? _selectedRequestForUpload;

  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  List<Song> get trendingSongs => _trendingSongs;
  List<Song> get allSongs => _allSongs;
  List<Song> get favoriteSongs => _favoriteSongs;
  bool get isLoading => _isLoading;
  bool get isProfileSetup => _userProfile != null;
  bool get isOtpVerifiedSession => _isOtpVerifiedSession;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  List<Playlist> get globalPlaylists => _globalPlaylists;
  List<Playlist> get userPlaylists => _userPlaylists;
  List<Song> get downloadedSongs => _downloadedSongs;
  List<Song> get playHistory => _playHistory;
  List<NotificationModel> get notifications => _notifications;
  int get adminTabIndex => _adminTabIndex;
  Map<String, dynamic>? get selectedRequestForUpload => _selectedRequestForUpload;
  bool get isAdmin => _userProfile?.isAdmin == true;

  void setAdminTab(int index, {Map<String, dynamic>? request}) {
    _adminTabIndex = index;
    if (request != null) {
      _selectedRequestForUpload = request;
    }
    notifyListeners();
  }

  void clearSelectedRequest() {
    _selectedRequestForUpload = null;
    notifyListeners();
  }

  int get unreadNotificationCount {
    if (_user == null) return 0;
    return _notifications.where((n) {
      if (n.userId == 'global') {
        return !n.readBy.contains(_user!.uid);
      } else {
        return !n.isRead;
      }
    }).length;
  }

  AppProvider() {
    _loadSettings();
    _loadPlayHistory();
    _initAuth();
    loadDownloadedSongs();
  }

  Future<void> _loadPlayHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('playHistory');
    if (str != null) {
      try {
        final List<dynamic> decoded = jsonDecode(str);
        _playHistory = decoded.map((e) {
          final map = e as Map<String, dynamic>;
          return Song.fromMap(map, map['id']?.toString() ?? '');
        }).toList();
        notifyListeners();
      } catch (e) {
        print("Error loading play history: $e");
      }
    }
  }

  Future<void> addToPlayHistory(Song song) async {
    _playHistory.removeWhere((s) => s.id == song.id);
    _playHistory.insert(0, song);
    if (_playHistory.length > 50) {
      _playHistory = _playHistory.sublist(0, 50);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_playHistory.map((s) {
      final m = s.toMap();
      m['id'] = s.id;
      return m;
    }).toList());
    prefs.setString('playHistory', encoded);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode');
    if (themeStr != null) {
      switch (themeStr) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    } else {
      _themeMode = ThemeMode.system;
    }
    
    
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    notifyListeners();
  }

  void verifyOtpSession() {
    _isOtpVerifiedSession = true;
    notifyListeners();
  }

  void requireOtpSession() {
    _isOtpVerifiedSession = false;
    notifyListeners();
  }

  void _initAuth() {
    if (Firebase.apps.isEmpty) {
      print("Firebase is not initialized.");
      return;
    }
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _user = user;
      notifyListeners();
      if (user != null) {
        await _fetchUserProfile(user.uid);
        fetchSongs();
        fetchPlaylists();
        _startNotificationListener(user.uid);
      } else {
        _userProfile = null;
        _notifications = [];
        _notificationSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void _startNotificationListener(String uid) {
    _notificationSubscription?.cancel();
    List<String> notificationTargets = ['global', uid, FirebaseAuth.instance.currentUser?.email ?? ''];
    if (isAdmin) notificationTargets.add('admin');
    
    bool isFirstLoad = true;
    
    _notificationSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', whereIn: notificationTargets)
        .snapshots()
        .listen(
          (snapshot) {
            final creationTime = FirebaseAuth.instance.currentUser?.metadata.creationTime ?? DateTime(2000);
            
            final previousLength = _notifications.length;
            
            _notifications = snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
                .where((notif) => notif.timestamp.isAfter(creationTime) || notif.timestamp.isAtSameMomentAs(creationTime))
                .where((notif) {
                  if (notif.userId == 'global') {
                    return !notif.readBy.contains(uid);
                  }
                  return !notif.isRead;
                })
                .toList();
            _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            
            // Show system notification for newly added unread notifications
            final hasNewAdded = snapshot.docChanges.any((change) => change.type == DocumentChangeType.added);
            if (!snapshot.metadata.isFromCache && !isFirstLoad && hasNewAdded && _notifications.isNotEmpty) {
              final newNotif = _notifications.first; // highest timestamp
              final isGlobal = newNotif.userId == 'global';
              final isRead = isGlobal ? newNotif.readBy.contains(uid) : newNotif.isRead;
              
              if (!isRead && _notificationsEnabled) {
                try {
                  AndroidNotificationDetails androidPlatformChannelSpecifics =
                      AndroidNotificationDetails('symphony_notifications', 'Symphony Notifications',
                          importance: Importance.max, 
                          priority: Priority.high, 
                          showWhen: true,
                          styleInformation: BigTextStyleInformation(newNotif.message));
                  NotificationDetails platformChannelSpecifics =
                      NotificationDetails(android: androidPlatformChannelSpecifics);
                  
                  flutterLocalNotificationsPlugin.show(
                      id: newNotif.hashCode,
                      title: newNotif.title,
                      body: newNotif.message,
                      notificationDetails: platformChannelSpecifics,
                      payload: newNotif.songId ?? 'item x');
                } catch (e) {
                  print("Local notification error: $e");
                }
              }
            }
            isFirstLoad = false;
            
            notifyListeners();
          },
          onError: (error) {
            print("Error listening to notifications: $error");
          },
        );
  }

  Future<void> markNotificationAsRead(NotificationModel notification) async {
    if (_user == null) return;
    try {
      if (notification.userId == 'global') {
        if (!notification.readBy.contains(_user!.uid)) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(notification.id)
              .update({
                'readBy': FieldValue.arrayUnion([_user!.uid]),
              });
        }
      } else {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(notification.id)
            .delete();
      }
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> clearAllNotifications() async {
    if (_user == null) return;
    final notifsCopy = List<NotificationModel>.from(_notifications);
    for (var notif in notifsCopy) {
      await markNotificationAsRead(notif);
    }
  }

  Future<void> _fetchUserProfile(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userProfile = UserModel.fromMap(doc.data()!, doc.id);

        // Auto-fix legacy ui-avatars URLs that have 2 letters instead of 1
        if (_userProfile!.profilePicUrl.contains('ui-avatars.com')) {
          final firstLetter = _userProfile!.username.isNotEmpty
              ? _userProfile!.username[0].toUpperCase()
              : 'U';
          final correctUrl =
              'https://ui-avatars.com/api/?name=$firstLetter&background=0D8ABC&color=fff&size=256';

          if (_userProfile!.profilePicUrl != correctUrl) {
            _userProfile = UserModel.fromMap({
              ...doc.data()!,
              'profilePicUrl': correctUrl,
            }, doc.id);
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'profilePicUrl': correctUrl});
          }
        }
      } else {
        if (_userProfile == null) {
          _userProfile = null;
        }
      }
      notifyListeners();
    } catch (e) {
      print("Error fetching user profile: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> setupProfile(String username, String profilePicUrl) async {
    if (_user == null) return "User not logged in";
    _isLoading = true;
    notifyListeners();
    try {
      final newUser = UserModel(
        id: _user!.uid,
        email: _user!.email ?? '',
        username: username,
        profilePicUrl: profilePicUrl,
        likedSongs: [],
        isOtpVerified: true,
      );
      print("Setting up profile for UID: ${_user!.uid}");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set(newUser.toMap());
      _userProfile = newUser;
      notifyListeners();
      print("Profile setup successful for ${newUser.username}");
      return null;
    } catch (e) {
      print("Profile setup failed: $e");
      return "Failed to setup profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile(String username, String profilePicUrl) async {
    if (_userProfile == null || _user == null) return "User profile not found";
    _isLoading = true;
    notifyListeners();
    try {
      final updatedUser = UserModel(
        id: _userProfile!.id,
        email: _userProfile!.email,
        username: username,
        profilePicUrl: profilePicUrl,
        likedSongs: _userProfile!.likedSongs,
        isOtpVerified: _userProfile!.isOtpVerified,
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update(updatedUser.toMap());
      _userProfile = updatedUser;
      return null;
    } catch (e) {
      return "Failed to update profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> login(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        return 'Firebase init error: $e';
      }
    }
    _isLoading = true;
    _isOtpVerifiedSession = kIsWeb ? true : false; // Require OTP only on mobile
    notifyListeners();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      _isOtpVerifiedSession = true;
      _isLoading = false;
      notifyListeners();
      return _friendlyAuthError(e.code);
    } catch (e) {
      _isOtpVerifiedSession = true;
      _isLoading = false;
      notifyListeners();
      return 'Login failed: ${e.toString()}';
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> signup(String email, String password) async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        return 'Firebase init error: $e';
      }
    }
    _isLoading = true;
    _isOtpVerifiedSession = kIsWeb ? true : false; // Require OTP only on mobile
    notifyListeners();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return _friendlyAuthError(e.code);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign up failed: ${e.toString()}';
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      // Classic error codes
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'Mail ID is already registered , Try logging in';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      // Firebase Auth v6+ error codes
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'INVALID_PASSWORD':
        return 'Invalid email or password. Please check and try again.';
      case 'channel-error':
        return 'Connection error. Please check your internet and try again.';
      case 'CONFIGURATION_NOT_FOUND':
        return 'Firebase not configured. See SETUP_INSTRUCTIONS.md step 1.';
      case 'operation-not-allowed':
        return 'Email/password auth is disabled. Go to Firebase Console → Authentication → Sign-in method → Enable Email/Password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      // "unknown" on Android = SHA-1 fingerprint not registered in Firebase
      case 'unknown':
        return 'Setup required: Add your app\'s SHA-1 fingerprint to Firebase Console. See SETUP_INSTRUCTIONS.md step 1.4.';
      default:
        print('[AuthError] Unhandled Firebase code: $code');
        return 'Auth error ($code). See SETUP_INSTRUCTIONS.md.';
    }
  }

  Future<void> toggleNotifications() async {
    if (!_notificationsEnabled) {
      // User is turning notifications ON, request permission
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final requestStatus = await Permission.notification.request();
        if (!requestStatus.isGranted) {
          // Keep notifications false if permission is denied
          return;
        }
      }
    }
    _notificationsEnabled = !_notificationsEnabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<String?> loginWithGoogle({required bool isLogin}) async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        return 'Firebase init error: $e';
      }
    }
    _isLoading = true;
    _isOtpVerifiedSession = true; // Auto verify for Google
    notifyListeners();
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Forces account chooser

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null; // User canceled
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isLogin && isNewUser) {
        await userCredential.user?.delete();
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();
        _isLoading = false;
        notifyListeners();
        return 'No account found. Please sign up first.';
      }

      if (!isLogin && !isNewUser) {
        await FirebaseAuth.instance.signOut();
        await googleSignIn.signOut();
        _isLoading = false;
        notifyListeners();
        return 'Account already exists. Please log in instead.';
      }

      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Google sign-in failed: ${e.toString()}';
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

    _userPlaylists = [];

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
            prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
        for (final pJson in localPlaylists) {
          try {
            final pMap = jsonDecode(pJson);
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
      final playlist = Playlist(
        id: docRef.id,
        name: name,
        creatorId: _user!.uid,
        isGlobal: isGlobal,
      );
      try {
        await docRef.set(playlist.toMap());
      } catch (e) {
        print("Firestore permission denied. Saving locally: $e");
        final prefs = await SharedPreferences.getInstance();
        final localPlaylists =
            prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
        localPlaylists.add(json.encode(playlist.toMap()));
        await prefs.setStringList(
          'local_playlists_${_user!.uid}',
          localPlaylists,
        );
      }
      await fetchPlaylists();
      return playlist;
    } catch (e) {
      print("Error creating playlist: $e");
      return null;
    }
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId);
      try {
        await docRef.update({
          'songIds': FieldValue.arrayUnion([songId]),
        });
      } catch (e) {
        print("Firestore update failed. Trying local: $e");
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          final localPlaylists =
              prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
          List<String> updated = [];
          for (final pJson in localPlaylists) {
            final pMap = json.decode(pJson) as Map<String, dynamic>;
            if (pMap['id'] == playlistId) {
              List<String> songs = List<String>.from(pMap['songIds'] ?? []);
              if (!songs.contains(songId)) songs.add(songId);
              pMap['songIds'] = songs;
              updated.add(json.encode(pMap));
            } else {
              updated.add(pJson);
            }
          }
          await prefs.setStringList('local_playlists_${_user!.uid}', updated);
        }
      }
      await fetchPlaylists();
    } catch (e) {
      print("Error adding song to playlist: $e");
    }
  }

  Future<void> addSongsToPlaylist(
    String playlistId,
    List<String> songIds,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId);
      try {
        await docRef.update({'songIds': FieldValue.arrayUnion(songIds)});
      } catch (e) {
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          final localPlaylists =
              prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
          List<String> updated = [];
          for (final pJson in localPlaylists) {
            final pMap = json.decode(pJson) as Map<String, dynamic>;
            if (pMap['id'] == playlistId) {
              List<String> songs = List<String>.from(pMap['songIds'] ?? []);
              for (final id in songIds) {
                if (!songs.contains(id)) songs.add(id);
              }
              pMap['songIds'] = songs;
              updated.add(json.encode(pMap));
            } else {
              updated.add(pJson);
            }
          }
          await prefs.setStringList('local_playlists_${_user!.uid}', updated);
        }
      }
      await fetchPlaylists();
    } catch (e) {
      print("Error adding songs to playlist: $e");
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId);
      try {
        await docRef.update({'name': newName});
      } catch (e) {
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          final localPlaylists =
              prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
          List<String> updated = [];
          for (final pJson in localPlaylists) {
            final pMap = json.decode(pJson) as Map<String, dynamic>;
            if (pMap['id'] == playlistId) {
              pMap['name'] = newName;
              updated.add(json.encode(pMap));
            } else {
              updated.add(pJson);
            }
          }
          await prefs.setStringList('local_playlists_${_user!.uid}', updated);
        }
      }
      await fetchPlaylists();
    } catch (e) {
      print("Error renaming playlist: $e");
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId);
      try {
        await docRef.delete();
      } catch (e) {
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          final localPlaylists =
              prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
          List<String> updated = [];
          for (final pJson in localPlaylists) {
            final pMap = json.decode(pJson) as Map<String, dynamic>;
            if (pMap['id'] != playlistId) {
              updated.add(pJson);
            }
          }
          await prefs.setStringList('local_playlists_${_user!.uid}', updated);
        }
      }
      await fetchPlaylists();
    } catch (e) {
      print("Error deleting playlist: $e");
    }
  }

  Future<void> deletePlaylists(List<String> playlistIds) async {
    for (String id in playlistIds) {
      await deletePlaylist(id);
    }
  }

  Future<void> removeSongsFromPlaylist(
    String playlistId,
    List<String> songIds,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('playlists')
          .doc(playlistId);
      try {
        await docRef.update({'songIds': FieldValue.arrayRemove(songIds)});
      } catch (e) {
        if (_user != null) {
          final prefs = await SharedPreferences.getInstance();
          final localPlaylists =
              prefs.getStringList('local_playlists_${_user!.uid}') ?? [];
          List<String> updated = [];
          for (final pJson in localPlaylists) {
            final pMap = json.decode(pJson) as Map<String, dynamic>;
            if (pMap['id'] == playlistId) {
              List<String> currentSongs = List<String>.from(
                pMap['songIds'] ?? [],
              );
              currentSongs.removeWhere((id) => songIds.contains(id));
              pMap['songIds'] = currentSongs;
              updated.add(json.encode(pMap));
            } else {
              updated.add(pJson);
            }
          }
          await prefs.setStringList('local_playlists_${_user!.uid}', updated);
        }
      }
      await fetchPlaylists();
    } catch (e) {
      print("Error removing songs from playlist: $e");
    }
  }

  Future<void> submitSongRequest(String songName, String movieName) async {
    if (_user == null) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('song_requests')
          .doc();
      final request = SongRequest(
        id: docRef.id,
        songName: songName,
        movieName: movieName,
        requesterName: _userProfile?.username ?? 'Listener',
        requesterEmail: _user!.email ?? 'unknown',
        timestamp: DateTime.now(),
      );
      try {
        await docRef.set(request.toMap());
        
        // Add an app notification for admins
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': 'admin',
          'title': 'New Song Request',
          'message': '${request.requesterName} has requested "$songName".',
          'songId': 'song_requests',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isRead': false,
          'readBy': [],
        });
      } catch (e) {
        print(
          "Firestore write denied (needs rule update), but continuing for email: $e",
        );
      }
    } catch (e) {
      print("Error submitting song request: $e");
      throw e;
    }
  }

  Future<void> fetchSongs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final homeData = await SaavnService.fetchTamilHomeData();
      _trendingSongs = List<Song>.from(homeData['trending'] as List? ?? []);
      
      // Update global playlists with Saavn playlists
      _globalPlaylists = List<Playlist>.from(homeData['playlists'] as List? ?? []);
      
      // Clear legacy allSongs since we fetch on demand
      _allSongs = [];
    } catch (e) {
      print("Error fetching songs from Saavn: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void shuffleTrendingSongs() {
    _trendingSongs.shuffle();
    notifyListeners();
  }

  Future<Song> resolveSongNow(Song song) async {
    // If it's a local file or already resolved, return it
    if (song.audioUrl.isNotEmpty && 
        (song.audioUrl.startsWith('file://') || song.audioUrl.startsWith('http'))) {
      return song;
    }

    try {
      final audioUrl = await SaavnService.getAudioUrl(song.id);
      if (audioUrl != null && audioUrl.isNotEmpty) {
        final resolvedSong = song.copyWith(audioUrl: audioUrl);
        
        // Update in memory if it exists in trending
        final index = _trendingSongs.indexWhere((s) => s.id == song.id);
        if (index != -1) {
          _trendingSongs[index] = resolvedSong;
        }

        return resolvedSong;
      }
    } catch (e) {
      print("Error resolving song now: $e");
    }
    return song;
  }

  Future<void> toggleFavorite(Song song) async {
    if (_userProfile == null || _user == null) return;

    final isLiked = _userProfile!.likedSongs.contains(song.id);
    List<String> newLikedSongs = List.from(_userProfile!.likedSongs);

    if (isLiked) {
      newLikedSongs.remove(song.id);
    } else {
      newLikedSongs.add(song.id);
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'likedSongs': newLikedSongs});
      _userProfile = UserModel(
        id: _userProfile!.id,
        email: _userProfile!.email,
        username: _userProfile!.username,
        profilePicUrl: _userProfile!.profilePicUrl,
        likedSongs: newLikedSongs,
      );
      notifyListeners();
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  bool isSongLiked(Song song) {
    if (_userProfile == null) return false;
    return _userProfile!.likedSongs.contains(song.id);
  }

  // --- Downloads Functionality ---

  Future<void> loadDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('downloaded_songs')) {
      try {
        final jsonList = jsonDecode(prefs.getString('downloaded_songs')!) as List;
        _downloadedSongs =
            jsonList
            .map((e) => Song.fromMap(e, e['id']))
            .toList();

        // Ensure the downloaded files actually exist (only on mobile)
        if (!kIsWeb) {
          final List<Song> verifiedSongs = [];
          for (var song in _downloadedSongs) {
            if (song.audioUrl.startsWith('file://')) {
              final path = song.audioUrl.replaceFirst('file://', '');
              if (await File(path).exists()) {
                verifiedSongs.add(song);
              }
            }
          }
          _downloadedSongs = verifiedSongs;
        }

        notifyListeners();
      } catch (e) {
        print("Error loading downloaded songs: $e");
      }
    }
  }

  Future<void> _saveDownloadedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final String songsJson = json.encode(
      _downloadedSongs.map((s) {
        final map = s.toMap();
        map['id'] = s.id; // Include id in map for persistence
        return map;
      }).toList(),
    );
    await prefs.setString('downloaded_songs', songsJson);
  }

  bool isSongDownloaded(String id) {
    return _downloadedSongs.any((s) => s.id == id);
  }

  bool isSongDownloading(String id) {
    return _downloadingSongIds.contains(id);
  }

  Future<void> downloadSong(Song song) async {
    if (kIsWeb) {
      print("Downloading not supported on web yet.");
      return;
    }
    if (_downloadedSongs.any((s) => s.id == song.id)) return;
    if (_downloadingSongIds.contains(song.id)) return;

    _downloadingSongIds.add(song.id);
    notifyListeners();

    try {
      final resolvedSong = await resolveSongNow(song);

      final dir = await getApplicationDocumentsDirectory();
      final File audioFile = File('${dir.path}/${resolvedSong.id}.mp3');
      final File coverFile = File('${dir.path}/${resolvedSong.id}_cover.jpg');

      String urlStr = resolvedSong.audioUrl;
      if (urlStr.startsWith('http://')) {
        urlStr = urlStr.replaceFirst('http://', 'https://');
      }

      final request = http.Request('GET', Uri.parse(urlStr));
      request.headers['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
      request.headers['Referer'] = 'https://www.jiosaavn.com/';
      final streamedResponse = await http.Client().send(request);
      
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 206) {
        final sink = audioFile.openWrite();
        await streamedResponse.stream.pipe(sink);
        await sink.close();

        // Download cover image
        if (resolvedSong.coverUrl.isNotEmpty && !resolvedSong.coverUrl.startsWith('asset:')) {
           try {
             final coverResponse = await http.get(
               Uri.parse(resolvedSong.coverUrl),
               headers: const {
                 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                 'Referer': 'https://www.jiosaavn.com/',
               },
             );
             if (coverResponse.statusCode == 200) {
               await coverFile.writeAsBytes(coverResponse.bodyBytes);
             }
           } catch(e) {
             print("Error downloading cover for ${resolvedSong.title}: $e");
           }
        }

        final downloadedSong = resolvedSong.copyWith(
          audioUrl: 'file://${audioFile.path}',
          coverUrl: await coverFile.exists() ? 'file://${coverFile.path}' : resolvedSong.coverUrl,
        );

        _downloadedSongs.insert(0, downloadedSong);
        await _saveDownloadedSongs();
        print("Download complete for ${resolvedSong.title}");
      } else {
        print("Download failed with status: ${streamedResponse.statusCode}");
      }
    } catch (e) {
      print("Error downloading song ${song.id}: $e");
    } finally {
      _downloadingSongIds.remove(song.id);
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedSong(String id) async {
    final index = _downloadedSongs.indexWhere((s) => s.id == id);
    if (index != -1) {
      final song = _downloadedSongs[index];
      if (!kIsWeb && song.audioUrl.startsWith('file://')) {
        final path = song.audioUrl.replaceFirst('file://', '');
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      _downloadedSongs.removeAt(index);
      await _saveDownloadedSongs();
      notifyListeners();
    }
  }

  // Cover fixing state
  int fixCoversTotal = 0;
  int fixCoversCurrent = 0;
  String fixCoversStatus = '';
  bool isFixingCovers = false;

  Future<void> fixAllCoversNative() async {
    if (isFixingCovers) return;
    
    isFixingCovers = true;
    fixCoversTotal = _allSongs.length;
    fixCoversCurrent = 0;
    fixCoversStatus = 'Starting...';
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('songs').get();
      final docs = querySnapshot.docs;
      
      for (var i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final artist = data['artist'] as String? ?? '';
        
        fixCoversCurrent = i + 1;
        fixCoversStatus = 'Processing: $title';
        notifyListeners();

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

        Future<String?> searchJioSaavn(String query) async {
          try {
            final encodedQuery = Uri.encodeComponent(query);
            final url = 'https://www.jiosaavn.com/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0&n=5&p=1&q=$encodedQuery&__call=search.getResults';
            final response = await http.get(Uri.parse(url));
            if (response.statusCode == 200) {
              final respData = jsonDecode(response.body);
              if (respData != null && respData['results'] != null && (respData['results'] as List).isNotEmpty) {
                final firstResult = respData['results'][0];
                String image = firstResult['image'] as String? ?? '';
                if (image.isNotEmpty) {
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

        newCoverUrl = await searchJioSaavn(searchTerm);
        if (newCoverUrl == null) {
          newCoverUrl = await searchJioSaavn('$title Tamil');
        }
        if (newCoverUrl == null) {
          newCoverUrl = await searchJioSaavn(title);
        }

        if (newCoverUrl != null) {
          final currentCoverUrl = data['coverUrl'] as String? ?? '';
          if (currentCoverUrl != newCoverUrl) {
            await doc.reference.update({'coverUrl': newCoverUrl});
            print("Updated '$title' to $newCoverUrl");
          }
        }
        
        await Future.delayed(const Duration(milliseconds: 200));
      }
      fixCoversStatus = 'Finished!';
    } catch (e) {
      fixCoversStatus = 'Error: $e';
    } finally {
      isFixingCovers = false;
      notifyListeners();
    }
  }
}

