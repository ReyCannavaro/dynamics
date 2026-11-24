import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dynamics/core/constants.dart';
import 'package:dynamics/models/song.dart';
import 'package:dynamics/models/lyric_line.dart';
import 'package:dynamics/models/user_profile.dart';
import 'package:dynamics/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dynamics_test_');
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

  group('Domain Models Unit Tests', () {
    test('Song model serialization and formattedDuration', () {
      final dummyArt = Uint8List.fromList([1, 2, 3, 4, 5]);
      final song = Song(
        id: 'song_1',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        durationMs: 230000, // 3:50
        filePath: '/music/starboy.mp3',
        coverArtBytes: dummyArt,
        playCount: 10,
        isFavorite: true,
      );

      expect(song.formattedDuration, '3:50');

      final map = song.toMap();
      final fromMap = Song.fromMap(map);

      expect(fromMap.id, song.id);
      expect(fromMap.title, song.title);
      expect(fromMap.artist, song.artist);
      expect(fromMap.album, song.album);
      expect(fromMap.durationMs, song.durationMs);
      expect(fromMap.filePath, song.filePath);
      expect(fromMap.playCount, 10);
      expect(fromMap.isFavorite, true);
      expect(fromMap.coverArtBytes, isNotNull);
      expect(fromMap.coverArtBytes!.length, 5);
      expect(fromMap, equals(song));
    });

    test('Song formattedDuration with hours', () {
      const longSong = Song(
        id: 'podcast_1',
        title: 'Long Set',
        artist: 'DJ',
        album: 'Live',
        durationMs: 3665000, // 1:01:05
        filePath: '/music/long.mp3',
      );

      expect(longSong.formattedDuration, '1:01:05');
    });

    test('LyricLine model parsing, sorting and equality', () {
      final line1 = LyricLine(
        timestamp: const Duration(seconds: 10),
        text: 'I\'m trying to put you in the worst mood, ah',
      );
      final line2 = LyricLine(
        timestamp: const Duration(seconds: 5),
        text: 'P1 cleaner than your church shoes, ah',
      );

      final list = [line1, line2]..sort();

      expect(list.first.text, line2.text);
      expect(list.last.text, line1.text);

      final map = line1.toMap();
      final reconstituted = LyricLine.fromMap(map);
      expect(reconstituted, equals(line1));
    });

    test('UserProfile defaults and formattedListeningTime', () {
      const profile = UserProfile(
        displayName: 'Rey Cannavaro',
        bio: 'Living in Dynamics 🎧',
        totalListeningSeconds: 7320, // 2 hrs 2 mins
      );

      expect(profile.displayName, DynamicsConstants.defaultUserName);
      expect(profile.bio, DynamicsConstants.defaultUserBio);
      expect(profile.formattedListeningTime, '2 hrs 2 mins');

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);
      expect(fromMap, equals(profile));
    });
  });

  group('StorageService CRUD Tests', () {
    test('Default user profile exists upon initialization', () {
      final profile = storage.getUserProfile();
      expect(profile.displayName, DynamicsConstants.defaultUserName);
      expect(profile.bio, DynamicsConstants.defaultUserBio);
      expect(profile.totalListeningSeconds, 0);
    });

    test('Save, retrieve, and delete single song', () async {
      const song = Song(
        id: 'track_1',
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        durationMs: 243000,
        filePath: '/storage/midnight_city.mp3',
      );

      await storage.saveSong(song);

      expect(storage.totalSongsCount, 1);
      final retrieved = storage.getSong('track_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Midnight City');
      expect(retrieved.artist, 'M83');

      await storage.deleteSong('track_1');
      expect(storage.totalSongsCount, 0);
      expect(storage.getSong('track_1'), isNull);
    });

    test('Bulk save and list retrieval', () async {
      final songs = List.generate(
        5,
        (i) => Song(
          id: 'song_$i',
          title: 'Title $i',
          artist: 'Artist $i',
          album: 'Album $i',
          durationMs: 180000 + i * 1000,
          filePath: '/music/song_$i.mp3',
        ),
      );

      await storage.saveSongs(songs);
      expect(storage.totalSongsCount, 5);

      final all = storage.getAllSongs();
      expect(all.length, 5);
    });

    test('Toggle favorite status', () async {
      const song = Song(
        id: 'fav_test',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        durationMs: 200000,
        filePath: '/music/bl.mp3',
        isFavorite: false,
      );

      await storage.saveSong(song);

      final newStatus = await storage.toggleFavorite('fav_test');
      expect(newStatus, true);
      expect(storage.getSong('fav_test')!.isFavorite, true);

      final nextStatus = await storage.toggleFavorite('fav_test');
      expect(nextStatus, false);
      expect(storage.getSong('fav_test')!.isFavorite, false);
    });

    test('Increment play count and sort top played songs', () async {
      const songA = Song(
        id: 'song_a',
        title: 'Song A',
        artist: 'Artist A',
        album: 'Album A',
        durationMs: 180000,
        filePath: '/a.mp3',
        playCount: 2,
      );
      const songB = Song(
        id: 'song_b',
        title: 'Song B',
        artist: 'Artist B',
        album: 'Album B',
        durationMs: 180000,
        filePath: '/b.mp3',
        playCount: 15,
      );

      await storage.saveSongs([songA, songB]);

      await storage.incrementPlayCount('song_a');
      expect(storage.getSong('song_a')!.playCount, 3);
      expect(storage.getSong('song_a')!.lastPlayedEpochMs, greaterThan(0));

      final top = storage.getTopPlayedSongs(limit: 2);
      expect(top.first.id, 'song_b'); // 15 plays
      expect(top.last.id, 'song_a'); // 3 plays
    });

    test('Cache and retrieve synced LRC lyrics', () async {
      const sampleLrc = '''
[00:12.00] Line one lyric
[00:15.50] Line two lyric
''';

      expect(storage.hasLyrics('song_lyrics_1'), false);
      await storage.saveLyrics('song_lyrics_1', sampleLrc);

      expect(storage.hasLyrics('song_lyrics_1'), true);
      final cached = storage.getCachedLyrics('song_lyrics_1');
      expect(cached, sampleLrc);
    });

    test('Update profile and accumulate listening seconds', () async {
      await storage.addListeningSeconds(120);
      expect(storage.getUserProfile().totalListeningSeconds, 120);

      await storage.addListeningSeconds(60);
      expect(storage.getUserProfile().totalListeningSeconds, 180);

      final updatedProfile = storage.getUserProfile().copyWith(
            bio: 'Coding with Dynamics 🎧',
          );
      await storage.saveUserProfile(updatedProfile);

      expect(storage.getUserProfile().bio, 'Coding with Dynamics 🎧');
    });

    test('Settings persistence (shuffle & loop modes)', () async {
      expect(storage.getShuffleMode(), false);
      await storage.setShuffleMode(true);
      expect(storage.getShuffleMode(), true);

      expect(storage.getLoopMode(), 0);
      await storage.setLoopMode(2); // Repeat all
      expect(storage.getLoopMode(), 2);
    });
  });
}
