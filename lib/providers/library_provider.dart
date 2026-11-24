import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/song.dart';
import '../services/metadata_service.dart';
import '../services/storage_service.dart';

enum SortOption {
  dateAdded,
  title,
  artist,
  mostPlayed,
  favorites,
}

/// State management provider for song library, file importing, searching, and sorting
class LibraryProvider extends ChangeNotifier {
  final StorageService _storageService;
  final MetadataService _metadataService;

  List<Song> _songs = [];
  bool _isLoading = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateAdded;

  LibraryProvider({
    StorageService? storageService,
    MetadataService? metadataService,
  })  : _storageService = storageService ?? StorageService.instance,
        _metadataService = metadataService ?? MetadataService.instance {
    loadSongs();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  int get totalSongsCount => _songs.length;

  /// Returns sorted and search-filtered songs for the UI
  List<Song> get songs {
    List<Song> result = List.from(_songs);

    // Apply search filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((s) {
        return s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q);
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.title:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.artist:
        result.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case SortOption.mostPlayed:
        result.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case SortOption.favorites:
        result = result.where((s) => s.isFavorite).toList()
          ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.dateAdded:
        // Default order
        break;
    }

    return result;
  }

  /// Load all stored songs from Hive
  Future<void> loadSongs() async {
    if (!_storageService.isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      _songs = _storageService.getAllSongs();
    } catch (e) {
      debugPrint('Error loading songs from storage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Import one or multiple audio files via file picker
  Future<int> importFiles() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: DynamicsConstants.supportedAudioExtensions,
      );

      if (pickedFiles.isEmpty) return 0;

      final paths = pickedFiles.map((f) => f.path).whereType<String>().toList();
      return await _processAndSavePaths(paths);
    } catch (e) {
      debugPrint('Error picking files: $e');
      return 0;
    }
  }

  /// Pick and scan an entire folder recursively for audio files
  Future<int> importFolder() async {
    try {
      final uri = await FilePicker.pickDirectory();
      if (uri == null) return 0;

      final directoryPath = uri.hasScheme && uri.scheme == 'file'
          ? uri.toFilePath()
          : uri.path;

      final dir = Directory(directoryPath);
      if (!dir.existsSync()) return 0;

      final paths = <String>[];
      final allowed = DynamicsConstants.supportedAudioExtensions.map((e) => '.$e').toSet();

      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (allowed.any((a) => ext.endsWith(a))) {
            paths.add(entity.path);
          }
        }
      }

      return await _processAndSavePaths(paths);
    } catch (e) {
      debugPrint('Error importing folder: $e');
      return 0;
    }
  }

  /// Helper to extract metadata and persist newly found audio paths
  Future<int> _processAndSavePaths(List<String> paths) async {
    if (paths.isEmpty) return 0;

    _isLoading = true;
    notifyListeners();

    final existingIds = _songs.map((s) => s.id).toSet();
    final newSongs = <Song>[];

    for (final path in paths) {
      try {
        final song = await _metadataService.extractMetadata(path);
        if (!existingIds.contains(song.id)) {
          newSongs.add(song);
          existingIds.add(song.id);
        }
      } catch (e) {
        debugPrint('Could not extract metadata for $path: $e');
      }
    }

    if (newSongs.isNotEmpty) {
      await _storageService.saveSongs(newSongs);
      _songs.addAll(newSongs);
    }

    _isLoading = false;
    notifyListeners();
    return newSongs.length;
  }

  /// Delete a song from storage and library
  Future<void> deleteSong(String songId) async {
    await _storageService.deleteSong(songId);
    _songs.removeWhere((s) => s.id == songId);
    notifyListeners();
  }

  /// Toggle favorite on a song
  Future<void> toggleFavorite(String songId) async {
    final newStatus = await _storageService.toggleFavorite(songId);
    final index = _songs.indexWhere((s) => s.id == songId);
    if (index >= 0) {
      _songs[index] = _songs[index].copyWith(isFavorite: newStatus);
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }
}
