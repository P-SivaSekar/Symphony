import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import '../utils/constants.dart';
import 'glassmorphic_component.dart';
import 'notification_screen.dart';
import 'playlist_screen.dart';
import 'all_playlists_screen.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'profile_screen.dart';
import '../utils/play_helper.dart';
import '../services/saavn_service.dart';
import 'playlist_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({super.key, this.onNavigateToProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showcaseVisible = true;
  List<Song> _forYouSongs = [];
  bool _hasGeneratedForYou = false;
  List<Song> _listenAgainSongs = [];
  bool _hasGeneratedListenAgain = false;
  List<Playlist> _cachedExploreList = [];
  bool _hasGeneratedExplore = false;

  void _generateForYouSongs(List<Song> sourceSongs) {
    if (sourceSongs.isEmpty || _hasGeneratedForYou) return;
    final shuffled = List<Song>.from(sourceSongs)..shuffle();
    _forYouSongs = shuffled.take(50).toList();
    _hasGeneratedForYou = true;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(_pulseController);

    _checkShowcase();
  }

  Future<void> _checkShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('has_seen_song_request_showcase') ?? false;
    if (!hasSeen) {
      setState(() {
        _showcaseVisible = true;
      });
    }
  }

  void _dismissShowcase() async {
    if (_showcaseVisible) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_song_request_showcase', true);
      setState(() {
        _showcaseVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendSongRequestEmail(String songName, String movieName) async {
    final user = Provider.of<AppProvider>(context, listen: false).userProfile;
    String adminUser = AppConstants.adminEmail;
    String adminPass = AppConstants.adminAppPassword;
    final smtpServer = gmail(adminUser, adminPass);

    final message = Message()
      ..from = Address(adminUser, 'Symphony App')
      ..recipients.add(adminUser)
      ..subject = 'New Song Request - Symphony App'
      ..html = '''
        <h3>New Song Request!</h3>
        <p><strong>User:</strong> ${user?.username ?? 'Unknown'}</p>
        <p><strong>Song:</strong> $songName</p>
        <p><strong>Movie/Album:</strong> $movieName</p>
      ''';

    try {
      await send(message, smtpServer);
    } catch (e) {
      print("Email Error: Error 535: Google App Password Revoked. Contact Admin.");
    }
  }

  void _showSongRequestDialog() {
    _dismissShowcase();
    String songName = '';
    String movieName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: const Text('Request a Song'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Song Name'),
                onChanged: (v) => songName = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Movie / Album (Optional)'),
                onChanged: (v) => movieName = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ElevatedButton(
              onPressed: () async {
                if (songName.trim().isNotEmpty) {
                  final provider = Provider.of<AppProvider>(context, listen: false);
                  await provider.submitSongRequest(songName.trim(), movieName.trim());
                  _sendSongRequestEmail(songName.trim(), movieName.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song requested successfully!')),
                  );
                }
              },
              child: const Text('Submit'),
            )      ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playerService = Provider.of<PlayerService>(context);

    if (!_hasGeneratedForYou && appProvider.trendingSongs.isNotEmpty) {
      _generateForYouSongs(appProvider.trendingSongs);
    }

    if (!_hasGeneratedListenAgain && appProvider.playHistory.isNotEmpty) {
      _listenAgainSongs = List.from(appProvider.playHistory)..shuffle();
      _hasGeneratedListenAgain = true;
    }

    if (!_hasGeneratedExplore && appProvider.globalPlaylists.isNotEmpty) {
      Playlist? trendingPlaylist;
      try {
        trendingPlaylist = appProvider.globalPlaylists.firstWhere((p) => p.name.toLowerCase().contains('trending'));
      } catch (e) {
        trendingPlaylist = null;
      }
      final otherGlobal = appProvider.globalPlaylists.where((p) => !p.name.toLowerCase().contains('trending')).toList();
      _cachedExploreList = [];
      if (trendingPlaylist != null) _cachedExploreList.add(trendingPlaylist);
      _cachedExploreList.addAll(otherGlobal);
      _cachedExploreList.shuffle();
      _hasGeneratedExplore = true;
    }

    List<dynamic> mergedPlaylists = [];

    Playlist? trendingPlaylist;
    List<Playlist> otherGlobal = [];
    for (var p in appProvider.globalPlaylists) {
      if (p.name.toLowerCase().contains('trending')) {
        trendingPlaylist = p;
      } else {
        otherGlobal.add(p);
      }
    }
    if (trendingPlaylist != null) {
      mergedPlaylists.add(trendingPlaylist);
    }
    mergedPlaylists.addAll(otherGlobal);
    mergedPlaylists.addAll(appProvider.userPlaylists);
    mergedPlaylists.add('CREATE_PLAYLIST');

    if (appProvider.isLoading || appProvider.isPlaylistsLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await appProvider.fetchSongs();
            setState(() {
              _hasGeneratedForYou = false;
            });
            // Manually refresh the data
            appProvider.fetchSongs();
            appProvider.fetchPlaylists();
            if (appProvider.playHistory.isNotEmpty) {
              setState(() {
                _listenAgainSongs = List.from(appProvider.playHistory)..shuffle();
              });
            }
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              title: const Text(
                'Symphony',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_showcaseVisible)
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.music_note),
                      onPressed: _showSongRequestDialog,
                      tooltip: 'Request Song',
                    ),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                      },
                    ),
                    if (appProvider.unreadNotificationCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${appProvider.unreadNotificationCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: appProvider.userProfile?.profilePicUrl.isNotEmpty == true
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(appProvider.userProfile!.profilePicUrl),
                          backgroundColor: Colors.transparent,
                        )
                      : const Icon(Icons.person_outline),
                  onPressed: widget.onNavigateToProfile ?? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Greeting & Vibe Chips
                    Builder(
                      builder: (context) {
                        var hour = DateTime.now().hour;
                        String greetingTime = 'Good Evening';
                        if (hour < 12) greetingTime = 'Good Morning';
                        else if (hour < 17) greetingTime = 'Good Afternoon';
                        final username = appProvider.userProfile?.username.split(' ')[0] ?? 'User';
                        return Text(
                          '$greetingTime, $username!',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        );
                      }
                    ),
                    const SizedBox(height: 24),

                    // For You (3x3 Grid)
                    if (_forYouSongs.isNotEmpty) ...[
                      const Text(
                        'For You',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _forYouSongs.length > 9 ? 9 : _forYouSongs.length,
                        itemBuilder: (context, index) {
                          final song = _forYouSongs[index];
                          return GestureDetector(
                            onTap: () => playAndOpenPlayer(context, [song], 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      song.coverUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // New Tamil Releases & BGMs
                    if (appProvider.newReleases.isNotEmpty) ...[
                      const Text(
                        'New Tamil Releases & BGMs',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: appProvider.newReleases.length > 20 ? 20 : appProvider.newReleases.length,
                          itemBuilder: (context, index) {
                            final song = appProvider.newReleases[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => playAndOpenPlayer(context, [song], 0),
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          song.coverUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        song.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Listen Again (Horizontal)
                    if (_listenAgainSongs.isNotEmpty) ...[
                      const Text(
                        'Listen Again',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _listenAgainSongs.length > 20 ? 20 : _listenAgainSongs.length,
                          itemBuilder: (context, index) {
                            final song = _listenAgainSongs[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => playAndOpenPlayer(context, [song], 0),
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          song.coverUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        song.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],



                    // Explore Playlists (Global Saavn Playlists)
                    if (_cachedExploreList.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Explore',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPlaylistsScreen(isExplore: true)));
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140, // 1:1 aspect ratio based on width 140
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cachedExploreList.length,
                          itemBuilder: (context, index) {
                            final playlist = _cachedExploreList[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: 140,
                                child: PlaylistCard(
                                  playlist: playlist,
                                  isTrending: playlist.name.toLowerCase().contains('trending'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 100), // padding for bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSongCard(Song song, PlayerService playerService, List<Song> queue, int index) {
    return GestureDetector(
      onTap: () => playAndOpenPlayer(context, queue, index),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Hero(
                  tag: 'trending_cover_${song.id}_$index',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      song.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePlaylistCard(AppProvider appProvider) {
    return GestureDetector(
      onTap: () {
        _showCreatePlaylistDialog(appProvider);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: GlassContainer(
          borderRadius: 16,
          padding: EdgeInsets.zero,
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.onSurface, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Create\nPlaylist',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(AppProvider appProvider) {
    String playlistName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Playlist Name'),
            onChanged: (val) => playlistName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ElevatedButton(
              onPressed: () async {
                if (playlistName.trim().isNotEmpty) {
                  await appProvider.createPlaylist(playlistName.trim(), isGlobal: false);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            )      ),
          ],
        );
      },
    );
  }

  Widget _buildGridSongCard(Song song, PlayerService playerService, List<Song> queue, int index) {
    return GestureDetector(
      onTap: () => playAndOpenPlayer(context, queue, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              song.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song.artist,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

