import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/playlist_model.dart';
import 'playlist_screen.dart';
import 'yt_music_player.dart';
import 'glassmorphic_component.dart';
import 'playlist_card.dart';

class AllPlaylistsScreen extends StatefulWidget {
  final bool isExplore;
  const AllPlaylistsScreen({super.key, this.isExplore = false});

  @override
  State<AllPlaylistsScreen> createState() => _AllPlaylistsScreenState();
}

class _AllPlaylistsScreenState extends State<AllPlaylistsScreen> {
  bool _isMultiSelectMode = false;
  Set<String> _selectedPlaylists = {};

  void _showPlaylistOptions(
    BuildContext context,
    Playlist playlist,
    AppProvider appProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenamePlaylistDialog(context, playlist, appProvider);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_box),
                title: const Text('Select'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isMultiSelectMode = true;
                    _selectedPlaylists.add(playlist.id);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Playlist',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePlaylist(context, [playlist.id], appProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRenamePlaylistDialog(
    BuildContext context,
    Playlist playlist,
    AppProvider appProvider,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: playlist.name,
    );
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Rename Playlist',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'New Playlist Name',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  appProvider.renamePlaylist(playlist.id, newName);
                }
                Navigator.pop(context);
              },
              child: Text(
                'Save',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePlaylist(
    BuildContext context,
    List<String> playlistIds,
    AppProvider appProvider,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Delete Playlist(s)',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to delete ${playlistIds.length} playlist(s)?',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                appProvider.deletePlaylists(playlistIds);
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedPlaylists.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final displayPlaylists = <Playlist>[];
    if (widget.isExplore) {
      displayPlaylists.addAll(appProvider.globalPlaylists);
    } else {
      displayPlaylists.add(Playlist(id: 'liked_songs', name: 'Liked', creatorId: 'system', songIds: appProvider.userProfile?.likedSongs ?? []));
      displayPlaylists.add(Playlist(id: 'downloaded_songs', name: 'Downloads', creatorId: 'system', songIds: appProvider.downloadedSongs.map((s) => s.id).toList()));
      displayPlaylists.addAll(appProvider.userPlaylists);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode
              ? "${_selectedPlaylists.length} Selected"
              : (widget.isExplore ? "Explore" : "Your Playlists"),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedPlaylists.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!widget.isExplore) ...[
            if (_isMultiSelectMode && _selectedPlaylists.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDeletePlaylist(
                  context,
                  _selectedPlaylists.toList(),
                  appProvider,
                ),
              )
            else if (!_isMultiSelectMode)
              IconButton(
                icon: Icon(Icons.checklist, color: textColor),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = true;
                  });
                },
              ),
          ]
        ],
      ),
      extendBodyBehindAppBar: true,
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
            bottom: false,
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 16 + 64),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: widget.isExplore ? 0.9 : 0.85,
              ),
              itemCount: displayPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = displayPlaylists[index];
                final isFixed = widget.isExplore || playlist.id == 'liked_songs' || playlist.id == 'downloaded_songs';
                final songCount = playlist.songIds.length;
                final isSelected = !isFixed && _selectedPlaylists.contains(playlist.id);

                return GestureDetector(
                  onTap: () {
                    if (_isMultiSelectMode) {
                      if (isFixed) return;
                      setState(() {
                        if (isSelected) {
                          _selectedPlaylists.remove(playlist.id);
                        } else {
                          _selectedPlaylists.add(playlist.id);
                        }
                      });
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistScreen(playlist: playlist),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    if (!isFixed && !_isMultiSelectMode && !widget.isExplore) {
                      _showPlaylistOptions(context, playlist, appProvider);
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (widget.isExplore)
                        PlaylistCard(
                          playlist: playlist,
                          isTrending: playlist.name.toLowerCase().contains('trending'),
                        )
                      else
                        GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(12),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isDark ? Colors.white10 : Colors.black12,
                                ),
                                child: Icon(
                                  Icons.queue_music,
                                  color: textColor.withOpacity(0.8),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                playlist.name,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$songCount songs",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.surface,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: YTMusicPlayer(hasBottomNav: false),
          ),
        ],
      ),
    );
  }
}
