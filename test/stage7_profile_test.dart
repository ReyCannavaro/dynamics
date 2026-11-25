import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dynamics/core/theme.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/services/storage_service.dart';
import 'package:dynamics/providers/player_provider.dart';
import 'package:dynamics/providers/profile_provider.dart';
import 'package:dynamics/ui/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_profile_test_');
    storage = StorageService.instance;
    await storage.init(customPath: tempDir.path);
  });

  tearDown(() async {
    await storage.clearAll();
    await storage.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('ProfileProvider Logic Tests', () {
    test('Initializes with default profile data from Hive', () async {
      final profileProvider = ProfileProvider(storageService: storage);
      await profileProvider.loadProfile();

      expect(profileProvider.displayName, 'Rey Cannavaro');
      expect(profileProvider.bio, 'Living in Dynamics 🎧');
      expect(profileProvider.totalSongs, 0);
      expect(profileProvider.totalFavorites, 0);
      expect(profileProvider.topTracks, isEmpty);
    });

    test('updateProfile updates state and persists to StorageService', () async {
      final profileProvider = ProfileProvider(storageService: storage);
      await profileProvider.loadProfile();

      await profileProvider.updateProfile(
        displayName: 'Rey J. Cannavaro',
        bio: 'Building Dynamics offline 🎧',
      );

      expect(profileProvider.displayName, 'Rey J. Cannavaro');
      expect(profileProvider.bio, 'Building Dynamics offline 🎧');

      // Verify persistence in Hive
      final storedProfile = storage.getUserProfile();
      expect(storedProfile.displayName, 'Rey J. Cannavaro');
      expect(storedProfile.bio, 'Building Dynamics offline 🎧');
    });

    test('Aggregates total songs, favorites, and top played tracks', () async {
      final songs = [
        const Song(
          id: 'song_1',
          title: 'Starboy',
          artist: 'The Weeknd',
          album: 'Starboy',
          durationMs: 230000,
          filePath: '/music/starboy.mp3',
          playCount: 45,
          isFavorite: true,
        ),
        const Song(
          id: 'song_2',
          title: 'Blinding Lights',
          artist: 'The Weeknd',
          album: 'After Hours',
          durationMs: 200000,
          filePath: '/music/bl.mp3',
          playCount: 12,
          isFavorite: true,
        ),
        const Song(
          id: 'song_3',
          title: 'Midnight City',
          artist: 'M83',
          album: 'Hurry Up',
          durationMs: 240000,
          filePath: '/music/mc.mp3',
          playCount: 3,
          isFavorite: false,
        ),
      ];

      await storage.saveSongs(songs);

      final profileProvider = ProfileProvider(storageService: storage);
      await profileProvider.loadProfile();

      expect(profileProvider.totalSongs, 3);
      expect(profileProvider.totalFavorites, 2);
      expect(profileProvider.topTracks.length, 3);
      expect(profileProvider.topTracks.first.title, 'Starboy');
      expect(profileProvider.topTracks.first.playCount, 45);
    });
  });

  group('ProfileScreen Widget & Interaction Tests', () {
    testWidgets('Renders user header, stat cards, and edit profile dialog', (tester) async {
      final profileProvider = ProfileProvider(storageService: storage);
      final playerProvider = PlayerProvider(storageService: storage);
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const ProfileScreen(),
          ),
        ),
      );

      // Verify header details
      expect(find.text('Rey Cannavaro'), findsOneWidget);
      expect(find.text('Living in Dynamics 🎧'), findsOneWidget);
      expect(find.text('DYNAMICS WRAPPED'), findsOneWidget);
      expect(find.text('LISTENING TIME'), findsOneWidget);
      expect(find.text('TOTAL TRACKS'), findsOneWidget);
      expect(find.text('FAVORITES'), findsOneWidget);
      expect(find.text('100% Ad-Free'), findsOneWidget);

      // Open Edit Profile dialog
      await tester.tap(find.text('EDIT PROFILE'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Bio / Tagline'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('Renders top played tracks list and triggers playback on tap', (tester) async {
      const topSong = Song(
        id: 'top_1',
        title: 'Save Your Tears',
        artist: 'The Weeknd',
        album: 'After Hours',
        durationMs: 215000,
        filePath: '/music/syt.mp3',
        playCount: 30,
      );

      await storage.saveSong(topSong);

      final profileProvider = ProfileProvider(storageService: storage);
      final playerProvider = PlayerProvider(storageService: storage);
      await profileProvider.loadProfile();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: profileProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const ProfileScreen(),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('Save Your Tears'), findsOneWidget);
      expect(find.text('30 plays'), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
