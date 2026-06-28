import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import 'ui_utils.dart';
import '../ui/glassmorphic_component.dart';

void showSongOptionsBottomSheet(BuildContext context, Song song, {bool isFullScreenPlayer = false, bool isQueueContext = false, int queueIndex = -1}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final textColor = theme.colorScheme.onSurface;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer2<AppProvider, PlayerService>(
        builder: (context, appProvider, playerService, child) {
          final isDownloaded = appProvider.isSongDownloaded(song.id);
          final isDownloading = appProvider.isSongDownloading(song.id);

          return GlassContainer(
            borderRadius: 20,
            hasBlur: true,
            child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: song.coverUrl.isEmpty
                        ? Container(
                            width: 50,
                            height: 50,
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: Icon(
                              Icons.music_note,
                              color: textColor.withOpacity(0.5),
                            ),
                          )
                        : (song.coverUrl.startsWith('asset:')
                              ? Image.asset(
                                  song.coverUrl.replaceFirst('asset:', ''),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  song.coverUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
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
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    appProvider.isSongLiked(song)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: appProvider.isSongLiked(song)
                        ? Colors.pinkAccent
                        : textColor,
                  ),
                  title: Text(
                    appProvider.isSongLiked(song) ? 'Unlike' : 'Like',
                    style: TextStyle(color: textColor),
                  ),
                  onTap: () {
                    appProvider.toggleFavorite(song);
                    UIUtils.showPopup(
                      context,
                      appProvider.isSongLiked(song)
                          ? 'Removed from liked songs'
                          : 'Added to liked songs',
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.playlist_add, color: textColor),
                  title: Text('Add to Playlist', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: isDark ? const Color(0xFF24243E) : Colors.white,
                          title: Text('Select Playlist', style: TextStyle(color: textColor)),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: appProvider.userPlaylists.length,
                              itemBuilder: (context, index) {
                                final playlist = appProvider.userPlaylists[index];
                                return ListTile(
                                  title: Text(playlist.name, style: TextStyle(color: textColor)),
                                  onTap: () {
                                    appProvider.addSongToPlaylist(playlist.id, song.id);
                                    Navigator.pop(context);
                                    UIUtils.showPopup(context, 'Added to \${playlist.name}');
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                if (!kIsWeb)
                  ListTile(
                    leading: Icon(
                      isDownloaded ? Icons.download_done : Icons.download,
                      color: isDownloaded ? Colors.green : textColor,
                    ),
                    title: Text(
                      isDownloaded
                          ? 'Downloaded'
                          : (isDownloading ? 'Downloading...' : 'Download'),
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () {
                      if (!isDownloaded && !isDownloading) {
                        appProvider.downloadSong(song);
                        UIUtils.showPopup(context, 'Downloading song...');
                      }
                      Navigator.pop(context);
                    },
                  ),
                if (!isFullScreenPlayer && !isQueueContext)
                  ListTile(
                    leading: Icon(Icons.queue_music, color: textColor),
                    title: Text('Play Next', style: TextStyle(color: textColor)),
                    onTap: () {
                      playerService.addNext(song);
                      UIUtils.showPopup(context, 'Added to play next');
                      Navigator.pop(context);
                    },
                  ),
                if (!isFullScreenPlayer && !isQueueContext)
                  ListTile(
                    leading: Icon(Icons.playlist_add, color: textColor),
                    title: Text(
                      'Add to Queue',
                      style: TextStyle(color: textColor),
                    ),
                    onTap: () {
                      playerService.addToQueue(song);
                      UIUtils.showPopup(context, 'Added to queue');
                      Navigator.pop(context);
                    },
                  ),
                if (isQueueContext && queueIndex != -1) ...[
                  ListTile(
                    leading: Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                    title: Text('Remove from Queue', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      playerService.removeFromQueue(queueIndex);
                      Navigator.pop(context);
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
            ),
            ),
          );
        },
      );
    },
  );
}
