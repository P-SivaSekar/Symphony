import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../services/player_service.dart';
import '../ui/player_screen.dart';

bool _isOpeningPlayer = false;

Future<void> playAndOpenPlayer(BuildContext context, List<Song> queue, int index) async {
  if (index < 0 || index >= queue.length) return;
  if (_isOpeningPlayer) return;
  _isOpeningPlayer = true;

  try {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    
    // Load the playlist (handles resolution asynchronously in the background)
    playerService.loadPlaylist(queue, initialIndex: index);
    
    if (context.mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(hideCover: false),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  } finally {
    // Keep lock active for a short debounce period to prevent rapid taps
    await Future.delayed(const Duration(milliseconds: 500));
    _isOpeningPlayer = false;
  }
}
