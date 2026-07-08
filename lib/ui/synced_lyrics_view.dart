import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_model.dart';
import '../services/player_service.dart';
import '../utils/lyrics_parser.dart';
import '../utils/lyrics_data.dart';

class SyncedLyricsView extends StatefulWidget {
  final Song song;
  const SyncedLyricsView({super.key, required this.song});

  @override
  State<SyncedLyricsView> createState() => _SyncedLyricsViewState();
}

class _SyncedLyricsViewState extends State<SyncedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  List<LyricLine> _lyrics = [];
  int _activeIndex = -1;
  bool _userScrolling = false;
  Timer? _userScrollTimer;
  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    _subscribeToPosition();
  }

  @override
  void didUpdateWidget(covariant SyncedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song.id != oldWidget.song.id) {
      _fetchLyrics();
      _activeIndex = -1;
      _scrollToActive(0, force: true);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    _userScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    final songId = widget.song.id;
    final title = widget.song.title;
    final artist = widget.song.artist;
    
    // Fast path: check for local handcoded time-synced lyrics
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('adi podi') || 
        lowerTitle.contains('vaathi coming') || 
        lowerTitle.contains('rowdy baby')) {
      if (mounted) {
        setState(() {
          _lyrics = LyricsData.getLyricsForSong(songId, title, artist);
        });
      }
      return;
    }

    // Try fetching from public JioSaavn Vercel API
    try {
      final playerService = Provider.of<PlayerService>(context, listen: false);
      final duration = playerService.audioPlayer.duration ?? const Duration(minutes: 3);
      final query = Uri.encodeComponent(title);
      final searchResponse = await http.get(Uri.parse(
        'https://jiosaavn-api.vercel.app/search?query=$query'
      ));

      if (searchResponse.statusCode == 200) {
        final searchData = jsonDecode(searchResponse.body);
        if (searchData['status'] == true && searchData['results'] != null && searchData['results'].isNotEmpty) {
          final firstResult = searchData['results'][0];
          final saavnId = firstResult['id'];
          
          final lyricsResponse = await http.get(Uri.parse(
            'https://jiosaavn-api.vercel.app/lyrics?id=$saavnId'
          ));
          
          if (lyricsResponse.statusCode == 200) {
            final lyricsData = jsonDecode(lyricsResponse.body);
            if (lyricsData['status'] == true && lyricsData['lyrics'] != null) {
              final rawLyrics = lyricsData['lyrics'] as String;
              final cleanLines = rawLyrics
                  .split(RegExp(r'<br>|\n'))
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
                  
              if (cleanLines.isNotEmpty) {
                final totalMs = duration.inMilliseconds;
                final msPerLine = (totalMs / cleanLines.length).floor();
                
                final List<LyricLine> newLyrics = [];
                for (int i = 0; i < cleanLines.length; i++) {
                  newLyrics.add(LyricLine(
                    time: Duration(milliseconds: i * msPerLine),
                    text: cleanLines[i],
                  ));
                }
                
                if (mounted) {
                  setState(() {
                    _lyrics = newLyrics;
                  });
                  return;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching dynamic lyrics: $e");
    }

    // Fallback if not found
    if (mounted) {
      setState(() {
        _lyrics = LyricsData.getLyricsForSong(songId, title, artist);
      });
    }
  }

  void _subscribeToPosition() {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    _positionSubscription = playerService.audioPlayer.positionStream.listen((position) {
      int newActive = -1;
      for (int i = 0; i < _lyrics.length; i++) {
        if (position >= _lyrics[i].time) {
          newActive = i;
        } else {
          break;
        }
      }

      if (newActive != _activeIndex) {
        setState(() {
          _activeIndex = newActive;
        });
        if (!_userScrolling) {
          _scrollToActive(newActive);
        }
      }
    });
  }

  void _scrollToActive(int index, {bool force = false}) {
    if (!_scrollController.hasClients || index == -1) return;
    
    final double itemHeight = 70.0;
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: Duration(milliseconds: force ? 50 : 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onUserScroll() {
    _userScrollTimer?.cancel();
    if (!_userScrolling) {
      setState(() {
        _userScrolling = true;
      });
    }
    _userScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _userScrolling = false;
        });
        _scrollToActive(_activeIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    if (_lyrics.isEmpty) {
      return Center(
        child: Text(
          "No lyrics available",
          style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 16),
        ),
      );
    }

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        _onUserScroll();
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
        itemCount: _lyrics.length,
        itemExtent: 70.0, // Fixed height per line for smooth offset calculations
        itemBuilder: (context, index) {
          final line = _lyrics[index];
          final isActive = index == _activeIndex;

          return GestureDetector(
            onTap: () {
              playerService.seek(line.time);
              // Instantly update active line to respond to user tap
              setState(() {
                _activeIndex = index;
              });
              _scrollToActive(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isActive ? theme.colorScheme.primary : textColor.withOpacity(0.4),
                  fontSize: isActive ? 22 : 17,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                child: Text(
                  line.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
