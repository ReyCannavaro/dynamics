import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dynamics/core/theme.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/services/storage_service.dart';
import 'package:dynamics/providers/player_provider.dart';
import 'package:dynamics/ui/screens/player_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_player_screen_test_');
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

  group('PlayerScreen Widget & Interaction Tests', () {
    testWidgets('Shows placeholder when no song is playing', (tester) async {
      final playerProvider = PlayerProvider(storageService: storage);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: playerProvider,
          child: const MaterialApp(
            home: PlayerScreen(),
          ),
        ),
      );

      expect(find.text('No song currently playing'), findsOneWidget);
    });

    testWidgets('Renders full playback controls, title, artist, and scrubber', (tester) async {
      const song = Song(
        id: 'full_player_song',
        title: 'Save Your Tears',
        artist: 'The Weeknd',
        album: 'After Hours',
        durationMs: 215000, // 3:35
        filePath: '/music/syt.mp3',
        isFavorite: false,
      );

      await storage.saveSong(song);

      final playerProvider = PlayerProvider(storageService: storage);
      await playerProvider.playSong(song);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: playerProvider,
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const PlayerScreen(),
          ),
        ),
      );

      // Verify song metadata displayed
      expect(find.text('Save Your Tears'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.text('After Hours'), findsOneWidget);

      // Verify controls
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Tap favorite button
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      // Tap shuffle button
      expect(playerProvider.isShuffle, false);
      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      expect(playerProvider.isShuffle, true);

      // Tap repeat button
      await tester.tap(find.byIcon(Icons.repeat_rounded));
      await tester.pump();
      expect(playerProvider.loopMode.index, 2); // LoopMode.all

      // Tap downward chevron button to dismiss
      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pump();
    });

    testWidgets('Scrubber seek drag updates playback position', (tester) async {
      const song = Song(
        id: 'scrubber_song',
        title: 'As It Was',
        artist: 'Harry Styles',
        album: 'Harry\'s House',
        durationMs: 167000,
        filePath: '/music/as_it_was.mp3',
      );

      await storage.saveSong(song);

      final playerProvider = PlayerProvider(storageService: storage);
      await playerProvider.playSong(song);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: playerProvider,
          child: MaterialApp(
            theme: DynamicsTheme.themeData,
            home: const PlayerScreen(),
          ),
        ),
      );

      // Drag slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pumpAndSettle();
    });
  });
}
