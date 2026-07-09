import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../services/saavn_service.dart';
import '../models/song_model.dart';
import 'playlist_screen.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final bool isTrending;

  const PlaylistCard({super.key, required this.playlist, this.isTrending = false});

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() async {
    // Only load if it's a global/saavn playlist without explicit songIds fetched yet
    // Or if we need covers for it
    if (widget.playlist.creatorId == 'system') {
       // if it's downloaded/liked we might not want to fetch from saavn. But explore lists don't have creatorId system (except all_songs etc, which we don't show here anymore).
    }
    
    try {
      final songs = await SaavnService.fetchPlaylistSongs(widget.playlist.id);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<String> covers = _songs.map((e) => e.coverUrl).where((e) => e.isNotEmpty).take(4).toList();
    if (covers.isEmpty && widget.playlist.coverUrl.isNotEmpty) {
      covers.add(widget.playlist.coverUrl);
    }
    
    Widget background;
    if (covers.length == 4) {
      background = GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: covers.map((url) => Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))).toList(),
      );
    } else if (covers.isNotEmpty) {
      background = Image.network(covers.first, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey));
    } else {
      background = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.isTrending 
                ? [Colors.deepOrange.withValues(alpha: 0.7), Colors.redAccent.withValues(alpha: 0.7)]
                : [Colors.blueAccent.withValues(alpha: 0.6), Colors.purpleAccent.withValues(alpha: 0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
    }

    final songCount = _songs.length;
    
    return GestureDetector(
      onTap: () {
        // If we fetched songs, we can pass them to PlaylistScreen via a new Playlist object or let PlaylistScreen fetch them.
        // Actually PlaylistScreen automatically fetches them if it's a Saavn playlist!
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: widget.playlist)));
      },
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              background,
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.isTrending)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                        ),
                      Text(
                        widget.playlist.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!_isLoading && songCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            '$songCount Songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
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
}
