import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/play_helper.dart';
import 'global_background.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'player_screen.dart';
import 'glassmorphic_component.dart';
import 'yt_music_player.dart';
import 'download_button.dart';
import '../utils/song_options_bottom_sheet.dart';

class PlaylistScreen extends StatefulWidget {
  final dynamic playlist; // Can be a Playlist model or a Map for "All Songs"
  final bool autoOpenAddSongs;

  const PlaylistScreen({
    super.key,
    required this.playlist,
    this.autoOpenAddSongs = false,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  String _sortOption = 'recently_added';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isMultiSelectMode = false;
  Set<String> _selectedSongs = {};

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
            decoration: InputDecoration(hintText: 'New Playlist Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  appProvider.renamePlaylist(playlist.id, newName);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeletePlaylist(
    BuildContext context,
    Playlist playlist,
    AppProvider appProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appProvider.deletePlaylist(playlist.id);
                Navigator.pop(context);
                Navigator.pop(context); // Also pop the playlist screen
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenAddSongs && widget.playlist is Playlist) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddSongsModal(context, widget.playlist as Playlist);
      });
    }
  }

  void _showAddSongsModal(BuildContext context, Playlist currentPlaylist) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _AddSongsSheet(playlist: currentPlaylist);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playerService = Provider.of<PlayerService>(context);

    String name = '';
    List<Song> baseSongs = [];
    bool isCustomPlaylist = false;

    if (widget.playlist is Map) {
      name = widget.playlist['name'];
      baseSongs = widget.playlist['songs'];
    } else if (widget.playlist is Playlist) {
      final pl = widget.playlist as Playlist;
      isCustomPlaylist = !pl.isGlobal || appProvider.isAdmin;
      name = pl.name;
      // Fetch latest playlist state from provider if available
      final p = appProvider.userPlaylists.firstWhere(
        (p) => p.id == widget.playlist.id,
        orElse: () => appProvider.globalPlaylists.firstWhere(
          (gp) => gp.id == widget.playlist.id,
          orElse: () => widget.playlist,
        ),
      );
      baseSongs = appProvider.allSongs
          .where((s) => p.songIds.contains(s.id))
          .toList();
    }

    // Apply search filter
    List<Song> displaySongs = baseSongs.where((s) {
      final query = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(query) ||
          s.artist.toLowerCase().contains(query);
    }).toList();

    // Apply sorting
    if (_sortOption == 'recently_added') {
      displaySongs.sort((a, b) => appProvider.allSongs.indexOf(a).compareTo(appProvider.allSongs.indexOf(b)));
      displaySongs = displaySongs.reversed.toList();
    } else if (_sortOption == 'alphabetical') {
      displaySongs.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (_sortOption == 'artist') {
      displaySongs.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode ? "${_selectedSongs.length} Selected" : name,
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
                    _selectedSongs.clear();
                  });
                },
              )
            : const BackButton(),
        actions: [
          if (_isMultiSelectMode &&
              _selectedSongs.isNotEmpty &&
              isCustomPlaylist)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                await appProvider.removeSongsFromPlaylist(
                  (widget.playlist as Playlist).id,
                  _selectedSongs.toList(),
                );
                setState(() {
                  _isMultiSelectMode = false;
                  _selectedSongs.clear();
                });
              },
            )
          else if (!_isMultiSelectMode && isCustomPlaylist)
            IconButton(
              icon: Icon(Icons.checklist, color: textColor),
              onPressed: () {
                setState(() {
                  _isMultiSelectMode = true;
                });
              },
            ),
          if (!_isMultiSelectMode && isCustomPlaylist)
            PopupMenuButton<String>(color: Colors.transparent,
              icon: Icon(Icons.more_vert, color: textColor),
              onSelected: (value) {
                if (value == 'rename') {
                  _showRenamePlaylistDialog(
                    context,
                    widget.playlist as Playlist,
                    appProvider,
                  );
                } else if (value == 'delete') {
                  _confirmDeletePlaylist(
                    context,
                    widget.playlist as Playlist,
                    appProvider,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename Playlist'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete Playlist',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),

      body: Stack(
        children: [
          const GlobalBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: GlassContainer(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search within playlist...',
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
                ),
                if (isCustomPlaylist)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: GlassContainer(
                        borderRadius: 30,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddSongsModal(
                            context,
                            widget.playlist as Playlist,
                          ),
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: primaryColor,
                          ),
                          label: Text(
                            'Add Songs to Playlist',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (displaySongs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GlassContainer(
                            borderRadius: 30,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                playerService.setShuffle(false);
                                playAndOpenPlayer(context, displaySongs, 0);
                              },
                              icon: Icon(
                                Icons.play_arrow,
                                color: textColor,
                              ),
                              label: Text(
                                'Play',
                                style: TextStyle(
                                  color: textColor,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GlassContainer(
                            borderRadius: 30,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                playerService.setShuffle(true);
                                final initialIndex = displaySongs.length > 1
                                    ? math.Random().nextInt(displaySongs.length)
                                    : 0;
                                playAndOpenPlayer(context, displaySongs, initialIndex);
                              },
                              icon: Icon(Icons.shuffle, color: textColor),
                              label: Text(
                                'Shuffle',
                                style: TextStyle(color: textColor),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PopupMenuButton<String>(
                            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                            icon: GlassContainer(
                              borderRadius: 12,
                              padding: const EdgeInsets.all(8),
                              blurColor: isDark ? Colors.black.withOpacity(0.1) : Colors.white.withOpacity(0.1),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 0.5,
                              ),
                              child: Icon(Icons.sort, color: textColor, size: 20),
                            ),
                            elevation: 0,
                            itemBuilder: (context) {
                              return [
                                PopupMenuItem(
                                  enabled: false,
                                  padding: EdgeInsets.zero,
                                  child: GlassContainer(
                                    hasBlur: true,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    borderRadius: 16,
                                    blurColor: isDark
                                        ? Colors.black.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.2),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() => _sortOption = 'recently_added');
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text('Recently Added', style: TextStyle(color: textColor)),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() => _sortOption = 'alphabetical');
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text('Alphabetical', style: TextStyle(color: textColor)),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                            setState(() => _sortOption = 'artist');
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text('Artist', style: TextStyle(color: textColor)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: displaySongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "No songs found.",
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                ),
                              ),
                              if (isCustomPlaylist && _searchQuery.isEmpty)
                                const SizedBox(height: 20),
                              if (isCustomPlaylist && _searchQuery.isEmpty)
                                GlassContainer(
                                  borderRadius: 30,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showAddSongsModal(
                                      context,
                                      widget.playlist as Playlist,
                                    ),
                                    icon: Icon(Icons.add, color: primaryColor),
                                    label: Text(
                                      'Add Songs',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: displaySongs.length,
                          itemBuilder: (context, index) {
                            final song = displaySongs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassContainer(
                                padding: const EdgeInsets.all(8),
                                border:
                                    _isMultiSelectMode &&
                                        _selectedSongs.contains(song.id)
                                    ? Border.all(color: primaryColor, width: 2)
                                    : null,
                                child: Stack(
                                  children: [
                                    ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: song.coverUrl.isEmpty
                                            ? Container(
                                                color: isDark
                                                    ? Colors.white10
                                                    : Colors.black12,
                                                alignment: Alignment.center,
                                                width: 55,
                                                height: 55,
                                                child: Icon(
                                                  Icons.music_note,
                                                  color: textColor.withOpacity(
                                                    0.24,
                                                  ),
                                                ),
                                              )
                                            : Image.network(
                                                song.coverUrl,
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: isDark
                                                          ? Colors.white10
                                                          : Colors.black12,
                                                      alignment:
                                                          Alignment.center,
                                                      width: 55,
                                                      height: 55,
                                                      child: Icon(
                                                        Icons.music_note,
                                                        color: textColor
                                                            .withOpacity(0.24),
                                                      ),
                                                    ),
                                              ),
                                      ),
                                      title: Text(
                                        song.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        song.artist,
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: !_isMultiSelectMode
                                          ? GlassContainer(
                                              borderRadius: 30,
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.more_vert,
                                                  color: textColor.withOpacity(0.5),
                                                ),
                                                onPressed: () {
                                                  showSongOptionsBottomSheet(
                                                    context,
                                                    song,
                                                  );
                                                },
                                              ),
                                            )
                                          : null,
                                      onTap: () {
                                        if (_isMultiSelectMode) {
                                          setState(() {
                                            if (_selectedSongs.contains(
                                              song.id,
                                            )) {
                                              _selectedSongs.remove(song.id);
                                            } else {
                                              _selectedSongs.add(song.id);
                                            }
                                            if (_selectedSongs.isEmpty) {
                                              _isMultiSelectMode = false;
                                            }
                                          });
                                        } else {
                                          playAndOpenPlayer(context, displaySongs, index);
                                        }
                                      },
                                      onLongPress: () {
                                        if (!_isMultiSelectMode) {
                                          setState(() {
                                            _isMultiSelectMode = true;
                                            _selectedSongs.add(song.id);
                                          });
                                        }
                                      },
                                    ),
                                    if (_isMultiSelectMode &&
                                        _selectedSongs.contains(song.id))
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
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (playerService.currentSong != null)
            const YTMusicPlayer(),
        ],
      ),
    );
  }
}

class _AddSongsSheet extends StatefulWidget {
  final Playlist playlist;
  const _AddSongsSheet({required this.playlist});

  @override
  State<_AddSongsSheet> createState() => _AddSongsSheetState();
}

class _AddSongsSheetState extends State<_AddSongsSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    // Fetch latest playlist state
    final currentPlaylist = appProvider.userPlaylists.firstWhere(
      (p) => p.id == widget.playlist.id,
      orElse: () => appProvider.globalPlaylists.firstWhere(
        (gp) => gp.id == widget.playlist.id,
        orElse: () => widget.playlist,
      ),
    );

    // Filter out songs already in the playlist
    final availableSongs = appProvider.allSongs
        .where((s) => !currentPlaylist.songIds.contains(s.id))
        .toList();

    // Apply search filter
    final displaySongs = availableSongs.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.artist.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Songs to Playlist',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search songs...',
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
            child: displaySongs.isEmpty
                ? Center(
                    child: Text(
                      "No songs available.",
                      style: TextStyle(color: textColor.withOpacity(0.7)),
                    ),
                  )
                : ListView.builder(
                    itemCount: displaySongs.length,
                    itemBuilder: (context, index) {
                      final song = displaySongs[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.coverUrl.isEmpty
                              ? Container(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.music_note,
                                    color: textColor.withOpacity(0.5),
                                  ),
                                )
                              : Image.network(
                                  song.coverUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    width: 40,
                                    height: 40,
                                    child: Icon(
                                      Icons.music_note,
                                      color: textColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle, color: primaryColor),
                          onPressed: () async {
                            await appProvider.addSongToPlaylist(
                              widget.playlist.id,
                              song.id,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}




