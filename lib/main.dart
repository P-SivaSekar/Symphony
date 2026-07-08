import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';

import 'providers/app_provider.dart';
import 'services/player_service.dart';
import 'services/update_service.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';
import 'ui/search_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/player_screen.dart';
import 'ui/yt_music_player.dart';
import 'ui/glassmorphic_component.dart';
import 'ui/admin_screen.dart';
import 'ui/profile_setup_screen.dart';
import 'ui/otp_screen.dart';
import 'ui/admin_dashboard_screen.dart';
import 'ui/playlist_screen.dart';
import 'ui/global_background.dart';
import 'ui/intro_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final ValueNotifier<String?> pendingSongPlayNotifier = ValueNotifier<String?>(null);
final ValueNotifier<int?> pendingAdminTabNotifier = ValueNotifier<int?>(null);

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == 'background_notification_fetch') {
        if (!kIsWeb) {
          try {
            await Firebase.initializeApp();
          } catch (e) {
            print("Firebase background initialization error: $e");
          }
        }
        
        final appProvider = AppProvider();
        // Background notification fetch is handled by firestore snapshot listeners when app is open, 
        // or through FCM for background. This periodic task can be expanded later if needed.
      }
    } catch (e) {
      print("Background task error: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      final modes = await FlutterDisplayMode.supported;
      if (modes.isNotEmpty) {
        final sorted = List<DisplayMode>.from(modes)
          ..sort((a, b) => b.refreshRate.compareTo(a.refreshRate));
        await FlutterDisplayMode.setPreferredMode(sorted.first);
      }
    } catch (e) {
      print("Error setting high refresh rate: $e");
    }
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else if (defaultTargetPlatform != TargetPlatform.windows) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    print("Firebase initialization error: $e");
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      try {
        await Firebase.initializeApp();
      } catch (e2) {
        print("Firebase fallback initialization error: $e2");
      }
    }
  }

  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
    
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  
    Workmanager().registerPeriodicTask(
      "1",
      "background_notification_fetch",
      frequency: const Duration(minutes: 15),
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload != 'item x') {
          if (response.payload == 'song_requests') {
            pendingAdminTabNotifier.value = 2;
          } else {
            pendingSongPlayNotifier.value = response.payload;
          }
        }
      },
    );

    final NotificationAppLaunchDetails? notificationAppLaunchDetails = 
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null && payload != 'item x') {
        if (payload == 'song_requests') {
          pendingAdminTabNotifier.value = 2;
        } else {
          pendingSongPlayNotifier.value = payload;
        }
      }
    }
  }

  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.symphony.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    );
  } catch (e) {
    print("JustAudioBackground init error: $e");
  }

  // Request notification permissions
  try {
    await Permission.notification.request();
  } catch (e) {
    print("Notification permission error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => PlayerService()),
      ],
      child: const SymphonyApp(),
    ),
  );
}

class SymphonyApp extends StatelessWidget {
  const SymphonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return MaterialApp(
      title: 'Symphony',
      debugShowCheckedModeBanner: false,
      themeMode: appProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: Colors.cyan.shade700,
          surface: Colors.grey.shade100,
          onSurface: Colors.black87,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthenticationWrapper(),
      routes: {
        '/admin': (context) => const AdminScreen(),
        '/player': (context) => PlayerScreen(),
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool? _hasSeenIntro;

  @override
  void initState() {
    super.initState();
    _checkIntro();
    pendingSongPlayNotifier.addListener(_onPendingSongPlay);
    pendingAdminTabNotifier.addListener(_onPendingAdminTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkVersion(context);
    });
  }

  Future<void> _checkIntro() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasSeenIntro = prefs.getBool('has_seen_intro_v1_1') ?? false;
    });
  }

  @override
  void dispose() {
    pendingSongPlayNotifier.removeListener(_onPendingSongPlay);
    pendingAdminTabNotifier.removeListener(_onPendingAdminTab);
    super.dispose();
  }

  void _onPendingAdminTab() {
    final tabIndex = pendingAdminTabNotifier.value;
    if (tabIndex != null) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      if (appProvider.isAdmin) {
        appProvider.setAdminTab(tabIndex);
      }
      pendingAdminTabNotifier.value = null; // Reset
    }
  }

  void _onPendingSongPlay() {
    final songId = pendingSongPlayNotifier.value;
    if (songId != null) {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final playerService = Provider.of<PlayerService>(context, listen: false);
      
      final songIndex = appProvider.allSongs.indexWhere((s) => s.id == songId);
      if (songIndex != -1) {
        playerService.loadPlaylist(appProvider.allSongs, initialIndex: songIndex);
      }
      pendingSongPlayNotifier.value = null; // Reset
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final appProviderNonListening = Provider.of<AppProvider>(context, listen: false);
    playerService.onQueueEmpty ??= ({bool forcePlay = false}) {
      playerService.consumeAutoplay(appProviderNonListening.allSongs, forcePlay: forcePlay);
    };

    if (_hasSeenIntro == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }
    
    if (!_hasSeenIntro!) {
      return const IntroScreen();
    }

    final appProvider = Provider.of<AppProvider>(context);

    if (appProvider.user != null) {
      if (appProvider.isLoading && !appProvider.isProfileSetup) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        );
      }
      if (!appProvider.isOtpVerifiedSession) {
        return const OtpScreen();
      }
      if (!appProvider.isProfileSetup) {
        return const ProfileSetupScreen();
      }
      // Admin users get the admin dashboard
      if (appProvider.isAdmin) {
        return const AdminDashboardScreen();
      }
      return const MainScreen();
    } else {
      return const AuthScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey bottomMenuKey = GlobalKey();
  int _currentIndex = 0;
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    playerService.onQueueEmpty ??= ({bool forcePlay = false}) {
      playerService.consumeAutoplay(appProvider.allSongs, forcePlay: forcePlay);
    };
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = results.contains(ConnectivityResult.none);
    });
    
    if (_isOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        await appProvider.loadDownloadedSongs(); // Ensure it's loaded before checking
        
        if (!kIsWeb && appProvider.downloadedSongs.isNotEmpty) {
           final downloadedPlaylist = {
             'name': 'Downloads',
             'songs': appProvider.downloadedSongs,
           };

           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (_) => PlaylistScreen(
                 playlist: downloadedPlaylist,
               ),
             ),
           );
        }
      });
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Ensure the autoplay queue is pre-populated whenever the UI builds
    if (playerService.autoplayEnabled && playerService.autoplayQueue.isEmpty && appProvider.allSongs.isNotEmpty) {
      Future.microtask(() => playerService.populateAutoplayQueue(appProvider.allSongs));
    }

    if (playerService.onQueueEmpty == null) {
      playerService.onQueueEmpty = ({bool forcePlay = false}) {
        if (playerService.autoplayEnabled && appProvider.allSongs.isNotEmpty) {
          playerService.consumeAutoplay(appProvider.allSongs, forcePlay: forcePlay);
        }
      };
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Global Vibrant Background
        const GlobalBackground(),
        WillPopScope(
          onWillPop: () async {
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
              return false;
            }
            return true; // Allow app to close if already on home tab
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF121212) : Colors.white,
            extendBody: true,
            body: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(
                  onNavigateToProfile: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                ),
                SearchScreen(isActive: _currentIndex == 1),
                const ProfileScreen(),
              ],
            ),
            bottomNavigationBar: GlassContainer(
              key: bottomMenuKey,
              borderRadius: 0,
              blurSigmaX: 20,
              blurSigmaY: 20,
              blurColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.85) 
                  : Colors.white.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: (playerService.playlist.isNotEmpty && playerService.currentSong != null) 
                      ? Colors.transparent 
                      : (Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black.withOpacity(0.08)),
                  width: 0.5,
                ),
              ),
              
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Theme.of(context).colorScheme.primary,
                  unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                    BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (playerService.playlist.isNotEmpty && playerService.currentSong != null) 
          YTMusicPlayer(hasBottomNav: true, bottomMenuKey: bottomMenuKey)
        else if (_isOffline)
          Positioned(
            bottom: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: () {
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                if (!kIsWeb && appProvider.downloadedSongs.isNotEmpty) {
                   final downloadedPlaylist = {
                     'name': 'Downloads',
                     'songs': appProvider.downloadedSongs,
                   };
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => PlaylistScreen(
                         playlist: downloadedPlaylist,
                       ),
                     ),
                   );
                }
              },
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.cloud_off, color: Colors.white70, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Offline. Tap to view downloads.",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
