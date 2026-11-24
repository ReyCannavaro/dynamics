import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/lyric_line.dart';
import '../models/song.dart';
import 'storage_service.dart';

/// Service responsible for fetching, parsing, and caching synchronized lyrics via LRCLIB
class LyricsService {
  static LyricsService? _instance;
  static LyricsService get instance {
    _instance ??= LyricsService._internal();
    return _instance!;
  }

  LyricsService._internal();

  final StorageService _storage = StorageService.instance;

  /// Fetches synchronized lyrics for a [song].
  /// Checks local Hive cache first. If not cached, queries LRCLIB API and caches the result.
  Future<String?> getLyrics(Song song) async {
    // 1. Check local Hive cache
    if (_storage.isInitialized && _storage.hasLyrics(song.id)) {
      final cached = _storage.getCachedLyrics(song.id);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }

    // 2. Fetch from LRCLIB API
    try {
      final durationSec = (song.durationMs / 1000).round();
      final queryParams = {
        'track_name': song.title,
        'artist_name': song.artist != 'Unknown Artist' ? song.artist : '',
        if (song.album != 'Unknown Album' && song.album.isNotEmpty)
          'album_name': song.album,
        if (durationSec > 0)
          'duration': durationSec.toString(),
      };

      final uri = Uri.parse(DynamicsConstants.lrclibApiBase).replace(queryParameters: queryParams);
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final syncedLyrics = data['syncedLyrics'] as String?;
        final plainLyrics = data['plainLyrics'] as String?;

        final resultLyrics = (syncedLyrics != null && syncedLyrics.isNotEmpty)
            ? syncedLyrics
            : plainLyrics;

        if (resultLyrics != null && resultLyrics.isNotEmpty) {
          // Cache permanently to Hive
          if (_storage.isInitialized) {
            await _storage.saveLyrics(song.id, resultLyrics);
          }
          return resultLyrics;
        }
      }
    } catch (e) {
      debugPrint('LRCLIB API request failed (device offline or track not found): $e');
    }

    return null;
  }

  /// Parses raw LRC string into a sorted list of timestamped [LyricLine]s.
  /// Handles timestamp formats like [mm:ss.xx], [mm:ss.xxx], [mm:ss].
  List<LyricLine> parseLrc(String rawLrc) {
    if (rawLrc.trim().isEmpty) return [];

    final lines = rawLrc.split('\n');
    final List<LyricLine> parsed = [];

    // Regex matching [mm:ss.xx] or [mm:ss.xxx] or [mm:ss]
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fractionStr = match.group(3);

        int milliseconds = 0;
        if (fractionStr != null) {
          if (fractionStr.length == 1) {
            milliseconds = int.parse(fractionStr) * 100;
          } else if (fractionStr.length == 2) {
            milliseconds = int.parse(fractionStr) * 10;
          } else {
            milliseconds = int.parse(fractionStr.substring(0, 3));
          }
        }

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        final text = match.group(4)?.trim() ?? '';
        parsed.add(LyricLine(timestamp: duration, text: text));
      } else {
        // Plain lyric without timestamp fallback
        if (!trimmed.startsWith('[ti:') &&
            !trimmed.startsWith('[ar:') &&
            !trimmed.startsWith('[al:') &&
            !trimmed.startsWith('[by:')) {
          parsed.add(LyricLine(timestamp: Duration.zero, text: trimmed));
        }
      }
    }

    parsed.sort();
    return parsed;
  }

  /// Finds the active lyric line index for a given playback position.
  /// Returns -1 if no line has started yet.
  int getActiveLyricIndex(List<LyricLine> lyrics, Duration currentPosition) {
    if (lyrics.isEmpty) return -1;

    for (int i = lyrics.length - 1; i >= 0; i--) {
      if (currentPosition >= lyrics[i].timestamp) {
        return i;
      }
    }
    return 0;
  }
}
