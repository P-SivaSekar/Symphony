import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/song_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlayerService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  List<Song> _playlist = [];
  final Set<String> _resolvedSessionSongIds = {};
  int _currentIndex = 0;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isInitialized = false;
  final List<String> _playNextOverrideIds = [];
  bool _isConsumingAutoplay = false;
  Future<Song> Function(Song)? songResolver;

  AudioPlayer get audioPlayer => _audioPlayer;
  List<Song> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  Song? get currentSong =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length
      ? _playlist[_currentIndex]
      : null;

  bool get hasNext => _audioPlayer.hasNext || _autoplayEnabled;
  bool get hasPrevious => _audioPlayer.hasPrevious;

  Map<String, String>? _getPlayHeaders(String url) {
    if (kIsWeb) return null;
    if (url.contains('saavncdn.com') || url.contains('saavn')) {
      return const {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://www.jiosaavn.com/',
      };
    }
    return null;
  }

  String _getPlayableUrl(String url) {
    if (kIsWeb && (url.contains('saavncdn.com') || url.contains('saavn'))) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  // Play history callback
  void Function(Song)? onSongPlayed;

  PlayerService() {
    _initPlayer();
  }

  Future<void> _savePlayerState() async {
    if (_playlist.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> playlistMap = _playlist.map((s) {
        final map = s.toMap();
        map['id'] = s.id;
        return map;
      }).toList();
      await prefs.setString('saved_playlist', jsonEncode(playlistMap));
      await prefs.setInt('saved_index', _currentIndex);
    } catch (e) {
      print('Error saving player state: $e');
    }
  }

  Future<void> _savePlayerIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('saved_index', _currentIndex);
    } catch (e) {
      print('Error saving player index: $e');
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlaylistStr = prefs.getString('saved_playlist');
      final savedIndex = prefs.getInt('saved_index') ?? 0;
      final savedAutoplay = prefs.getBool('autoplay_enabled');
      if (savedAutoplay != null) _autoplayEnabled = savedAutoplay;
      if (savedPlaylistStr != null) {
        final List<dynamic> decoded = jsonDecode(savedPlaylistStr);
        final List<Song> savedSongs = decoded.map((e) {
          final map = Map<String, dynamic>.from(e);
          return Song.fromMap(map, map['id'] ?? '');
        }).toList();
        if (savedSongs.isNotEmpty) {
          _playlist = savedSongs;
          _currentIndex = savedIndex < savedSongs.length ? savedIndex : 0;

          final audioSource = ConcatenatingAudioSource(
            children: savedSongs.map((s) {
              return AudioSource.uri(
                Uri.parse(_getPlayableUrl(s.audioUrl)),
                headers: _getPlayHeaders(s.audioUrl),
                tag: MediaItem(
                  id: s.id,
                  album: "Symphony",
                  title: s.title,
                  artist: s.artist,
                  artUri:
                      (s.coverUrl.isNotEmpty &&
                          !s.coverUrl.startsWith('asset:'))
                      ? Uri.parse(s.coverUrl)
                      : null,
                ),
              );
            }).toList(),
          );
          await _audioPlayer.setAudioSource(
            audioSource,
            initialIndex: _currentIndex,
            initialPosition: Duration.zero,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error loading saved state: $e');
    }
  }

  List<Song> _sessionHistory = [];
  List<Song> get sessionHistory => _sessionHistory;

  List<Song> get effectivePlaylist {
    if (_playlist.isEmpty) return [];
    final indices = _audioPlayer.effectiveIndices ?? [];
    if (indices.length != _playlist.length) {
      if (_currentIndex >= 0 && _currentIndex < _playlist.length) {
        return _playlist.sublist(_currentIndex);
      }
      return _playlist;
    }
    final curEffIdx = currentEffectiveIndex;
    if (curEffIdx < 0 || curEffIdx >= indices.length) return _playlist;
    return indices
        .sublist(curEffIdx)
        .where((i) => i >= 0 && i < _playlist.length)
        .map((i) => _playlist[i])
        .toList();
  }

  List<Song> get fullEffectivePlaylist {
    if (_playlist.isEmpty) return [];
    final indices = _audioPlayer.effectiveIndices ?? [];
    if (indices.length != _playlist.length) return _playlist;
    return indices
        .where((i) => i >= 0 && i < _playlist.length)
        .map((i) => _playlist[i])
        .toList();
  }

  int get currentEffectiveIndex {
    if (_playlist.isEmpty) return 0;
    final indices = _audioPlayer.effectiveIndices ?? [];
    if (indices.isEmpty) return _currentIndex;
    final index = indices.indexOf(_currentIndex);
    return index == -1 ? 0 : index;
  }

  bool _isShuffleModeEnabled = false;
  LoopMode _loopMode = LoopMode.off;
  bool _autoplayEnabled = true;
  List<Song> _autoplayQueue = [];
  List<Song> get autoplayQueue => _autoplayQueue;

  void populateAutoplayQueue(List<Song> allSongs) {
    if (_autoplayQueue.length < 10) {
      final available = allSongs.where((s) => !_autoplayQueue.any((aq) => aq.id == s.id)).toList();
      available.shuffle();
      _autoplayQueue.addAll(available.take(10 - _autoplayQueue.length));
      notifyListeners();
    }
  }

  Future<void> consumeAutoplay(List<Song> allSongs, {bool forcePlay = false}) async {
    if (_isConsumingAutoplay) return;
    _isConsumingAutoplay = true;
    try {
      if (_autoplayQueue.isEmpty) populateAutoplayQueue(allSongs);
      if (_autoplayQueue.isNotEmpty) {
        final song = _autoplayQueue.removeAt(0);
        await addToQueue(song);
        
        if (forcePlay || _audioPlayer.processingState == ProcessingState.completed) {
          final newIndex = _playlist.length - 1;
          await Future.delayed(const Duration(milliseconds: 300));
          await _audioPlayer.seek(Duration.zero, index: newIndex);
          await play();
        }
        populateAutoplayQueue(allSongs);
      }
    } finally {
      _isConsumingAutoplay = false;
    }
  }
  void Function({bool forcePlay})? onQueueEmpty;

  bool get isShuffleModeEnabled => _isShuffleModeEnabled;
  LoopMode get loopMode => _loopMode;
  bool get autoplayEnabled => _autoplayEnabled;

  Future<void> toggleAutoplay() async {
    _autoplayEnabled = !_autoplayEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoplay_enabled', _autoplayEnabled);
    notifyListeners();
  }

  Future<void> _initPlayer() async {
    // Small delay to ensure JustAudioBackground is fully ready
    await Future.delayed(const Duration(milliseconds: 500));
    _audioPlayer = AudioPlayer();

    await _loadSavedState();

    _isInitialized = true;

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
      if (state.processingState == ProcessingState.completed) {
        if (_playNextOverrideIds.isNotEmpty) {
          final nextId = _playNextOverrideIds.removeAt(0);
          final index = _playlist.indexWhere((s) => s.id == nextId);
          if (index != -1) {
            _audioPlayer.seek(Duration.zero, index: index);
            return;
          }
        }
        if (_loopMode == LoopMode.off && !_audioPlayer.hasNext) {
          if (_autoplayEnabled && onQueueEmpty != null) {
            onQueueEmpty!(forcePlay: true);
          } else {
            // If we reached the end and not looping, stop. JustAudio handles looping internally.
            _audioPlayer.pause();
            _audioPlayer.seek(Duration.zero, index: 0);
          }
        } else if (_loopMode == LoopMode.all && !_audioPlayer.hasNext) {
          _audioPlayer.seek(Duration.zero, index: 0);
          _audioPlayer.play();
        }
      }
    });

    _audioPlayer.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      print('A playback error occurred: $e');
      // Do not automatically skip to the next song, as this can cause the entire playlist to be skipped if the device goes offline.
      _isPlaying = false;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      // Removed notifyListeners() to prevent UI lag on every position tick
    });

    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index != _currentIndex && index < _playlist.length) {
        _currentIndex = index;

        // Add to session history if it's a new song play
        final song = _playlist[_currentIndex];
        if (_sessionHistory.isEmpty || _sessionHistory.last.id != song.id) {
          _sessionHistory.add(song);
          onSongPlayed?.call(song);
        }

        _savePlayerIndex();
        notifyListeners();

        // Dynamically resolve adjacent (next/prev) tracks on track transition
        _preloadAdjacentSongs(index);
      } else if (index != null &&
          _sessionHistory.isEmpty &&
          index < _playlist.length) {
        // First song loaded
        final song = _playlist[index];
        _sessionHistory.add(song);
        onSongPlayed?.call(song);
        notifyListeners();

        // Preload next track for the first song
        _preloadAdjacentSongs(index);
      }
    });

    _audioPlayer.shuffleModeEnabledStream.listen((enabled) {
      _isShuffleModeEnabled = enabled;
      notifyListeners();
    });

    _audioPlayer.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    _audioPlayer.sequenceStateStream.listen((state) {
      notifyListeners(); // Notify when effective sequence changes (e.g., shuffle)
    });
  }

  Future<void> loadPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    Song? targetSong;
    if (initialIndex >= 0 && initialIndex < songs.length) {
      targetSong = songs[initialIndex];
    }

    // Keep all songs, as JioSaavn tracks might have empty audioUrl initially and will be resolved.
    final validSongs = songs;
    if (validSongs.isEmpty) return;

    int newIndex = 0;
    if (targetSong != null) {
      final targetId = targetSong.id;
      newIndex = validSongs.indexWhere((s) => s.id == targetId);
      if (newIndex == -1) newIndex = 0;
    }

    // Set player playlist state synchronously first so that the UI updates instantly
    _playlist = validSongs;
    _resolvedSessionSongIds.clear();
    _currentIndex = newIndex;
    _sessionHistory.clear(); // Clear history when loading new playlist
    notifyListeners();

    try {
      print(
        "Loading playlist asynchronously with ${validSongs.length} songs at index $_currentIndex",
      );

      // If the target song needs resolution (e.g. has empty or expired JioSaavn audioUrl), resolve it synchronously first
      if (validSongs.isNotEmpty && _currentIndex < validSongs.length) {
        final currentSong = validSongs[_currentIndex];
        final isPermanent = currentSong.audioUrl.isNotEmpty && 
            (currentSong.audioUrl.startsWith('file://') || currentSong.audioUrl.contains("cloudinary.com"));
        final needsSyncResolve = !isPermanent;

        if (needsSyncResolve && songResolver != null) {
          try {
            print("Target song needs fresh resolution. Resolving synchronously before playback...");
            final resolved = await songResolver!(currentSong);
            _resolvedSessionSongIds.add(resolved.id);
            if (_playlist.length > _currentIndex && _playlist[_currentIndex].id == currentSong.id) {
              _playlist[_currentIndex] = resolved;
            }
          } catch (e) {
            print("Error resolving initial song synchronously: $e");
          }
        }
      }

      final audioSource = ConcatenatingAudioSource(
        children: _playlist.map((s) {
          final url = s.audioUrl.isEmpty ? "https://placeholder.com/empty.mp3" : s.audioUrl;
          return AudioSource.uri(
            Uri.parse(_getPlayableUrl(url)),
            headers: _getPlayHeaders(url),
            tag: MediaItem(
              id: s.id,
              album: "Symphony",
              title: s.title,
              artist: s.artist,
              artUri:
                  (s.coverUrl.isNotEmpty && !s.coverUrl.startsWith('asset:'))
                  ? Uri.parse(s.coverUrl)
                  : null,
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(
        audioSource,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );

      if (kIsWeb) {
        await _audioPlayer.seek(Duration.zero, index: _currentIndex);
      }
      print("Audio source set successfully");
      _savePlayerState();
      notifyListeners();
      await play();

      // Trigger background resolution of adjacent songs (next and previous tracks)
      _preloadAdjacentSongs(_currentIndex);
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Future<void> seekToTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final song = _playlist[index];
    if (songResolver != null && 
        !song.audioUrl.startsWith('file://') && 
        !song.audioUrl.contains("cloudinary.com")) {
      try {
        final resolved = await songResolver!(song);
        _playlist[index] = resolved;
        final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
        if (source != null && source.length > index) {
          if (!_resolvedSessionSongIds.contains(resolved.id)) {
            _resolvedSessionSongIds.add(resolved.id);
            await source.removeAt(index);
            await source.insert(
              index,
              AudioSource.uri(
                Uri.parse(_getPlayableUrl(resolved.audioUrl)),
                headers: _getPlayHeaders(resolved.audioUrl),
                tag: MediaItem(
                  id: resolved.id,
                  album: "Symphony",
                  title: resolved.title,
                  artist: resolved.artist,
                  artUri: (resolved.coverUrl.isNotEmpty && !resolved.coverUrl.startsWith('asset:'))
                      ? Uri.parse(resolved.coverUrl)
                      : null,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print("Error resolving track on seek: $e");
      }
    }
    await _audioPlayer.seek(Duration.zero, index: index);
  }

  Future<void> _preloadAdjacentSongs(int currentIndex) async {
    if (songResolver == null) return;
    
    final indices = _audioPlayer.effectiveIndices;
    if (indices == null || indices.isEmpty) return;

    final effectiveIndex = indices.indexOf(currentIndex);
    if (effectiveIndex == -1) return;

    // 1. Preload the next track in the effective sequence
    final nextEffective = effectiveIndex + 1;
    if (nextEffective < indices.length) {
      final nextIndex = indices[nextEffective];
      final song = _playlist[nextIndex];
      if (!song.audioUrl.startsWith('file://') && !song.audioUrl.contains("cloudinary.com")) {
        try {
          final resolved = await songResolver!(song);
          if (_playlist.length > nextIndex && _playlist[nextIndex].id == song.id) {
            _playlist[nextIndex] = resolved;
            final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
            if (source != null && source.length > nextIndex) {
              if (!_resolvedSessionSongIds.contains(resolved.id)) {
                _resolvedSessionSongIds.add(resolved.id);
                await source.removeAt(nextIndex);
                if (source.length >= nextIndex) {
                  await source.insert(
                    nextIndex,
                    AudioSource.uri(
                      Uri.parse(_getPlayableUrl(resolved.audioUrl)),
                      headers: _getPlayHeaders(resolved.audioUrl),
                      tag: MediaItem(
                        id: resolved.id,
                        album: "Symphony",
                        title: resolved.title,
                        artist: resolved.artist,
                        artUri: (resolved.coverUrl.isNotEmpty && !resolved.coverUrl.startsWith('asset:'))
                            ? Uri.parse(resolved.coverUrl)
                            : null,
                      ),
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          print("Error preloading next song at $nextIndex: $e");
        }
      }
    }

    // 2. Preload the previous track in the effective sequence
    final prevEffective = effectiveIndex - 1;
    if (prevEffective >= 0) {
      final prevIndex = indices[prevEffective];
      final song = _playlist[prevIndex];
      if (!song.audioUrl.startsWith('file://') && !song.audioUrl.contains("cloudinary.com")) {
        try {
          final resolved = await songResolver!(song);
          if (_playlist.length > prevIndex && _playlist[prevIndex].id == song.id) {
            _playlist[prevIndex] = resolved;
            final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
            if (source != null && source.length > prevIndex) {
              if (!_resolvedSessionSongIds.contains(resolved.id)) {
                _resolvedSessionSongIds.add(resolved.id);
                await source.removeAt(prevIndex);
                if (source.length >= prevIndex) {
                  await source.insert(
                    prevIndex,
                    AudioSource.uri(
                      Uri.parse(_getPlayableUrl(resolved.audioUrl)),
                      headers: _getPlayHeaders(resolved.audioUrl),
                      tag: MediaItem(
                        id: resolved.id,
                        album: "Symphony",
                        title: resolved.title,
                        artist: resolved.artist,
                        artUri: (resolved.coverUrl.isNotEmpty && !resolved.coverUrl.startsWith('asset:'))
                            ? Uri.parse(resolved.coverUrl)
                            : null,
                      ),
                    ),
                  );
                }
              }
            }
          }
        } catch (e) {
          print("Error preloading prev song at $prevIndex: $e");
        }
      }
    }
  }

  Future<void> addNext(Song song) async {
    Song resolvedSong = song;
    if (songResolver != null && 
        !song.audioUrl.startsWith('file://') && 
        !song.audioUrl.contains("cloudinary.com")) {
      try {
        resolvedSong = await songResolver!(song);
      } catch (e) {
        print("Error resolving in addNext: $e");
      }
    }

    _playNextOverrideIds.add(resolvedSong.id);
    if (_playlist.isEmpty) {
      await loadPlaylist([resolvedSong]);
      return;
    }

    final insertIndex = _currentIndex + 1;
    _playlist.insert(insertIndex, resolvedSong);

    final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
    if (source != null) {
      await source.insert(
        insertIndex,
        AudioSource.uri(
          Uri.parse(_getPlayableUrl(resolvedSong.audioUrl)),
          headers: _getPlayHeaders(resolvedSong.audioUrl),
          tag: MediaItem(
            id: resolvedSong.id,
            album: "Symphony",
            title: resolvedSong.title,
            artist: resolvedSong.artist,
            artUri:
                (resolvedSong.coverUrl.isNotEmpty &&
                    !resolvedSong.coverUrl.startsWith('asset:'))
                ? Uri.parse(resolvedSong.coverUrl)
                : null,
          ),
        ),
      );
    }
    _savePlayerState();
    notifyListeners();
  }

  Future<void> addToQueue(Song song) async {
    Song resolvedSong = song;
    if (songResolver != null && 
        !song.audioUrl.startsWith('file://') && 
        !song.audioUrl.contains("cloudinary.com")) {
      try {
        resolvedSong = await songResolver!(song);
      } catch (e) {
        print("Error resolving in addToQueue: $e");
      }
    }

    if (_playlist.isEmpty) {
      await loadPlaylist([resolvedSong]);
      return;
    }

    _playlist.add(resolvedSong);

    final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
    if (source != null) {
      await source.add(
        AudioSource.uri(
          Uri.parse(_getPlayableUrl(resolvedSong.audioUrl)),
          headers: _getPlayHeaders(resolvedSong.audioUrl),
          tag: MediaItem(
            id: resolvedSong.id,
            album: "Symphony",
            title: resolvedSong.title,
            artist: resolvedSong.artist,
            artUri:
                (resolvedSong.coverUrl.isNotEmpty &&
                    !resolvedSong.coverUrl.startsWith('asset:'))
                ? Uri.parse(resolvedSong.coverUrl)
                : null,
          ),
        ),
      );
    }
    _savePlayerState();
    notifyListeners();
  }

  Future<void> play() async {
    await _audioPlayer.play();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> toggleShuffle([List<Song>? allSongs]) async {
    final newMode = !_isShuffleModeEnabled;

    if (newMode && allSongs != null) {
      final currentSongIds = _playlist.map((s) => s.id).toSet();
      final songsToAdd = allSongs
          .where((s) => !currentSongIds.contains(s.id) && s.audioUrl.isNotEmpty)
          .toList();

      if (songsToAdd.isNotEmpty) {
        _playlist.addAll(songsToAdd);

        final newAudioSources = songsToAdd.map((s) {
          return AudioSource.uri(
            Uri.parse(_getPlayableUrl(s.audioUrl)),
            headers: _getPlayHeaders(s.audioUrl),
            tag: MediaItem(
              id: s.id,
              album: "Symphony",
              title: s.title,
              artist: s.artist,
              artUri:
                  (s.coverUrl.isNotEmpty && !s.coverUrl.startsWith('asset:'))
                  ? Uri.parse(s.coverUrl)
                  : null,
            ),
          );
        }).toList();

        final concatenatingSource =
            _audioPlayer.audioSource as ConcatenatingAudioSource?;
        if (concatenatingSource != null) {
          await concatenatingSource.addAll(newAudioSources);
        }
      }
    }

    await _audioPlayer.setShuffleModeEnabled(newMode);
    if (newMode) {
      await _audioPlayer.shuffle();
    }
  }

  Future<void> setShuffle(bool value) async {
    if (_isShuffleModeEnabled == value) return;
    await _audioPlayer.setShuffleModeEnabled(value);
    if (value) {
      await _audioPlayer.shuffle();
    }
  }

  Future<void> toggleRepeat() async {
    if (_loopMode == LoopMode.off) {
      await _audioPlayer.setLoopMode(LoopMode.all);
      _loopMode = LoopMode.all;
    } else if (_loopMode == LoopMode.all) {
      await _audioPlayer.setLoopMode(LoopMode.one);
      _loopMode = LoopMode.one;
    } else {
      await _audioPlayer.setLoopMode(LoopMode.off);
      _loopMode = LoopMode.off;
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    await seek(newPosition > _totalDuration ? _totalDuration : newPosition);
  }

  Future<void> skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    await seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  Future<void> skipNext() async {
    if (!_audioPlayer.hasNext && _autoplayEnabled && onQueueEmpty != null) {
      onQueueEmpty!(forcePlay: true);
    } else if (_audioPlayer.hasNext) {
      final nextIdx = _audioPlayer.nextIndex;
      if (nextIdx != null) {
        await seekToTrack(nextIdx);
      }
      await play();
    } else {
      if (_loopMode == LoopMode.all) {
        await _audioPlayer.seek(Duration.zero, index: 0);
        await play();
      } else {
        await _audioPlayer.seek(Duration.zero, index: 0);
        await pause();
      }
    }
  }

  Future<void> skipPrevious() async {
    if (_audioPlayer.hasPrevious) {
      final prevIdx = _audioPlayer.previousIndex;
      if (prevIdx != null) {
        await seekToTrack(prevIdx);
      }
    } else {
      await seek(Duration.zero);
    }
    await play();
  }

  Future<void> playNext() => skipNext();
  Future<void> playPrevious() => skipPrevious();

  Future<void> removeFromQueue(int index) async {
    if (_playlist.isEmpty || index < 0 || index >= _playlist.length) return;
    
    _playlist.removeAt(index);
    final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
    if (source != null) {
      await source.removeAt(index);
    }
    
    if (_currentIndex > index) {
      _currentIndex--;
    }
    
    _savePlayerState();
    notifyListeners();
  }



  Future<void> moveToTop(int index) async {
    await reorderQueue(index, 0);
  }

  Future<void> moveToNext(int index) async {
    int targetIndex = _currentIndex + 1;
    if (index > _currentIndex) {
      await reorderQueue(index, targetIndex);
    } else {
      await reorderQueue(index, _currentIndex);
    }
  }

  Future<void> moveToBottom(int index) async {
    await reorderQueue(index, _playlist.length - 1);
  }

  Future<void> moveToPrevious(int index) async {
    int targetIndex = _currentIndex;
    if (targetIndex < 0) targetIndex = 0;
    
    if (index > _currentIndex) {
      await reorderQueue(index, targetIndex);
    } else {
      await reorderQueue(index, targetIndex - 1);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (_playlist.isEmpty) return;
    
    if (oldIndex < 0 || oldIndex >= _playlist.length) return;
    if (newIndex < 0) newIndex = 0;
    if (newIndex > _playlist.length) newIndex = _playlist.length;
    
    final item = _playlist.removeAt(oldIndex);
    _playlist.insert(newIndex, item);
    
    final source = _audioPlayer.audioSource as ConcatenatingAudioSource?;
    if (source != null) {
      await source.move(oldIndex, newIndex);
    }
    
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    
    _savePlayerState();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
