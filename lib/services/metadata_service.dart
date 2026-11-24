import 'dart:convert';
import 'dart:io';
import 'package:audiotags/audiotags.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../core/constants.dart';
import '../models/song.dart';

/// Service responsible for ID3 tag extraction, filename cleaning, and metadata fallbacks
class MetadataService {
  static MetadataService? _instance;
  static MetadataService get instance {
    _instance ??= MetadataService._internal();
    return _instance!;
  }

  MetadataService._internal();

  /// Extracts metadata from an audio file and creates a [Song] entity.
  /// If embedded tags are missing, applies intelligent filename cleaning.
  Future<Song> extractMetadata(String filePath) async {
    final file = File(filePath);
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : file.path.split(Platform.pathSeparator).last;

    Tag? tag;
    try {
      tag = await AudioTags.read(filePath);
    } catch (e) {
      debugPrint('Error reading tags from $filePath: $e');
    }

    // Determine Title
    String title = tag?.title?.trim() ?? '';
    if (title.isEmpty) {
      title = cleanFilename(fileName);
    }

    // Determine Artist
    String artist = tag?.trackArtist?.trim() ??
        tag?.albumArtist?.trim() ??
        '';
    if (artist.isEmpty) {
      final parsed = _extractArtistFromFilename(fileName);
      artist = parsed ?? 'Unknown Artist';
    }

    // Determine Album
    String album = tag?.album?.trim() ?? 'Unknown Album';
    if (album.isEmpty) {
      album = 'Unknown Album';
    }

    // Determine Duration
    final durationSec = tag?.duration ?? 0;
    final durationMs = durationSec * 1000;

    // Determine Cover Art
    Uint8List? coverArt;
    if (tag?.pictures.isNotEmpty ?? false) {
      coverArt = tag!.pictures.first.bytes;
    }

    // Unique deterministic ID based on SHA-1 hash of file path
    final id = sha1.convert(utf8.encode(filePath)).toString();

    return Song(
      id: id,
      title: title,
      artist: artist,
      album: album,
      durationMs: durationMs,
      filePath: filePath,
      coverArtBytes: coverArt,
    );
  }

  /// Cleans a raw filename into a human-readable title
  /// E.g. "01 - Bohemian_Rhapsody.mp3" -> "Bohemian Rhapsody"
  String cleanFilename(String filename) {
    var clean = filename;

    // 1. Remove supported file extensions
    for (final ext in DynamicsConstants.supportedAudioExtensions) {
      final pattern = RegExp('\\.$ext\$', caseSensitive: false);
      clean = clean.replaceAll(pattern, '');
    }

    // 2. Replace underscores with spaces
    clean = clean.replaceAll('_', ' ');

    // 3. Normalize multiple spaces and trim
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 4. Remove leading track numbers e.g. "01 - ", "01. ", "01-", "1. "
    clean = clean.replaceAll(RegExp(r'^\d+[\s\.\-_]+'), '');

    // 5. If filename has format "Artist - Title", extract Title
    if (clean.contains(' - ')) {
      final parts = clean.split(' - ');
      if (parts.length >= 2 && parts[1].trim().isNotEmpty) {
        clean = parts.sublist(1).join(' - ');
      }
    }

    // 6. Final trim
    clean = clean.trim();

    return clean.isNotEmpty ? clean : 'Unknown Track';
  }

  /// Tries to extract artist name if filename has format "Artist - Title"
  String? _extractArtistFromFilename(String filename) {
    var raw = filename;
    for (final ext in DynamicsConstants.supportedAudioExtensions) {
      raw = raw.replaceAll(RegExp('\\.$ext\$', caseSensitive: false), '');
    }

    // Replace underscores with spaces
    raw = raw.replaceAll('_', ' ');
    raw = raw.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove leading track numbers
    raw = raw.replaceAll(RegExp(r'^\d+[\s\.\-_]+'), '');

    if (raw.contains(' - ')) {
      final parts = raw.split(' - ');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        return parts[0].trim();
      }
    }
    return null;
  }

  /// Optional progressive enhancement: fetch high-resolution cover art from iTunes Search API
  Future<Uint8List?> fetchOnlineCoverArt(String title, String artist) async {
    try {
      final query = Uri.encodeComponent('$title $artist');
      final url = Uri.parse('${DynamicsConstants.itunesSearchApiBase}?term=$query&entity=song&limit=1');

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null && results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final rawArtUrl = first['artworkUrl100'] as String?;
          if (rawArtUrl != null) {
            // Replace 100x100 with 600x600 for high resolution
            final highResUrl = rawArtUrl.replaceAll('100x100bb', '600x600bb');
            final imgResponse = await http.get(Uri.parse(highResUrl)).timeout(const Duration(seconds: 5));
            if (imgResponse.statusCode == 200) {
              return imgResponse.bodyBytes;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Online cover art search failed (offline or network error): $e');
    }
    return null;
  }
}
