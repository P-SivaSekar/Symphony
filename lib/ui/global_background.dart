import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/player_service.dart';
import '../utils/color_utils.dart';

class GlobalBackground extends StatelessWidget {
  const GlobalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final playerService = Provider.of<PlayerService>(context);
    final currentSong = playerService.currentSong;

    List<Color> gradientColors;
    if (isDark) {
      gradientColors = const [
        Color(0xFF000000),
        Color(0xFF000000),
      ];
    } else {
      gradientColors = const [
        Color(0xFFF1F5F9),
        Color(0xFFE2E8F0),
      ];
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
