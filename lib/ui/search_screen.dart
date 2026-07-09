import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import '../models/song_model.dart';
import 'player_screen.dart';
import 'glassmorphic_component.dart';
import 'download_button.dart';
import '../utils/song_options_bottom_sheet.dart';
import '../utils/ui_utils.dart';
import '../utils/play_helper.dart';

class SearchScreen extends StatefulWidget {
  final bool isActive;
  const SearchScreen({super.key, this.isActive = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _isMultiSelectMode = false;
  Set<String> _selectedSongs = {};

  void _showAddToPlaylistDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final theme = Theme.of(context);
    final customPlaylists = appProvider.userPlaylists;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add to Playlist'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ...customPlaylists.map((playlist) {
                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(
                      playlist.name,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onTap: () {
                      appProvider.addSongsToPlaylist(
                        playlist.id,
                        _selectedSongs.toList(),
                      );
                      Navigator.pop(context);
                      setState(() {
                        _isMultiSelectMode = false;
                        _selectedSongs.clear();
                      });
                      UIUtils.showPopup(
                        context,
                        'Added ${_selectedSongs.length} songs to ${playlist.name}',
                      );
                    },
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: Text(
                    'Create New Playlist',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreatePlaylistDialog();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCreatePlaylistDialog() {
    final theme = Theme.of(context);
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Playlist'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Playlist Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  final newPlaylist = await appProvider.createPlaylist(name);
                  if (newPlaylist != null && _selectedSongs.isNotEmpty) {
                    await appProvider.addSongsToPlaylist(
                      newPlaylist.id,
                      _selectedSongs.toList(),
                    );
                    if (mounted) {
                      setState(() {
                        _isMultiSelectMode = false;
                        _selectedSongs.clear();
                      });
                      UIUtils.showPopup(
                        context,
                        'Created $name and added songs',
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    if (widget.isActive) {
      _focusNode.requestFocus();
    }
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _isSearching = true;
      _searchResults = appProvider.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artist.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playerService = Provider.of<PlayerService>(context);

    // If not searching, display explicitly marked recently added songs (last 10 songs)
    final displaySongs = _isSearching
        ? _searchResults
        : (appProvider.trendingSongs.reversed.take(10).toList());
        
    final bool allSelected = displaySongs.isNotEmpty && 
        displaySongs.every((s) => _selectedSongs.contains(s.id));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by MainScreen stack
      appBar: _isMultiSelectMode
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                "${_selectedSongs.length} Selected",
                style: TextStyle(color: textColor),
              ),
              leading: IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedSongs.clear();
                  });
                },
              ),
              actions: [
                if (_selectedSongs.isNotEmpty || _isMultiSelectMode)
                  IconButton(
                    icon: Icon(allSelected ? Icons.deselect : Icons.select_all, color: primaryColor),
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selectedSongs.removeAll(displaySongs.map((s) => s.id));
                          if (_selectedSongs.isEmpty) {
                            _isMultiSelectMode = false;
                          }
                        } else {
                          _selectedSongs.addAll(displaySongs.map((s) => s.id));
                        }
                      });
                    },
                  ),
                if (_selectedSongs.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.playlist_add, color: primaryColor),
                    onPressed: _showAddToPlaylistDialog,
                  ),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: GlassContainer(
                borderRadius: 30,
                height: 45,
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  autofocus:
                      true, // Opens keyboard automatically when first built
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: 'Search songs, artists...',
                    hintStyle: TextStyle(color: textColor.withOpacity(0.54)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: textColor.withOpacity(0.54),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
      body: appProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_isSearching && displaySongs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 10,
                    ),
                    child: Text(
                      'Recently Added',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                if (_isSearching && displaySongs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No songs found',
                        style: TextStyle(
                          color: textColor.withOpacity(0.54),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                if (displaySongs.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(
                        bottom: 100,
                        left: 20,
                        right: 20,
                        top: 10,
                      ),
                      itemCount: displaySongs.length,
                      itemBuilder: (context, index) {
                        final song = displaySongs[index];
                        return GestureDetector(
                          onTap: () {
                            if (_isMultiSelectMode) {
                              setState(() {
                                if (_selectedSongs.contains(song.id)) {
                                  _selectedSongs.remove(song.id);
                                } else {
                                  _selectedSongs.add(song.id);
                                }
                                if (_selectedSongs.isEmpty) {
                                  _isMultiSelectMode = false;
                                }
                              });
                            } else if (_isSearching) {
                                  final allSongs = appProvider.allSongs;
                                  final initialIndex = allSongs.indexWhere(
                                    (s) => s.id == song.id,
                                  );
                                  playAndOpenPlayer(
                                    context,
                                    allSongs,
                                    initialIndex != -1 ? initialIndex : 0,
                                  );
                                } else {
                                  playAndOpenPlayer(
                                    context,
                                    displaySongs,
                                    index,
                                  );
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
                          child: Container(
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
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.black26,
                                              ),
                                            )
                                          : song.coverUrl.startsWith('asset:')
                                          ? Image.asset(
                                              song.coverUrl.replaceFirst(
                                                'asset:',
                                                '',
                                              ),
                                              width: 55,
                                              height: 55,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.network(
                                              song.coverUrl,
                                              width: 55,
                                              height: 55,
                                              cacheWidth: 300,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: isDark
                                                        ? Colors.white10
                                                        : Colors.black12,
                                                    width: 55,
                                                    height: 55,
                                                    child: Icon(
                                                      Icons.music_note,
                                                      color: isDark
                                                          ? Colors.white24
                                                          : Colors.black26,
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
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: textColor.withOpacity(
                                                0.54,
                                              ),
                                            ),
                                            onPressed: () {
                                              showSongOptionsBottomSheet(
                                                context,
                                                song,
                                              );
                                            },
                                          )
                                        : null,
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

