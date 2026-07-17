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
    if (covers.length >= 4) {
      background = GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: covers.take(4).map((url) => Image.network(url, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))).toList(),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
              background,

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.isTrending)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          widget.playlist.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4.0,
                                color: Colors.black87,
                              ),
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 8.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
