import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../models/user_profile.dart';

/// Offline-first Storage Service powering Dynamics via Hive
class StorageService {
  static StorageService? _instance;
  static StorageService get instance {
    _instance ??= StorageService._internal();
    return _instance!;
  }

  StorageService._internal();

  // Hive Boxes
  late Box<Map> _songsBox;
  late Box<String> _lyricsBox;
  late Box<dynamic> _profileBox;
  late Box<dynamic> _settingsBox;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes Hive and opens all required storage boxes.
  /// If [customPath] is provided (e.g. during unit tests), Hive initializes to that path.
  Future<void> init({String? customPath}) async {
    if (_isInitialized) return;

    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    _songsBox = await Hive.openBox<Map>(DynamicsConstants.boxSongs);
    _lyricsBox = await Hive.openBox<String>(DynamicsConstants.boxLyrics);
    _profileBox = await Hive.openBox<dynamic>(DynamicsConstants.boxProfile);
    _settingsBox = await Hive.openBox<dynamic>(DynamicsConstants.boxSettings);

    // Initialize default profile if absent
    if (!_profileBox.containsKey(DynamicsConstants.keyProfile)) {
      final defaultProfile = const UserProfile();
      await _profileBox.put(DynamicsConstants.keyProfile, defaultProfile.toMap());
    }

    _isInitialized = true;
  }

  // ==========================================
  // SONG OPERATIONS
  // ==========================================

  /// Save or update a single song
  Future<void> saveSong(Song song) async {
    _checkInit();
    await _songsBox.put(song.id, song.toMap());
  }

  /// Bulk save multiple songs (e.g. after importing a folder)
  Future<void> saveSongs(List<Song> songs) async {
    _checkInit();
    final entries = <String, Map>{};
    for (final song in songs) {
      entries[song.id] = song.toMap();
    }
    await _songsBox.putAll(entries);
  }

  /// Retrieve all songs in library
  List<Song> getAllSongs() {
    _checkInit();
    final List<Song> songs = [];
    for (final value in _songsBox.values) {
      try {
        songs.add(Song.fromMap(value));
      } catch (e) {
        debugPrint('Error parsing song from Hive: $e');
      }
    }
    return songs;
  }

  /// Retrieve a specific song by its ID
  Song? getSong(String id) {
    _checkInit();
    final map = _songsBox.get(id);
    if (map == null) return null;
    return Song.fromMap(map);
  }

  /// Delete a song and its cached lyrics
  Future<void> deleteSong(String id) async {
    _checkInit();
    await _songsBox.delete(id);
    await _lyricsBox.delete(id);
  }

  /// Toggle song favorite status. Returns the updated isFavorite boolean.
  Future<bool> toggleFavorite(String id) async {
    _checkInit();
    final song = getSong(id);
    if (song == null) return false;

    final updated = song.copyWith(isFavorite: !song.isFavorite);
    await saveSong(updated);
    return updated.isFavorite;
  }

  /// Increment a song's play count and record the last played timestamp
  Future<void> incrementPlayCount(String id) async {
    _checkInit();
    final song = getSong(id);
    if (song == null) return;

    final updated = song.copyWith(
      playCount: song.playCount + 1,
      lastPlayedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
    await saveSong(updated);
  }

  /// Get the top played songs sorted descending by play count
  List<Song> getTopPlayedSongs({int limit = 5}) {
    _checkInit();
    final songs = getAllSongs()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    return songs.take(limit).toList();
  }

  /// Get only liked/favorited songs
  List<Song> getFavoriteSongs() {
    _checkInit();
    return getAllSongs().where((s) => s.isFavorite).toList();
  }

  /// Total count of songs in library
  int get totalSongsCount {
    _checkInit();
    return _songsBox.length;
  }

  // ==========================================
  // LYRICS OPERATIONS (LRCLIB Cache)
  // ==========================================

  /// Permanently cache raw LRC lyrics string for a song
  Future<void> saveLyrics(String songId, String rawLrc) async {
    _checkInit();
    await _lyricsBox.put(songId, rawLrc);
  }

  /// Get cached LRC lyrics string if available
  String? getCachedLyrics(String songId) {
    _checkInit();
    return _lyricsBox.get(songId);
  }

  /// Check whether lyrics are already cached locally for a song
  bool hasLyrics(String songId) {
    _checkInit();
    return _lyricsBox.containsKey(songId);
  }

  // ==========================================
  // USER PROFILE & STATS OPERATIONS
  // ==========================================

  /// Get the current offline user profile
  UserProfile getUserProfile() {
    _checkInit();
    final raw = _profileBox.get(DynamicsConstants.keyProfile);
    if (raw is Map) {
      return UserProfile.fromMap(raw);
    }
    return const UserProfile();
  }

  /// Save updated user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    _checkInit();
    await _profileBox.put(DynamicsConstants.keyProfile, profile.toMap());
  }

  /// Accumulate listening time in seconds to the offline profile
  Future<void> addListeningSeconds(int seconds) async {
    _checkInit();
    final current = getUserProfile();
    final updated = current.copyWith(
      totalListeningSeconds: current.totalListeningSeconds + seconds,
    );
    await saveUserProfile(updated);
  }

  // ==========================================
  // SETTINGS & PLAYBACK STATE PERSISTENCE
  // ==========================================

  bool getShuffleMode({bool defaultValue = false}) {
    _checkInit();
    return (_settingsBox.get(DynamicsConstants.keyShuffleMode) as bool?) ?? defaultValue;
  }

  Future<void> setShuffleMode(bool enabled) async {
    _checkInit();
    await _settingsBox.put(DynamicsConstants.keyShuffleMode, enabled);
  }

  int getLoopMode({int defaultValue = 0}) {
    _checkInit();
    return (_settingsBox.get(DynamicsConstants.keyRepeatMode) as int?) ?? defaultValue;
  }

  Future<void> setLoopMode(int mode) async {
    _checkInit();
    await _settingsBox.put(DynamicsConstants.keyRepeatMode, mode);
  }

  // ==========================================
  // UTILITIES & CLEANUP
  // ==========================================

  /// Clear all data in all boxes (useful for reset or clean test teardown)
  Future<void> clearAll() async {
    _checkInit();
    await _songsBox.clear();
    await _lyricsBox.clear();
    await _profileBox.clear();
    await _settingsBox.clear();
  }

  /// Close all Hive boxes
  Future<void> close() async {
    if (!_isInitialized) return;
    await _songsBox.close();
    await _lyricsBox.close();
    await _profileBox.close();
    await _settingsBox.close();
    _isInitialized = false;
  }

  void _checkInit() {
    if (!_isInitialized) {
      throw StateError(
        'StorageService has not been initialized. Call await StorageService.instance.init() first.',
      );
    }
  }
}
