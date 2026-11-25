import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

/// State management provider for offline user profile, listening statistics, and Wrapped insights
class ProfileProvider extends ChangeNotifier {
  final StorageService _storageService;

  UserProfile _profile = const UserProfile();
  List<Song> _topTracks = [];
  int _totalSongs = 0;
  int _totalFavorites = 0;

  ProfileProvider({
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService.instance {
    loadProfile();
  }

  UserProfile get profile => _profile;
  String get displayName => _profile.displayName;
  String get bio => _profile.bio;
  String? get avatarPath => _profile.avatarPath;
  String get formattedListeningTime => _profile.formattedListeningTime;

  List<Song> get topTracks => List.unmodifiable(_topTracks);
  int get totalSongs => _totalSongs;
  int get totalFavorites => _totalFavorites;

  /// Loads the stored user profile and aggregates local listening stats from Hive
  Future<void> loadProfile() async {
    if (!_storageService.isInitialized) return;

    _profile = _storageService.getUserProfile();
    _refreshStats();
    notifyListeners();
  }

  /// Refreshes local statistics (top played tracks, total songs, favorites)
  void _refreshStats() {
    if (!_storageService.isInitialized) return;

    _totalSongs = _storageService.totalSongsCount;
    _topTracks = _storageService.getTopPlayedSongs(limit: 5);
    _totalFavorites = _storageService.getFavoriteSongs().length;
  }

  /// Updates user profile details and persists them into Hive
  Future<void> updateProfile({
    required String displayName,
    required String bio,
    String? avatarPath,
  }) async {
    final updated = _profile.copyWith(
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : _profile.displayName,
      bio: bio.trim().isNotEmpty ? bio.trim() : _profile.bio,
      avatarPath: avatarPath ?? _profile.avatarPath,
    );

    _profile = updated;
    if (_storageService.isInitialized) {
      await _storageService.saveUserProfile(updated);
    }
    notifyListeners();
  }

  /// Manually trigger a stats refresh (e.g. after songs played or imported)
  void refresh() {
    loadProfile();
  }
}
