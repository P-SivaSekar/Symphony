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

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const HomeScreen({super.key, this.onNavigateToProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showcaseVisible = false;
  List<Song> _forYouSongs = [];
  bool _hasGeneratedForYou = false;

  void _generateForYouSongs(List<Song> allSongs) {
    if (allSongs.isEmpty || _hasGeneratedForYou) return;
    final shuffled = List<Song>.from(allSongs)..shuffle();
    _forYouSongs = shuffled.take(9).toList();
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

    if (!_hasGeneratedForYou && appProvider.allSongs.isNotEmpty) {
      _generateForYouSongs(appProvider.allSongs);
    }

    List<Song> recentlyAdded = List.from(appProvider.allSongs);
    // Assuming songs added recently are at the end, reverse it for "Recently Added"
    recentlyAdded = recentlyAdded.reversed.toList();

    List<dynamic> mergedPlaylists = [];
    mergedPlaylists.add(Playlist(id: 'all_songs', name: 'All Songs', creatorId: 'system', songIds: appProvider.allSongs.map((s) => s.id).toList()));

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
            setState(() {
              _hasGeneratedForYou = false;
            });
            await Future.delayed(const Duration(milliseconds: 500));
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
                  icon: const Icon(Icons.person_outline),
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
                    if (appProvider.trendingSongs.isNotEmpty) ...[
                      const Text(
                        'Trending Now',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: appProvider.trendingSongs.length,
                          itemBuilder: (context, index) {
                            final song = appProvider.trendingSongs[index];
                            return _buildSongCard(song, playerService, appProvider.trendingSongs, index);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (mergedPlaylists.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Playlists',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllPlaylistsScreen()));
                            },
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: mergedPlaylists.length,
                          itemBuilder: (context, index) {
                            final item = mergedPlaylists[index];
                            if (item == 'CREATE_PLAYLIST') {
                              return _buildCreatePlaylistCard(appProvider);
                            }
                            return _buildPlaylistCard(item as Playlist);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_forYouSongs.isNotEmpty) ...[
                      const Text(
                        'For You',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 150,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _forYouSongs.length,
                            itemBuilder: (context, index) {
                              final song = _forYouSongs[index];
                              return _buildGridSongCard(song, playerService, _forYouSongs, index);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (recentlyAdded.isNotEmpty) ...[
                      const Text(
                        'Recently Added',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentlyAdded.length > 10 ? 10 : recentlyAdded.length,
                        itemBuilder: (context, index) {
                          final song = recentlyAdded[index];
                          return GlassContainer(
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  song.coverUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey),
                                ),
                              ),
                              title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () {
                                playAndOpenPlayer(context, recentlyAdded, index);
                              },
                            ),
                          );
                        },
                      ),
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
                  tag: 'cover_${song.id}',
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

  Widget _buildPlaylistCard(Playlist playlist) {
    bool isTrending = playlist.name.toLowerCase().contains('trending');
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: playlist)));
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
              gradient: LinearGradient(
                colors: isTrending 
                    ? [Colors.deepOrange.withValues(alpha: 0.7), Colors.redAccent.withValues(alpha: 0.7)]
                    : Theme.of(context).brightness == Brightness.dark ? [Colors.white24, Colors.white12] : [Colors.blueAccent.withValues(alpha: 0.6), Colors.purpleAccent.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTrending ? Icons.local_fire_department : Icons.queue_music,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    playlist.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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

