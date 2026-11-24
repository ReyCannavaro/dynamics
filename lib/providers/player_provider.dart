import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import '../services/storage_service.dart';

/// State management provider for audio playback, queue, and listening milestones
class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final StorageService _storageService;

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _indexSub;

  Song? _currentSong;
  Song? get currentSong => _currentSong;

  List<Song> _queue = [];
  List<Song> get queue => List.unmodifiable(_queue);

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  bool _isShuffle = false;
  bool get isShuffle => _isShuffle;

  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  // Milestone tracking for offline statistics
  bool _milestoneCounted = false;
  int _lastAccumulatedSecond = 0;

  PlayerProvider({
    AudioPlayerService? audioService,
    StorageService? storageService,
  })  : _audioService = audioService ?? AudioPlayerService.instance,
        _storageService = storageService ?? StorageService.instance {
    _init();
  }

  void _init() {
    // Restore persisted settings if storage is ready
    if (_storageService.isInitialized) {
      _isShuffle = _storageService.getShuffleMode();
      final loopIdx = _storageService.getLoopMode();
      _loopMode = LoopMode.values[loopIdx.clamp(0, LoopMode.values.length - 1)];
      _audioService.setShuffleMode(_isShuffle);
      _audioService.setLoopMode(_loopMode);
    }

    _listenToStreams();
  }

  void _listenToStreams() {
    _playerStateSub = _audioService.playerStateStream.listen((state) {
      final isNowPlaying = state.playing && state.processingState != ProcessingState.completed;
      if (_isPlaying != isNowPlaying) {
        _isPlaying = isNowPlaying;
        notifyListeners();
      }

      // Handle song completion tracking
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });

    _positionSub = _audioService.positionStream.listen((pos) {
      _position = pos;
      _handleListeningMilestone(pos);
      notifyListeners();
    });

    _durationSub = _audioService.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });

    _indexSub = _audioService.currentIndexStream.listen((index) {
      _onTrackChanged(index);
    });
  }

  void _onTrackChanged(int? index) {
    if (index != null && index >= 0 && index < _audioService.currentQueue.length) {
      _currentSong = _audioService.currentQueue[index];
    } else {
      _currentSong = null;
    }
    _milestoneCounted = false;
    _lastAccumulatedSecond = 0;
    _position = Duration.zero;
    notifyListeners();
  }

  void _handleListeningMilestone(Duration currentPos) {
    if (_currentSong == null) return;

    final currentSec = currentPos.inSeconds;

    // Accumulate total listening seconds to profile every 5 seconds of active playback
    if (currentSec > _lastAccumulatedSecond && (currentSec - _lastAccumulatedSecond >= 5)) {
      final diff = currentSec - _lastAccumulatedSecond;
      _lastAccumulatedSecond = currentSec;
      if (_storageService.isInitialized) {
        _storageService.addListeningSeconds(diff);
      }
    }

    // 30-Second listening milestone: increments song's playCount once per session
    if (!_milestoneCounted && currentSec >= DynamicsConstants.minListeningSecondsForPlayCount) {
      _milestoneCounted = true;
      if (_storageService.isInitialized) {
        _storageService.incrementPlayCount(_currentSong!.id);
      }
    }
  }

  void _onSongCompleted() {
    // If completed before 30s (short audio clip), still reward play count
    if (!_milestoneCounted && _currentSong != null) {
      _milestoneCounted = true;
      if (_storageService.isInitialized) {
        _storageService.incrementPlayCount(_currentSong!.id);
      }
    }
  }

  // ==========================================
  // PLAYBACK ACTIONS
  // ==========================================

  /// Play a specific song. If [contextQueue] is provided, replaces current queue with it.
  Future<void> playSong(Song song, {List<Song>? contextQueue}) async {
    final targetQueue = contextQueue ?? [song];
    final initialIndex = targetQueue.indexWhere((s) => s.id == song.id);

    _queue = List.from(targetQueue);
    _currentSong = song;
    _milestoneCounted = false;
    _lastAccumulatedSecond = 0;
    notifyListeners();

    await _audioService.setPlaylist(
      targetQueue,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
      autoPlay: true,
    );
  }

  /// Toggle play/pause state
  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      await _audioService.play();
    }
  }

  Future<void> play() => _audioService.play();

  Future<void> pause() => _audioService.pause();

  Future<void> next() => _audioService.skipToNext();

  Future<void> previous() => _audioService.skipToPrevious();

  Future<void> seek(Duration position) => _audioService.seek(position);

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await _audioService.setShuffleMode(_isShuffle);
    if (_storageService.isInitialized) {
      await _storageService.setShuffleMode(_isShuffle);
    }
    notifyListeners();
  }

  /// Cycle loop mode: Off -> All -> One -> Off
  Future<void> toggleRepeat() async {
    switch (_loopMode) {
      case LoopMode.off:
        _loopMode = LoopMode.all;
        break;
      case LoopMode.all:
        _loopMode = LoopMode.one;
        break;
      case LoopMode.one:
        _loopMode = LoopMode.off;
        break;
    }

    await _audioService.setLoopMode(_loopMode);
    if (_storageService.isInitialized) {
      await _storageService.setLoopMode(_loopMode.index);
    }
    notifyListeners();
  }

  /// Toggle favorite on the currently playing track
  Future<void> toggleFavorite() async {
    if (_currentSong == null) return;

    if (_storageService.isInitialized) {
      final updatedStatus = await _storageService.toggleFavorite(_currentSong!.id);
      _currentSong = _currentSong!.copyWith(isFavorite: updatedStatus);
      notifyListeners();
    }
  }

  // ==========================================
  // PROGRESS & FORMATTING GETTERS
  // ==========================================

  /// Playback progress normalized from 0.0 to 1.0
  double get progress {
    if (_duration.inMilliseconds == 0) return 0.0;
    final val = _position.inMilliseconds / _duration.inMilliseconds;
    return val.clamp(0.0, 1.0);
  }

  String get formattedPosition => _formatDuration(_position);

  String get formattedDuration => _formatDuration(_duration);

  String get remainingDuration {
    final remaining = _duration - _position;
    if (remaining.isNegative) return '-0:00';
    return '-${_formatDuration(remaining)}';
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final secondsPadded = seconds.toString().padLeft(2, '0');

    if (d.inHours > 0) {
      final hours = d.inHours;
      final minutesPadded = (minutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutesPadded:$secondsPadded';
    }
    return '$minutes:$secondsPadded';
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _indexSub?.cancel();
    super.dispose();
  }
}
