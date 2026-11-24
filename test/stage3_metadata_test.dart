import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/services/metadata_service.dart';
import 'package:dynamics/services/storage_service.dart';
import 'package:dynamics/providers/library_provider.dart';
import 'package:dynamics/ui/widgets/album_art_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late MetadataService metadataService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_metadata_test_');
    storage = StorageService.instance;
    await storage.init(customPath: tempDir.path);
    metadataService = MetadataService.instance;
  });

  tearDown(() async {
    await storage.clearAll();
    await storage.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MetadataService Filename Cleaning Tests', () {
    test('Cleans track numbers, underscores, and extensions', () {
      expect(
        metadataService.cleanFilename('01 - Bohemian_Rhapsody.mp3'),
        'Bohemian Rhapsody',
      );
      expect(
        metadataService.cleanFilename('02. Hotel California.m4a'),
        'Hotel California',
      );
      expect(
        metadataService.cleanFilename('Queen_-_Don\'t_Stop_Me_Now.flac'),
        'Don\'t Stop Me Now',
      );
      expect(
        metadataService.cleanFilename('track_05.wav'),
        'track 05',
      );
    });

    test('Handles messy and edge case filenames gracefully', () {
      expect(metadataService.cleanFilename('.mp3'), 'Unknown Track');
      expect(metadataService.cleanFilename('01 - .mp3'), 'Unknown Track');
      expect(
        metadataService.cleanFilename('The Weeknd - Blinding Lights (Official).mp3'),
        'Blinding Lights (Official)',
      );
    });
  });

  group('LibraryProvider Search & Sort Tests', () {
    test('Search filtering by title, artist, and album', () async {
      final songs = [
        const Song(
          id: '1',
          title: 'Starboy',
          artist: 'The Weeknd',
          album: 'Starboy',
          durationMs: 230000,
          filePath: '/music/1.mp3',
        ),
        const Song(
          id: '2',
          title: 'Midnight City',
          artist: 'M83',
          album: 'Hurry Up, We\'re Dreaming',
          durationMs: 243000,
          filePath: '/music/2.mp3',
        ),
        const Song(
          id: '3',
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          album: 'After Hours',
          durationMs: 200000,
          filePath: '/music/3.mp3',
        ),
      ];

      await storage.saveSongs(songs);

      final provider = LibraryProvider(
        storageService: storage,
        metadataService: metadataService,
      );

      await provider.loadSongs();
      expect(provider.totalSongsCount, 3);

      // Search by artist
      provider.setSearchQuery('weeknd');
      expect(provider.songs.length, 2);

      // Search by title
      provider.setSearchQuery('Midnight');
      expect(provider.songs.length, 1);
      expect(provider.songs.first.title, 'Midnight City');

      // Search by album
      provider.setSearchQuery('After Hours');
      expect(provider.songs.length, 1);
      expect(provider.songs.first.title, 'Blinding Lights');

      // Clear search
      provider.setSearchQuery('');
      expect(provider.songs.length, 3);
    });

    test('Sorting by title, artist, mostPlayed, and favorites', () async {
      final songs = [
        const Song(
          id: '1',
          title: 'Zebra',
          artist: 'Beach House',
          album: 'Teen Dream',
          durationMs: 200000,
          filePath: '/music/1.mp3',
          playCount: 5,
          isFavorite: false,
        ),
        const Song(
          id: '2',
          title: 'Apple',
          artist: 'Charli XCX',
          album: 'BRAT',
          durationMs: 150000,
          filePath: '/music/2.mp3',
          playCount: 20,
          isFavorite: true,
        ),
      ];

      await storage.saveSongs(songs);

      final provider = LibraryProvider(
        storageService: storage,
        metadataService: metadataService,
      );
      await provider.loadSongs();

      // Sort by Title
      provider.setSortOption(SortOption.title);
      expect(provider.songs.first.title, 'Apple');

      // Sort by Artist
      provider.setSortOption(SortOption.artist);
      expect(provider.songs.first.artist, 'Beach House');

      // Sort by Most Played
      provider.setSortOption(SortOption.mostPlayed);
      expect(provider.songs.first.playCount, 20);

      // Filter Favorites
      provider.setSortOption(SortOption.favorites);
      expect(provider.songs.length, 1);
      expect(provider.songs.first.title, 'Apple');
    });

    test('Toggle favorite updates library state', () async {
      const song = Song(
        id: 'toggle_fav',
        title: 'As It Was',
        artist: 'Harry Styles',
        album: 'Harry\'s House',
        durationMs: 167000,
        filePath: '/music/as_it_was.mp3',
        isFavorite: false,
      );

      await storage.saveSong(song);

      final provider = LibraryProvider(
        storageService: storage,
        metadataService: metadataService,
      );
      await provider.loadSongs();

      expect(provider.songs.first.isFavorite, false);

      await provider.toggleFavorite('toggle_fav');
      expect(provider.songs.first.isFavorite, true);
    });
  });

  group('AlbumArtImage Widget Tests', () {
    testWidgets('Renders placeholder icon when bytes is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumArtImage(bytes: null, size: 60),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
    });

    testWidgets('Renders image memory when bytes is provided', (tester) async {
      // 1x1 transparent PNG byte array
      final dummyBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumArtImage(bytes: dummyBytes, size: 80),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
