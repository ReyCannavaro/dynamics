import 'dart:typed_data';

/// Song model representing an imported audio track in Dynamics
class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int durationMs;
  final String filePath;
  final Uint8List? coverArtBytes;
  final int playCount;
  final int lastPlayedEpochMs;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
    required this.filePath,
    this.coverArtBytes,
    this.playCount = 0,
    this.lastPlayedEpochMs = 0,
    this.isFavorite = false,
  });

  /// Human-readable duration in mm:ss (or hh:mm:ss if > 1 hour)
  String get formattedDuration {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final secondsPadded = seconds.toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutesPadded = (minutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutesPadded:$secondsPadded';
    }
    return '$minutes:$secondsPadded';
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? durationMs,
    String? filePath,
    Uint8List? coverArtBytes,
    int? playCount,
    int? lastPlayedEpochMs,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      filePath: filePath ?? this.filePath,
      coverArtBytes: coverArtBytes ?? this.coverArtBytes,
      playCount: playCount ?? this.playCount,
      lastPlayedEpochMs: lastPlayedEpochMs ?? this.lastPlayedEpochMs,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': durationMs,
      'filePath': filePath,
      'coverArtBytes': coverArtBytes != null ? List<int>.from(coverArtBytes!) : null,
      'playCount': playCount,
      'lastPlayedEpochMs': lastPlayedEpochMs,
      'isFavorite': isFavorite,
    };
  }

  factory Song.fromMap(Map<dynamic, dynamic> map) {
    Uint8List? cover;
    final rawCover = map['coverArtBytes'];
    if (rawCover is List) {
      cover = Uint8List.fromList(rawCover.cast<int>());
    } else if (rawCover is Uint8List) {
      cover = rawCover;
    }

    return Song(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Unknown Title',
      artist: (map['artist'] as String?) ?? 'Unknown Artist',
      album: (map['album'] as String?) ?? 'Unknown Album',
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      filePath: (map['filePath'] as String?) ?? '',
      coverArtBytes: cover,
      playCount: (map['playCount'] as num?)?.toInt() ?? 0,
      lastPlayedEpochMs: (map['lastPlayedEpochMs'] as num?)?.toInt() ?? 0,
      isFavorite: (map['isFavorite'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: "$title", artist: "$artist", plays: $playCount)';
}
