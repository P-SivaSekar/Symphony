import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'global_background.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import 'player_screen.dart';
import 'playlist_screen.dart';
import 'glassmorphic_component.dart';
import 'all_playlists_screen.dart';
import '../models/playlist_model.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _usernameController = TextEditingController();
  Uint8List? _selectedImageBytes;
  bool _isUpdating = false;
  bool _removePhoto = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AppProvider>(
      context,
      listen: false,
    ).userProfile;
    if (profile != null) {
      _usernameController.text = profile.username;
    }
  }

  void _startEditing(String currentUsername) {
    setState(() {
      _isEditing = true;
      _usernameController.text = currentUsername;
      _removePhoto = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _removePhoto = false;
      });
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes) async {
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse(
                'https://api.cloudinary.com/v1_1/dx02qjcqn/image/upload',
              ),
            )
            ..fields['upload_preset'] = 'symphony_preset'
            ..files.add(
              http.MultipartFile.fromBytes('file', imageBytes, filename: 'profile_pic.jpg')
            );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final profile = provider.userProfile!;

    setState(() => _isUpdating = true);

    String newPicUrl = profile.profilePicUrl;
    if (_removePhoto) {
      newPicUrl = '';
    } else if (_selectedImageBytes != null) {
      final uploadedUrl = await _uploadImage(_selectedImageBytes!);
      if (uploadedUrl != null) newPicUrl = uploadedUrl;
    } else if (newPicUrl.contains('ui-avatars.com')) {
      newPicUrl = ''; // Clean up legacy UI avatars
    }

    final error = await provider.updateProfile(
      _usernameController.text.trim(),
      newPicUrl,
    );

    if (mounted) {
      setState(() {
        _isUpdating = false;
        if (error == null) _isEditing = false;
      });
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

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
                leading: Icon(Icons.edit),
                title: Text('Rename Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenamePlaylistDialog(context, playlist, appProvider);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text(
                  'Delete Playlist',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePlaylist(context, playlist, appProvider);
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
            decoration: InputDecoration(hintText: 'New Playlist Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  appProvider.renamePlaylist(playlist.id, newName);
                }
                Navigator.pop(context);
              },
              child: Text('Save'),
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
          title: Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appProvider.deletePlaylist(playlist.id);
                Navigator.pop(context);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final profile = appProvider.userProfile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Text("Profile not found", style: TextStyle(color: textColor)),
        ),
      );
    }

    // Determine what to show for the avatar
    bool showNativeText = false;
    if (_removePhoto) {
      showNativeText = true;
    } else if (_selectedImageBytes == null) {
      if (profile.profilePicUrl.isEmpty ||
          profile.profilePicUrl.contains('ui-avatars.com')) {
        showNativeText = true;
      }
    }

    return Stack(
      children: [
        const GlobalBackground(),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Profile",
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: textColor),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
              child: GlassContainer(
                width: 36,
                height: 36,
                borderRadius: 12,
                blurSigmaX: 4.0,
                blurSigmaY: 4.0,
                blurColor: Colors.black.withOpacity(0.1),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  width: 0.5,
                ),
                child: Center(
                  child: Icon(Icons.settings, color: textColor, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Profile Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: _isEditing ? _pickImage : null,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDark
                                            ? Colors.white24
                                            : Colors.black12,
                                      ),
                                      child: ClipOval(
                                        child:
                                            _selectedImageBytes != null &&
                                                !_removePhoto
                                            ? Image.memory(
                                                _selectedImageBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : !showNativeText
                                            ? Image.network(
                                                profile.profilePicUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.person,
                                                      size: 40,
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                    ),
                                              )
                                            : Container(
                                                color: primaryColor,
                                                alignment: Alignment.center,
                                                child: Text(
                                                  profile.username.isNotEmpty
                                                      ? profile.username[0]
                                                            .toUpperCase()
                                                      : 'U',
                                                  style: TextStyle(
                                                    color: theme
                                                        .colorScheme
                                                        .onPrimary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 36,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (_isEditing)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.black38,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_isEditing &&
                                  (!showNativeText || _selectedImageBytes != null))
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _removePhoto = true;
                                        _selectedImageBytes = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.redAccent,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Row(
                              children: [
                                if (!_isEditing)
                                  Flexible(
                                    child: Text(
                                      profile.username,
                                      style: GoogleFonts.outfit(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: TextField(
                                      controller: _usernameController,
                                      style: GoogleFonts.outfit(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Enter username",
                                        hintStyle: TextStyle(
                                          color: textColor.withOpacity(0.38),
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (!_isEditing)
                                  IconButton(
                                    icon: Icon(Icons.edit, color: primaryColor),
                                    onPressed: () =>
                                        _startEditing(profile.username),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text('Cancel', style: TextStyle(color: textColor)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GlassContainer(
                            borderRadius: 30,
                            child: ElevatedButton(
                              onPressed: _isUpdating ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: BorderSide(color: primaryColor),
                                ),
                              ),
                              child: _isUpdating
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                                      ),
                                    )
                                  : Text('Save', style: TextStyle(color: textColor)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : theme.colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      border: isDark
                          ? null
                          : const Border(
                              top: BorderSide(color: Colors.black12),
                            ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (!kIsWeb) ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        final downloadedPlaylist = {
                                          'name': 'Downloads',
                                          'songs': appProvider.downloadedSongs,
                                        };
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PlaylistScreen(
                                              playlist: downloadedPlaylist,
                                            ),
                                          ),
                                        );
                                      },
                                      child: GlassContainer(
                                        borderRadius: 16,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.teal,
                                                    Colors.green,
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.download_done,
                                                color: Theme.of(context).colorScheme.onSurface,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Downloads",
                                                    style: TextStyle(
                                                      color: textColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    "${appProvider.downloadedSongs.length}",
                                                    style: TextStyle(
                                                      color: textColor
                                                          .withOpacity(0.7),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ] else const Expanded(child: SizedBox()),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final likedSongsList = appProvider
                                          .allSongs
                                          .where(
                                            (s) => profile.likedSongs.contains(
                                              s.id,
                                            ),
                                          )
                                          .toList();
                                      final likedSongsPlaylist = {
                                        'name': 'Liked Songs',
                                        'songs': likedSongsList,
                                      };
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PlaylistScreen(
                                            playlist: likedSongsPlaylist,
                                          ),
                                        ),
                                      );
                                    },
                                    child: GlassContainer(
                                      borderRadius: 16,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Colors.pinkAccent,
                                                  Colors.redAccent,
                                                ],
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.favorite,
                                              color: Theme.of(context).colorScheme.onSurface,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Liked",
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  "${profile.likedSongs.length}",
                                                  style: TextStyle(
                                                    color: textColor
                                                        .withOpacity(0.7),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Your Playlists",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (appProvider.userPlaylists.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final playlists = appProvider.userPlaylists;
                                  int displayCount = playlists.length;
                                  bool showAllButton = false;
                                  if (displayCount > 4) {
                                    displayCount = 3;
                                    showAllButton = true;
                                  }

                                  List<Widget> gridItems = [];
                                  for (int i = 0; i < displayCount; i++) {
                                    final playlist = playlists[i];
                                    final songCount = playlist.songIds.length;
                                    gridItems.add(
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PlaylistScreen(
                                                playlist: playlist,
                                              ),
                                            ),
                                          );
                                        },
                                        onLongPress: () => _showPlaylistOptions(
                                          context,
                                          playlist,
                                          appProvider,
                                        ),
                                        child: GlassContainer(
                                          borderRadius: 16,
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                ),
                                                child: Icon(
                                                  Icons.queue_music,
                                                  color: textColor.withOpacity(
                                                    0.8,
                                                  ),
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
                                                  color: textColor.withOpacity(
                                                    0.7,
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  if (showAllButton) {
                                    gridItems.add(
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AllPlaylistsScreen(),
                                            ),
                                          );
                                        },
                                        child: GlassContainer(
                                          borderRadius: 16,
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: isDark
                                                      ? Colors.white10
                                                      : Colors.black12,
                                                ),
                                                child: Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: textColor.withOpacity(
                                                    0.8,
                                                  ),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "Show All",
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 1,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "${playlists.length} playlists",
                                                style: TextStyle(
                                                  color: textColor.withOpacity(
                                                    0.7,
                                                  ),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childAspectRatio: 0.85,
                                      children: gridItems,
                                    ),
                                  );
                                },
                              )
                            else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    "No playlists created yet",
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).colorScheme.onSurface;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Create Playlist', style: TextStyle(color: textColor)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Playlist Name',
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Provider.of<AppProvider>(
                    context,
                    listen: false,
                  ).createPlaylist(name);
                }
                Navigator.pop(context);
              },
              child: Text('Create', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final passController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Change Password',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: passController,
          obscureText: true,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Enter new password',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.cyanAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (passController.text.length >= 6) {
                  await FirebaseAuth.instance.currentUser?.updatePassword(
                    passController.text,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }
}






