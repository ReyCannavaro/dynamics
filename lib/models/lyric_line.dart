/// Represents a single timestamped lyric line for synced playback
class LyricLine implements Comparable<LyricLine> {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestampMs': timestamp.inMilliseconds,
      'text': text,
    };
  }

  factory LyricLine.fromMap(Map<dynamic, dynamic> map) {
    return LyricLine(
      timestamp: Duration(milliseconds: (map['timestampMs'] as num?)?.toInt() ?? 0),
      text: (map['text'] as String?) ?? '',
    );
  }

  @override
  int compareTo(LyricLine other) => timestamp.compareTo(other.timestamp);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLine &&
          runtimeType == other.runtimeType &&
          timestamp == other.timestamp &&
          text == other.text;

  @override
  int get hashCode => timestamp.hashCode ^ text.hashCode;

  @override
  String toString() => 'LyricLine(${timestamp.inMilliseconds}ms: "$text")';
}
