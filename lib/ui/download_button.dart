import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/app_provider.dart';
import '../utils/ui_utils.dart';

class DownloadButton extends StatelessWidget {
  final Song song;
  final Color? color;

  const DownloadButton({super.key, required this.song, this.color});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isDownloaded = appProvider.isSongDownloaded(song.id);
        final isDownloading = appProvider.isSongDownloading(song.id);
        final iconColor = color ?? Colors.white.withOpacity(0.5);

        if (isDownloading) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          );
        }

        if (isDownloaded) {
          return IconButton(
            icon: const Icon(Icons.download_done, color: Colors.green),
            onPressed: () {
              // Optionally allow removing download
              _showRemoveDialog(context, appProvider);
            },
          );
        }

        return IconButton(
          icon: Icon(Icons.download, color: iconColor),
          onPressed: () {
            appProvider.downloadSong(song);
            UIUtils.showPopup(context, 'Downloading song...');
          },
        );
      },
    );
  }

  void _showRemoveDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Remove Download?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to remove this song from downloads?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54)),
            ),
          ),
          TextButton(
            onPressed: () {
              appProvider.deleteDownloadedSong(song.id);
              UIUtils.showPopup(context, 'Download removed');
              Navigator.pop(context);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
