import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import 'player_screen.dart';
import 'glassmorphic_component.dart';
import '../utils/play_helper.dart';

class TrendingScreen extends StatelessWidget {
  const TrendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playerService = Provider.of<PlayerService>(context);

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by MainScreen stack
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Trending Now',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 1.2,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: appProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 100,
                left: 20,
                right: 20,
                top: 20,
              ),
              itemCount: appProvider.trendingSongs.length,
              itemBuilder: (context, index) {
                final song = appProvider.trendingSongs[index];
                return GestureDetector(
                  onTap: () {
                    playAndOpenPlayer(context, appProvider.trendingSongs, index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: song.coverUrl.isEmpty
                              ? Container(
                                  color: Colors.white10,
                                  width: 55,
                                  height: 55,
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white24,
                                  ),
                                )
                              : song.coverUrl.startsWith('asset:')
                              ? Image.asset(
                                  song.coverUrl.replaceFirst('asset:', ''),
                                  width: 55,
                                  height: 55,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  song.coverUrl,
                                  width: 55,
                                  height: 55,
                                  cacheWidth: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.white10,
                                    width: 55,
                                    height: 55,
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white24,
                                    ),
                                  ),
                                ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            appProvider.isSongLiked(song)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: appProvider.isSongLiked(song)
                                ? Colors.pinkAccent
                                : Colors.white54,
                          ),
                          onPressed: () {
                            appProvider.toggleFavorite(song);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
