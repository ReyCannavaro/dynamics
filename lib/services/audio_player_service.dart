import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

import '../models/song.dart';

/// Service responsible for managing audio playback and background media controls
class AudioPlayerService {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance {
    _instance ??= AudioPlayerService._internal();
    return _instance!;
  }

  AudioPlayerService._internal();

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  List<Song> _currentQueue = [];
  List<Song> get currentQueue => List.unmodifiable(_currentQueue);

  bool _isBackgroundInitialized = false;
  Directory? _artCacheDir;

  /// Initializes the audio service and background notifications
  Future<void> init() async {
    if (!_isBackgroundInitialized) {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await JustAudioBackground.init(
            androidNotificationChannelId: 'com.dynamics.audio.channel',
            androidNotificationChannelName: 'Dynamics Playback',
            androidNotificationOngoing: true,
            androidStopForegroundOnPause: true,
            androidNotificationIcon: 'mipmap/ic_launcher',
          );
        } catch (e) {
          debugPrint('JustAudioBackground init warning: $e');
        }
      }
      _isBackgroundInitialized = true;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      _artCacheDir = Directory('${tempDir.path}/dynamics_art_cache');
      if (!_artCacheDir!.existsSync()) {
        _artCacheDir!.createSync(recursive: true);
      }
    } catch (e) {
      debugPrint('Could not initialize artwork cache directory: $e');
    }
  }

  // ==========================================
  // PLAYLIST & QUEUE MANAGEMENT
  // ==========================================

  /// Load a playlist of songs and optionally start playback at [initialIndex]
  Future<void> setPlaylist(
    List<Song> songs, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;

    _currentQueue = List.from(songs);
    final audioSources = <AudioSource>[];

    for (final song in songs) {
      final source = await _createAudioSource(song);
      audioSources.add(source);
    }

    final validIndex = initialIndex.clamp(0, songs.length - 1);

    await _player.setAudioSources(
      audioSources,
      initialIndex: validIndex,
      initialPosition: Duration.zero,
    );

    if (autoPlay) {
      await _player.play();
    }
  }

  /// Append a single song to the active queue
  Future<void> addSongToQueue(Song song) async {
    _currentQueue.add(song);
    final source = await _createAudioSource(song);
    await _player.addAudioSource(source);
  }

  /// Remove a song at [index] from the active queue
  Future<void> removeSongFromQueue(int index) async {
    if (index >= 0 && index < _currentQueue.length) {
      _currentQueue.removeAt(index);
      await _player.removeAudioSourceAt(index);
    }
  }

  /// Converts a [Song] to a JustAudio [AudioSource] tagged with [MediaItem]
  Future<AudioSource> _createAudioSource(Song song) async {
    Uri? artUri;

    // Cache cover art bytes to local temporary file for notification artwork
    if (song.coverArtBytes != null && song.coverArtBytes!.isNotEmpty && _artCacheDir != null) {
      try {
        final artFile = File('${_artCacheDir!.path}/${song.id}.jpg');
        if (!artFile.existsSync()) {
          await artFile.writeAsBytes(song.coverArtBytes!, flush: true);
        }
        artUri = Uri.file(artFile.path);
      } catch (e) {
        debugPrint('Failed to write art file for notification: $e');
      }
    }

    final mediaItem = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: Duration(milliseconds: song.durationMs),
      artUri: artUri,
    );

    return AudioSource.uri(
      Uri.file(song.filePath),
      tag: mediaItem,
    );
  }

  // ==========================================
  // PLAYBACK CONTROLS
  // ==========================================

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipToNext() => _player.seekToNext();

  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> setShuffleMode(bool enabled) => _player.setShuffleModeEnabled(enabled);

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  // ==========================================
  // STREAMS & GETTERS
  // ==========================================

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<int?> get currentIndexStream => _player.currentIndexStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  int? get currentIndex => _player.currentIndex;
  LoopMode get loopMode => _player.loopMode;
  bool get isShuffleEnabled => _player.shuffleModeEnabled;

  Song? get currentSong {
    final idx = _player.currentIndex;
    if (idx != null && idx >= 0 && idx < _currentQueue.length) {
      return _currentQueue[idx];
    }
    return null;
  }

  /// Disposes the underlying player resources
  Future<void> dispose() async {
    await _player.dispose();
  }
}
