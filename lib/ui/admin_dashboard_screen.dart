import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/admin_upload_service.dart';
import '../models/song_model.dart';
import '../services/player_service.dart';
import 'glassmorphic_component.dart';
import 'home_screen.dart';
import 'yt_music_player.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../utils/ui_utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey bottomMenuKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentTab = Provider.of<AppProvider>(context).adminTabIndex;
    final playerService = Provider.of<PlayerService>(context);

    final List<Widget> pages = [
      HomeScreen(
        onNavigateToProfile: () {
          Provider.of<AppProvider>(context, listen: false).setAdminTab(6);
        },
      ),
      SearchScreen(isActive: currentTab == 1),
      const _SongRequestsPage(),
      const _UploadSongPage(),
      const _NotificationsPage(),
      const _ManageSongsPage(),
      const ProfileScreen(),
    ];

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              // Gradient background
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
              IndexedStack(
                index: currentTab,
                children: pages,
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            key: bottomMenuKey,
            currentIndex: currentTab,
            onTap: (index) {
              Provider.of<AppProvider>(context, listen: false).setAdminTab(index);
            },
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.54),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.request_page_outlined),
                activeIcon: Icon(Icons.request_page),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud_upload_outlined),
                activeIcon: Icon(Icons.cloud_upload),
                label: 'Upload',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.notifications_outlined),
                activeIcon: Icon(Icons.notifications),
                label: 'Notify',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music_outlined),
                activeIcon: Icon(Icons.library_music),
                label: 'Manage',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        if (playerService.playlist.isNotEmpty && playerService.currentSong != null)
          YTMusicPlayer(hasBottomNav: true, bottomMenuKey: bottomMenuKey)
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1: SONG REQUESTS
// ═══════════════════════════════════════════════════════════════════════════════

class _SongRequestsPage extends StatefulWidget {
  const _SongRequestsPage();

  @override
  State<_SongRequestsPage> createState() => _SongRequestsPageState();
}

class _SongRequestsPageState extends State<_SongRequestsPage> {
  Set<String> _selectedDeletedIds = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome back ADMIN!',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.logout, color: Colors.redAccent.withValues(alpha: 0.8)),
                            tooltip: 'Logout',
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              Provider.of<AppProvider>(context, listen: false).logout();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.request_page, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Song Requests',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TabBar(
              indicatorColor: primaryColor,
              labelColor: primaryColor,
              unselectedLabelColor: textColor.withValues(alpha: 0.5),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Recently Deleted'),
              ],
              onTap: (index) {
                if (index == 0 && _isSelectionMode) {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedDeletedIds.clear();
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPendingList(textColor, primaryColor),
                  _buildDeletedList(textColor, primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(Color textColor, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('song_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }

        // Filtering manually as Firestore requires index for complex queries
        final docs = snapshot.data?.docs.where((doc) {
           final data = doc.data() as Map<String, dynamic>;
           return data['isDeleted'] != true;
        }).toList();
        // sort by timestamp descending
        docs?.sort((a, b) {
           final aData = a.data() as Map<String, dynamic>;
           final bData = b.data() as Map<String, dynamic>;
           final aTime = aData['timestamp'] as int? ?? 0;
           final bTime = bData['timestamp'] as int? ?? 0;
           return bTime.compareTo(aTime);
        });

        if (docs == null || docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_outlined, color: textColor.withValues(alpha: 0.3), size: 64),
                const SizedBox(height: 16),
                Text('No pending requests', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 16)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final songName = data['songName'] ?? 'Unknown';
            final movieName = data['movieName'] ?? '';
            final requesterEmail = data['requesterEmail'] ?? 'Anonymous';
            
            // Fallback to email prefix if unknown
            String requesterName = data['requesterName'] ?? 'Unknown';
            if (requesterName == 'Unknown' || requesterName == 'Listener') {
              requesterName = requesterEmail.split('@')[0];
            }

            final timestamp = data['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.3),
                            primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: Icon(Icons.music_note, color: primaryColor, size: 24),
                    ),
                    title: Text(songName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (movieName.isNotEmpty)
                          Text('Movie: $movieName', style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 14)),
                        Text('Requested by: $requesterName', style: TextStyle(color: primaryColor.withValues(alpha: 0.9), fontSize: 13)),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.email_outlined, size: 16, color: textColor.withValues(alpha: 0.6)),
                                const SizedBox(width: 8),
                                Text(requesterEmail, style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (timestamp != null)
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: textColor.withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Text(_formatDate(timestamp), style: TextStyle(color: textColor.withValues(alpha: 0.8), fontSize: 13)),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    // Soft delete
                                    await FirebaseFirestore.instance.collection('song_requests').doc(docId).update({'isDeleted': true});
                                  },
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                                GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showSelectUploadedSongDialog(context, docId, requesterEmail, songName);
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
                                  icon: const Icon(Icons.check_circle_outline, size: 20),
                                  label: const Text('Uploaded'),
                                )      ),
                                GlassContainer(
        borderRadius: 30, // Or extract from button if needed
        child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Switch to Upload Tab and prefill data
                                    Provider.of<AppProvider>(context, listen: false)
                                        .setAdminTab(3, request: {
                                      'id': docId,
                                      'songName': songName,
                                      'movieName': movieName,
                                      'requesterName': requesterName,
                                      'requesterEmail': requesterEmail,
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0),
                                  icon: const Icon(Icons.upload, size: 20),
                                  label: const Text('Upload Song'),
                                )      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  Widget _buildDeletedList(Color textColor, Color primaryColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('song_requests')
          .where('isDeleted', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
        }

        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_delete_outlined, color: textColor.withValues(alpha: 0.3), size: 64),
                const SizedBox(height: 16),
                Text('No deleted requests', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 16)),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                color: primaryColor.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Text('${_selectedDeletedIds.length} Selected', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedDeletedIds.length == docs.length) {
                            _selectedDeletedIds.clear();
                          } else {
                            _selectedDeletedIds = docs.map((d) => d.id).toSet();
                          }
                        });
                      },
                      child: Text(_selectedDeletedIds.length == docs.length ? 'Deselect All' : 'Select All', style: TextStyle(color: primaryColor)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.greenAccent),
                      tooltip: 'Undo (Restore)',
                      onPressed: _selectedDeletedIds.isEmpty ? null : () async {
                        for (String id in _selectedDeletedIds) {
                          await FirebaseFirestore.instance.collection('song_requests').doc(id).update({'isDeleted': false});
                        }
                        setState(() {
                          _isSelectionMode = false;
                          _selectedDeletedIds.clear();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      tooltip: 'Delete Permanently',
                      onPressed: _selectedDeletedIds.isEmpty ? null : () async {
                        for (String id in _selectedDeletedIds) {
                          await FirebaseFirestore.instance.collection('song_requests').doc(id).delete();
                        }
                        setState(() {
                          _isSelectionMode = false;
                          _selectedDeletedIds.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  final songName = data['songName'] ?? 'Unknown';
                  final requesterEmail = data['requesterEmail'] ?? 'Anonymous';
                  
                  String requesterName = data['requesterName'] ?? 'Unknown';
                  if (requesterName == 'Unknown' || requesterName == 'Listener') {
                    requesterName = requesterEmail.split('@')[0];
                  }
                  final isSelected = _selectedDeletedIds.contains(docId);

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _isSelectionMode = true;
                        _selectedDeletedIds.add(docId);
                      });
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedDeletedIds.remove(docId);
                            if (_selectedDeletedIds.isEmpty) _isSelectionMode = false;
                          } else {
                            _selectedDeletedIds.add(docId);
                          }
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: isSelected ? Border.all(color: primaryColor, width: 2) : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            if (_isSelectionMode)
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedDeletedIds.add(docId);
                                    } else {
                                      _selectedDeletedIds.remove(docId);
                                      if (_selectedDeletedIds.isEmpty) _isSelectionMode = false;
                                    }
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(songName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(height: 4),
                                  Text('Requested by: $requesterName', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13)),
                                ],
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
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showSelectUploadedSongDialog(BuildContext context, String docId, String userEmail, String requestedSongName) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredSongs = appProvider.allSongs
                .where((s) => s.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
                              s.artist.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();
            
            return AlertDialog(
              title: const Text('Select Uploaded Song'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search songs...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(song.coverUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.music_note)),
                            ),
                            title: Text(song.title, maxLines: 1),
                            subtitle: Text(song.artist, maxLines: 1),
                            onTap: () async {
                              // Mark request as deleted (soft delete)
                              await FirebaseFirestore.instance.collection('song_requests').doc(docId).update({'isDeleted': true});
                              
                              // Send notification
                              await FirebaseFirestore.instance.collection('notifications').add({
                                'userId': userEmail,
                                'title': 'Song Uploaded',
                                'message': 'Your requested song "$requestedSongName" has been uploaded! Tap to play.',
                                'songId': song.id,
                                'timestamp': DateTime.now().millisecondsSinceEpoch,
                                'isRead': false,
                                'readBy': [],
                              });
                              
                              if (context.mounted) {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder: (ctx) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: GlassContainer(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Song marked as uploaded and notification sent!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 24),
                                          GlassContainer(
                                            borderRadius: 30,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                elevation: 0,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                              ),
                                              child: const Text('OK'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ],
            );
          }
        );
      }
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2: UPLOAD SONG
// ═══════════════════════════════════════════════════════════════════════════════

class _UploadSongPage extends StatefulWidget {
  const _UploadSongPage();

  @override
  State<_UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends State<_UploadSongPage> {
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final AdminUploadService _uploadService = AdminUploadService();

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  bool _isTrending = false;
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context);
    final request = provider.selectedRequestForUpload;
    if (request != null) {
      if (_titleController.text.isEmpty && request['songName'] != null) {
        _titleController.text = request['songName'];
      }
      if (_artistController.text.isEmpty && request['movieName'] != null) {
        // artist controller is no longer pre-filled by movieName
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFileName = result.files.first.name;
        _selectedFileBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _uploadSong() async {
    if (_titleController.text.trim().isEmpty ||
        _artistController.text.trim().isEmpty) {
      _snack('Please enter title and artist.');
      return;
    }
    if (_selectedFileBytes == null) {
      _snack('Please select an audio file.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.2;
    });

    try {
      // Upload to Cloudinary
      setState(() => _uploadProgress = 0.4);
      final audioUrl = await _uploadService.uploadAudioBytes(
        _selectedFileBytes!,
        _selectedFileName!,
      );

      if (audioUrl == null) {
        _snack('Audio upload failed. Check Cloudinary settings.');
        setState(() => _isUploading = false);
        return;
      }

      setState(() => _uploadProgress = 0.7);

      // Save to Firestore
      final songId = await _uploadService.saveSongMetadata(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        coverUrl: _coverUrlController.text.trim(),
        audioUrl: audioUrl,
        isTrending: _isTrending,
      );

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        final provider = Provider.of<AppProvider>(context, listen: false);
        provider.fetchSongs();
        _snack('Song uploaded successfully!');
        
        final req = provider.selectedRequestForUpload;
        if (req != null) {
          try {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': req['requesterEmail'],
              'title': 'Song Uploaded',
              'message': 'Hey ${req['requesterName']}, the song you requested "${req['songName']}" was added to the library! Check it out!',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'isRead': false,
              'readBy': <String>[],
              'songId': songId,
            });
            await FirebaseFirestore.instance.collection('song_requests').doc(req['id']).delete();
            provider.clearSelectedRequest();
            _snack('Request fulfilled and user notified!');
          } catch (e) {
            _snack('Failed to notify user: $e');
          }
        }
      }

      // Reset form
      setState(() {
        _titleController.clear();
        _artistController.clear();
        _coverUrlController.clear();
        _selectedFileName = null;
        _selectedFileBytes = null;
        _isTrending = false;
        _isUploading = false;
        _uploadProgress = 0;
      });
    } catch (e) {
      _snack('Upload failed: $e');
      setState(() => _isUploading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    UIUtils.showPopup(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Upload Song',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Audio File Picker
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploading ? null : _pickAudioFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        color: primaryColor.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFileName != null
                                ? Icons.audio_file
                                : Icons.add_circle_outline,
                            color: primaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFileName ?? 'Tap to select audio file',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Song Details
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildField(_titleController, 'Song Title', Icons.title,
                      textColor, primaryColor),
                  const SizedBox(height: 16),
                  _buildField(_artistController, 'Artist Name', Icons.person,
                      textColor, primaryColor),
                  const SizedBox(height: 16),
                  _buildField(_coverUrlController, 'Cover Image URL (optional)',
                      Icons.image, textColor, primaryColor),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: _isTrending,
                        onChanged: (val) =>
                            setState(() => _isTrending = val),
                        activeColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Add to Recently Added List',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Upload Progress
            if (_isUploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toInt()}% uploaded',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Upload Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: GlassContainer(
                borderRadius: 30,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadSong,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, 
                    shadowColor: Colors.transparent, 
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Upload Song',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      IconData icon, Color textColor, Color primaryColor) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
        prefixIcon: Icon(icon, color: primaryColor, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3: PUSH NOTIFICATIONS
// ═══════════════════════════════════════════════════════════════════════════════

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String? _selectedSongId;
  String? _selectedSongTitle;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickSong() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final songs = appProvider.allSongs;

    final song = await showModalBottomSheet<Song>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = songs.where((s) {
              final q = search.toLowerCase();
              return s.title.toLowerCase().contains(q) ||
                  s.artist.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select a Song',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search songs...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search,
                            color: Colors.cyanAccent, size: 20),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setSheetState(() => search = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: s.coverUrl.isNotEmpty
                                ? Image.network(
                                    s.coverUrl,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 44,
                                      height: 44,
                                      color: Colors.white10,
                                      child: const Icon(Icons.music_note,
                                          color: Colors.white24),
                                    ),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.white10,
                                    child: const Icon(Icons.music_note,
                                        color: Colors.white24),
                                  ),
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            s.artist,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, s),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (song != null) {
      setState(() {
        _selectedSongId = song.id;
        _selectedSongTitle = '${song.title} - ${song.artist}';
      });
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      _snack('Please enter title and message.');
      return;
    }

    setState(() => _isSending = true);

    try {
      final notifData = <String, dynamic>{
        'userId': 'global',
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'readBy': <String>[],
      };

      if (_selectedSongId != null) {
        notifData['songId'] = _selectedSongId;
      }

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notifData);

      _snack('Notification sent to all users!');

      setState(() {
        _titleController.clear();
        _messageController.clear();
        _selectedSongId = null;
        _selectedSongTitle = null;
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _snack('Permission denied. Please update Firebase Rules to send notifications.');
      } else {
        _snack('Failed: ${e.message}');
      }
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendRandomSuggestion() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final songs = appProvider.allSongs;
    if (songs.isEmpty) {
      _snack('No songs available to suggest.');
      return;
    }

    songs.shuffle();
    final song = songs.first;

    setState(() => _isSending = true);
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': 'global',
        'title': '🎵 Song Suggestion',
        'message':
            'Check out "${song.title}" by ${song.artist}. Tap to listen now!',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isRead': false,
        'readBy': <String>[],
        'songId': song.id,
      });
      _snack('Random suggestion sent for "${song.title}"!');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _snack('Permission denied. Please update Firebase Rules to send notifications.');
      } else {
        _snack('Failed: ${e.message}');
      }
    } catch (e) {
      _snack('Failed: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    UIUtils.showPopup(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Action: Random Song Suggestion
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: Colors.amber, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isSending ? null : _sendRandomSuggestion,
                      icon: const Icon(Icons.shuffle, size: 20),
                      label: const Text('Send Random Song Suggestion'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amber,
                        side: const BorderSide(color: Colors.amber, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Custom Notification Form
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_notifications,
                          color: primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Custom Notification',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Notification Title',
                      hintStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.4)),
                      prefixIcon: Icon(Icons.title,
                          color: primaryColor, size: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _messageController,
                    style: TextStyle(color: textColor),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Message / Description',
                      hintStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.4)),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.message,
                            color: primaryColor, size: 20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: textColor.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Attach Song (optional)
                  GestureDetector(
                    onTap: _pickSong,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSongId != null
                              ? Colors.green.withValues(alpha: 0.5)
                              : textColor.withValues(alpha: 0.2),
                        ),
                        color: _selectedSongId != null
                            ? Colors.green.withValues(alpha: 0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedSongId != null
                                ? Icons.check_circle
                                : Icons.link,
                            color: _selectedSongId != null
                                ? Colors.green
                                : primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedSongTitle ??
                                  'Attach a song (tap to play on click)',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedSongId != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSongId = null;
                                  _selectedSongTitle = null;
                                });
                              },
                              child: const Icon(Icons.close,
                                  color: Colors.white38, size: 18),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: GlassContainer(
                      borderRadius: 30,
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendNotification,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.send, size: 20),
                        label: Text(
                          _isSending ? 'Sending...' : 'Send to All Users',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4: MANAGE SONGS
// ═══════════════════════════════════════════════════════════════════════════════

class _ManageSongsPage extends StatefulWidget {
  const _ManageSongsPage();

  @override
  State<_ManageSongsPage> createState() => _ManageSongsPageState();
}

class _ManageSongsPageState extends State<_ManageSongsPage> {
  final AdminUploadService _uploadService = AdminUploadService();
  String _searchQuery = '';
  bool _isSelectionMode = false;
  Set<String> _selectedSongIds = {};

  Future<void> _deleteSelectedSongs() async {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('Delete ${_selectedSongIds.length} Songs?', style: TextStyle(color: textColor)),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (String id in _selectedSongIds) {
          await _uploadService.deleteSong(id);
        }
        if (mounted) {
          Provider.of<AppProvider>(context, listen: false).fetchSongs();
          setState(() {
            _isSelectionMode = false;
            _selectedSongIds.clear();
          });
          _snack('${_selectedSongIds.length} songs deleted.');
        }
      } catch (e) {
        _snack('Delete failed: $e');
      }
    }
  }

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
          style: TextStyle(color: textColor.withValues(alpha: 0.7)),
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
                _buildEditField(
                    titleController, 'Title', textColor, primaryColor),
                const SizedBox(height: 12),
                _buildEditField(
                    artistController, 'Artist', textColor, primaryColor),
                const SizedBox(height: 12),
                _buildEditField(
                    coverController, 'Cover URL', textColor, primaryColor),
                const SizedBox(height: 12),
                _buildEditField(
                    audioController, 'Audio URL', textColor, primaryColor),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text(
                    'Mark as Recently Added',
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
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
                    Provider.of<AppProvider>(context, listen: false)
                        .fetchSongs();
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

  Widget _buildEditField(TextEditingController controller, String label,
      Color textColor, Color primaryColor) {
    return TextField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    UIUtils.showPopup(context, msg);
  }

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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Icon(Icons.library_music, color: primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Manage Songs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${appProvider.allSongs.length} songs',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('${_selectedSongIds.length} Selected', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedSongIds.length == songs.length) {
                            _selectedSongIds.clear();
                          } else {
                            _selectedSongIds = songs.map((s) => s.id).toSet();
                          }
                        });
                      },
                      child: Text(_selectedSongIds.length == songs.length ? 'Deselect All' : 'Select All', style: TextStyle(color: primaryColor)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      tooltip: 'Delete Selected',
                      onPressed: _selectedSongIds.isEmpty ? null : _deleteSelectedSongs,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassContainer(
                child: TextField(
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    hintStyle:
                        TextStyle(color: textColor.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.search, color: primaryColor, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                final isSelected = _selectedSongIds.contains(song.id);
                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedSongIds.add(song.id);
                    });
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      setState(() {
                        if (isSelected) {
                          _selectedSongIds.remove(song.id);
                          if (_selectedSongIds.isEmpty) {
                            _isSelectionMode = false;
                          }
                        } else {
                          _selectedSongIds.add(song.id);
                        }
                      });
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Container(
                        decoration: isSelected
                            ? BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryColor, width: 1),
                              )
                            : null,
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: song.coverUrl.isEmpty
                                ? Container(
                                    color: isDark ? Colors.white24 : Colors.black26,
                                    width: 48,
                                    height: 48,
                                    child: const Icon(Icons.music_note),
                                  )
                                : Image.network(
                                    song.coverUrl,
                                    width: 48,
                                    height: 48,
                                    cacheWidth: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: isDark ? Colors.white24 : Colors.black26,
                                      width: 48,
                                      height: 48,
                                      child: const Icon(Icons.music_note),
                                    ),
                                  ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (song.isTrending)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(Icons.trending_up, color: Colors.amber, size: 18),
                                ),
                              IconButton(
                                icon: Icon(Icons.edit_outlined, color: primaryColor, size: 20),
                                onPressed: _isSelectionMode ? null : () => _editSong(song),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: _isSelectionMode ? null : () => _deleteSong(song.id),
                              ),
                            ],
                          ),
                        ),
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

