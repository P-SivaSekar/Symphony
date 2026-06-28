import 'dart:io';

void main() {
  final file = File('lib/ui/player_screen.dart');
  String content = file.readAsStringSync();

  // 1. Fix StreamBuilder by using a Stream.periodic and clamping values
  content = content.replaceAll(
    '''                      StreamBuilder<Duration>(
                        stream: playerService.audioPlayer.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;''',
    '''                      StreamBuilder<int>(
                        stream: Stream.periodic(const Duration(milliseconds: 200), (i) => i),
                        builder: (context, snapshot) {
                          final position = playerService.currentPosition;'''
  );

  content = content.replaceAll(
    '''                                child: Slider(
                                  value: position.inSeconds.toDouble(),
                                  min: 0,
                                  max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                                  onChanged: (value) {
                                    playerService.audioPlayer.seek(Duration(seconds: value.toInt()));
                                  },
                                ),''',
    '''                                child: Slider(
                                  value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0),
                                  min: 0,
                                  max: duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0,
                                  onChanged: (value) {
                                    playerService.seek(Duration(seconds: value.toInt()));
                                  },
                                ),'''
  );

  // 2. Fix the Bottom Row to add Queue button instead of just Autoplay
  content = content.replaceAll(
    '''                // Bottom Row (Autoplay, etc.)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassContainer(
                        borderRadius: 30,
                        child: IconButton(
                          icon: Icon(
                            Icons.autorenew,
                            color: playerService.autoplayEnabled ? primaryColor : Colors.white.withOpacity(0.54),
                            size: 24,
                          ),
                          onPressed: () => playerService.toggleAutoplay(),
                        ),
                      ),
                    ],
                  ),
                ),''',
    '''                // Bottom Row (Queue)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48), // spacer
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white54,
                          size: 32,
                        ),
                        onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.queue_music,
                          color: Colors.white54,
                          size: 24,
                        ),
                        onPressed: () => _showQueueBottomSheet(context, playerService, appProvider),
                      ),
                    ],
                  ),
                ),'''
  );

  // 3. Add the _showQueueBottomSheet method inside _PlayerScreenState
  content = content.replaceFirst(
    '''  @override
  Widget build(BuildContext context) {''',
    '''  void _showQueueBottomSheet(BuildContext context, PlayerService playerService, AppProvider appProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GlassContainer(
              borderRadius: 20,
              hasBlur: true,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Up Next',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Autoplay',
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                            ),
                            Switch(
                              value: playerService.autoplayEnabled,
                              activeColor: primaryColor,
                              onChanged: (val) {
                                playerService.toggleAutoplay();
                                setState(() {}); // update sheet UI
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: playerService.fullEffectivePlaylist.length,
                        itemBuilder: (context, index) {
                          final song = playerService.fullEffectivePlaylist[index];
                          final isPlaying = index == playerService.currentEffectiveIndex;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.coverUrl.isEmpty
                                  ? Container(
                                      width: 50,
                                      height: 50,
                                      color: isDark ? Colors.white10 : Colors.black12,
                                      child: Icon(Icons.music_note, color: textColor.withOpacity(0.5)),
                                    )
                                  : (song.coverUrl.startsWith('asset:')
                                      ? Image.asset(song.coverUrl.replaceFirst('asset:', ''), width: 50, height: 50, fit: BoxFit.cover)
                                      : Image.network(song.coverUrl, width: 50, height: 50, fit: BoxFit.cover)),
                            ),
                            title: Text(
                              song.title,
                              style: TextStyle(
                                color: isPlaying ? primaryColor : textColor,
                                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist,
                              style: TextStyle(color: textColor.withOpacity(0.7)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isPlaying
                                ? Icon(Icons.equalizer, color: primaryColor)
                                : IconButton(
                                    icon: Icon(Icons.more_vert, color: textColor.withOpacity(0.7)),
                                    onPressed: () => showSongOptionsBottomSheet(context, song),
                                  ),
                            onTap: () {
                              playerService.audioPlayer.seek(Duration.zero, index: index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {'''
  );

  // 4. Fix cover image animation: Add a frame callback inside build
  content = content.replaceFirst(
    '''  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);''',
    '''  @override
  Widget build(BuildContext context) {
    final playerService = Provider.of<PlayerService>(context);

    // Ensure PageView animates to the correct page when the song changes externally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && !_isProgrammaticScroll) {
        final currentPage = _pageController.page?.round() ?? 0;
        if (currentPage != playerService.currentEffectiveIndex) {
          _isProgrammaticScroll = true;
          _pageController.animateToPage(
            playerService.currentEffectiveIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ).then((_) => _isProgrammaticScroll = false);
        }
      }
    });'''
  );

  // 5. Change showSongOptionsBottomSheet in player_screen.dart to isFullScreenPlayer: true
  content = content.replaceAll(
    '''showSongOptionsBottomSheet(context, song)''',
    '''showSongOptionsBottomSheet(context, song, isFullScreenPlayer: true)'''
  );

  // Wait, I need to undo that for the _showQueueBottomSheet which shouldn't have isFullScreenPlayer: true!
  content = content.replaceAll(
    '''showSongOptionsBottomSheet(context, song, isFullScreenPlayer: true),
                                  ),
                            onTap: () {
                              playerService.audioPlayer.seek(Duration.zero, index: index);''',
    '''showSongOptionsBottomSheet(context, song),
                                  ),
                            onTap: () {
                              playerService.audioPlayer.seek(Duration.zero, index: index);'''
  );

  file.writeAsStringSync(content);
  print('Updated player_screen.dart successfully.');
}
