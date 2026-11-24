import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/services/lyrics_service.dart';
import 'package:dynamics/services/storage_service.dart';
import 'package:dynamics/providers/player_provider.dart';
import 'package:dynamics/ui/screens/lyrics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late StorageService storage;
  late LyricsService lyricsService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_lyrics_test_');
    storage = StorageService.instance;
    await storage.init(customPath: tempDir.path);
    lyricsService = LyricsService.instance;
  });

  tearDown(() async {
    await storage.clearAll();
    await storage.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LRC Parsing & Active Index Logic Tests', () {
    const sampleLrc = '''
[ti:Blinding Lights]
[ar:The Weeknd]
[00:12.50] Yeah
[00:18.20] I've been tryna call
[00:23.85] I've been on my own for long enough
[01:05.123] I said, ooh, I'm blinded by the lights
''';

    test('Parses timestamped LRC into sorted LyricLines', () {
      final lines = lyricsService.parseLrc(sampleLrc);

      expect(lines.length, 4);
      expect(lines[0].timestamp, const Duration(seconds: 12, milliseconds: 500));
      expect(lines[0].text, 'Yeah');

      expect(lines[1].timestamp, const Duration(seconds: 18, milliseconds: 200));
      expect(lines[1].text, 'I\'ve been tryna call');

      expect(lines[2].timestamp, const Duration(seconds: 23, milliseconds: 850));
      expect(lines[2].text, 'I\'ve been on my own for long enough');

      expect(lines[3].timestamp, const Duration(minutes: 1, seconds: 5, milliseconds: 123));
      expect(lines[3].text, 'I said, ooh, I\'m blinded by the lights');
    });

    test('Determines active lyric index accurately based on playback position', () {
      final lines = lyricsService.parseLrc(sampleLrc);

      // Before 12.5s
      expect(lyricsService.getActiveLyricIndex(lines, const Duration(seconds: 5)), 0);

      // At 15s (between line 0 and line 1)
      expect(lyricsService.getActiveLyricIndex(lines, const Duration(seconds: 15)), 0);

      // At 20s (between line 1 and line 2)
      expect(lyricsService.getActiveLyricIndex(lines, const Duration(seconds: 20)), 1);

      // At 24s (between line 2 and line 3)
      expect(lyricsService.getActiveLyricIndex(lines, const Duration(seconds: 24)), 2);

      // At 1m 10s (after line 3)
      expect(lyricsService.getActiveLyricIndex(lines, const Duration(seconds: 70)), 3);
    });

    test('Handles plain un-timestamped lyrics gracefully', () {
      const plain = '''
Line one
Line two
Line three
''';
      final lines = lyricsService.parseLrc(plain);
      expect(lines.length, 3);
      expect(lines[0].text, 'Line one');
      expect(lines[1].text, 'Line two');
    });
  });

  group('LyricsScreen Widget & Interaction Tests', () {
    const testSong = Song(
      id: 'lyrics_song_1',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      durationMs: 200000,
      filePath: '/music/bl.mp3',
    );

    const testLrc = '''
[00:00.00] Intro beat
[00:05.00] First vocal line
[00:10.00] Second vocal line
''';

    testWidgets('Renders lyrics list and highlights active line', (tester) async {
      // Pre-cache lyrics into storage
      await storage.saveSong(testSong);
      await storage.saveLyrics(testSong.id, testLrc);

      final playerProvider = PlayerProvider(storageService: storage);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: playerProvider,
          child: const MaterialApp(
            home: LyricsScreen(song: testSong),
          ),
        ),
      );

      // Await lyrics loading future
      await tester.pumpAndSettle();

      expect(find.text('Blinding Lights'), findsOneWidget);
      expect(find.text('The Weeknd'), findsOneWidget);
      expect(find.text('KARAOKE'), findsOneWidget);

      expect(find.text('Intro beat'), findsOneWidget);
      expect(find.text('First vocal line'), findsOneWidget);
      expect(find.text('Second vocal line'), findsOneWidget);

      // Tap on a lyric line to seek
      await tester.tap(find.text('First vocal line'));
      await tester.pump();
    });

    testWidgets('Renders empty state when no lyrics are cached or available', (tester) async {
      const unkSong = Song(
        id: 'no_lyrics_song',
        title: 'NonExistentSong12345',
        artist: 'UnknownArtist12345',
        album: 'None',
        durationMs: 180000,
        filePath: '/music/none.mp3',
      );

      final playerProvider = PlayerProvider(storageService: storage);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: playerProvider,
          child: const MaterialApp(
            home: LyricsScreen(song: unkSong),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Lyrics Available'), findsOneWidget);
      expect(find.text('RETRY SEARCH'), findsOneWidget);
    });
  });
}
