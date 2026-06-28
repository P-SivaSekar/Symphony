import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  final originalContent = file.readAsStringSync();
  
  final topPart = '''import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:text_scroll/text_scroll.dart';
import '../models/song_model.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import '../utils/song_options_bottom_sheet.dart';
import '../utils/ui_utils.dart';
import 'glassmorphic_component.dart';

class PlayerScreen extends StatefulWidget {
  final bool hideCover;
  const PlayerScreen({super.key, this.hideCover = false});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PageController _pageController;
  bool _isProgrammaticScroll = false;
  
  @override
  void initState() {
    super.initState();
    final playerService = Provider.of<PlayerService>(context, listen: false);
    _pageController = PageController(
      initialPage: playerService.currentEffectiveIndex,
    );
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playerService = Provider.of<PlayerService>(context, listen: false);
    if (_pageController.hasClients &&
        _pageController.page?.round() != playerService.currentEffectiveIndex) {
      _isProgrammaticScroll = true;
      _pageController
          .animateToPage(
            playerService.currentEffectiveIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) {
        _isProgrammaticScroll = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final song = playerService.currentSong;
    if (song == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Now Playing')),
        body: const Center(child: Text('No song playing')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Cover
          Positioned.fill(
            child: widget.hideCover ? Container(color: theme.colorScheme.surface) : Image.network(
              song.coverUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surface,
              ),
            ),
          ),
          // Blur Overlay
          if (!widget.hideCover)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withOpacity(isDark ? 0.6 : 0.4)),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Now Playing',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      GlassContainer(
                        borderRadius: 30,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onPressed: () => showSongOptionsBottomSheet(context, song),
                        ),
                      ),
                    ],
                  ),
                ),
                // Cover Art Pager
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      if (_isProgrammaticScroll) return;
                      if (index != playerService.currentEffectiveIndex) {
                        final actualIndex =
''';

  file.writeAsStringSync(topPart + originalContent);
  print("Prepended the top part to player_screen.dart");
}
