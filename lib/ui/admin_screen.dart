import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_upload_service.dart';
import '../providers/app_provider.dart';
import 'glassmorphic_component.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminUploadService _uploadService = AdminUploadService();
  String _searchQuery = '';

  // ─── Manage ──────────────────────────────────────────────────────────────────

  Future<void> _deleteSong(String id) async {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete Song?', style: TextStyle(color: textColor)),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: textColor.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _uploadService.deleteSong(id);
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).fetchSongs();
          _snack('Song deleted.');
        }
      } catch (e) {
        _snack('Delete failed: $e');
      }
    }
  }

  Future<void> _editSong(dynamic song) async {
    final titleController = TextEditingController(text: song.title);
    final artistController = TextEditingController(text: song.artist);
    final coverController = TextEditingController(text: song.coverUrl);
    final audioController = TextEditingController(text: song.audioUrl);
    bool isTrending = song.isTrending;

    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Edit Song', style: TextStyle(color: textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  titleController,
                  'Title',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  artistController,
                  'Artist',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  coverController,
                  'Cover URL',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  audioController,
                  'Audio URL',
                  textColor,
                  primaryColor,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(
                    'Is Trending',
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                  value: isTrending,
                  onChanged: (val) =>
                      setDialogState(() => isTrending = val ?? false),
                  activeColor: primaryColor,
                  checkColor: theme.scaffoldBackgroundColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ElevatedButton(
              onPressed: () async {
                try {
                  await _uploadService.updateSongMetadata(song.id, {
                    'title': titleController.text.trim(),
                    'artist': artistController.text.trim(),
                    'coverUrl': coverController.text.trim(),
                    'audioUrl': audioController.text.trim(),
                    'isTrending': isTrending,
                  });
                  if (mounted) {
                    Provider.of<AppProvider>(
                      context,
                      listen: false,
                    ).fetchSongs();
                    Navigator.pop(context);
                    _snack('Song updated!');
                  }
                } catch (e) {
                  _snack('Update failed: $e');
                }
              },
              child: const Text('Update'),
            )      ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    Color textColor,
    Color primaryColor,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: const BorderRadius.all(Radius.circular(15)),
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    final songs = appProvider.allSongs.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Manage Songs',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? null : theme.scaffoldBackgroundColor,
              gradient: isDark
                  ? const LinearGradient(
                      colors: [
                        Colors.black,
                        Colors.black,
                        Colors.black,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GlassContainer(
                    child: TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search songs or artists...',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        final song = songs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: song.coverUrl.isEmpty
                                    ? Container(
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black26,
                                        width: 50,
                                        height: 50,
                                        child: const Icon(Icons.music_note),
                                      )
                                    : Image.network(
                                        song.coverUrl,
                                        width: 50,
                                        height: 50,
                                        cacheWidth:
                                            150, // Optimize memory usage
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: isDark
                                              ? Colors.white24
                                              : Colors.black26,
                                          width: 50,
                                          height: 50,
                                          child: const Icon(Icons.music_note),
                                        ),
                                      ),
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
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: primaryColor,
                                    ),
                                    onPressed: () => _editSong(song),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteSong(song.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
