import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dynamics/core/theme.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/services/storage_service.dart';
import 'package:dynamics/services/metadata_service.dart';
import 'package:dynamics/providers/library_provider.dart';
import 'package:dynamics/providers/player_provider.dart';
import 'package:dynamics/ui/widgets/pill_button.dart';
import 'package:dynamics/ui/widgets/song_tile.dart';
import 'package:dynamics/ui/widgets/mini_player.dart';
import 'package:dynamics/ui/screens/home_screen.dart';
import 'package:dynamics/ui/screens/main_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_ui_test_');
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

  group('UI Widgets Tests', () {
    testWidgets('PillButton renders uppercase label and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillButton(
              label: 'Import Songs',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('IMPORT SONGS'), findsOneWidget);
      await tester.tap(find.byType(PillButton));
      expect(tapped, true);
    });

    testWidgets('SongTile renders title, artist, and responds to taps', (tester) async {
      bool tileTapped = false;
      bool favTapped = false;

      const song = Song(
        id: 'tile_song_1',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        durationMs: 200000, // 3:20
        filePath: '/music/bl.mp3',
        isFavorite: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SongTile(
              song: song,
              isCurrent: false,
              isPlaying: false,
              onTap: () => tileTapped = true,
              onToggleFavorite: () => favTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Blinding Lights'), findsOneWidget);
      expect(find.text('The Weeknd • 3:20'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.text('Blinding Lights'));
      expect(tileTapped, true);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      expect(favTapped, true);
    });

    testWidgets('MiniPlayer renders song details, play/pause and progress', (tester) async {
      bool playPauseTapped = false;
      bool miniTapped = false;

      const song = Song(
        id: 'mini_song',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        durationMs: 230000,
        filePath: '/music/starboy.mp3',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniPlayer(
              song: song,
              isPlaying: true,
              progress: 0.5,
              onTap: () => miniTapped = true,
              onPlayPause: () => playPauseTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Starboy'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(playPauseTapped, true);

      await tester.tap(find.text('Starboy'));
      expect(miniTapped, true);
    });
  });

  group('HomeScreen & MainScaffold Integration Tests', () {
    testWidgets('HomeScreen shows empty state when library has no tracks', (tester) async {
      final libraryProvider = LibraryProvider(
        storageService: storage,
        metadataService: MetadataService.instance,
      );
      final playerProvider = PlayerProvider(storageService: storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: libraryProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const HomeScreen(),
          ),
        ),
      );

      expect(find.text('Your Library is Empty'), findsOneWidget);
      expect(find.text('Dynamics'), findsOneWidget);
      expect(find.text('IMPORT FILES'), findsOneWidget);
      expect(find.text('IMPORT FOLDER'), findsOneWidget);
    });

    testWidgets('MainScaffold switches navigation tabs', (tester) async {
      final libraryProvider = LibraryProvider(
        storageService: storage,
        metadataService: MetadataService.instance,
      );
      final playerProvider = PlayerProvider(storageService: storage);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: libraryProvider),
            ChangeNotifierProvider.value(value: playerProvider),
          ],
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const MainScaffold(),
          ),
        ),
      );

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap Search tab
      await tester.tap(find.text('Search'));
      await tester.pump();
      expect(find.text('Search Your Library'), findsOneWidget);

      // Tap Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(find.text('Rey Cannavaro'), findsOneWidget);
      expect(find.text('LISTENING TIME'), findsOneWidget);
    });
  });
}
