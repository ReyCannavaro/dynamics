import '../core/constants.dart';

/// Offline-first personalized user profile for Dynamics
class UserProfile {
  final String displayName;
  final String bio;
  final String? avatarPath;
  final int totalListeningSeconds;

  const UserProfile({
    this.displayName = DynamicsConstants.defaultUserName,
    this.bio = DynamicsConstants.defaultUserBio,
    this.avatarPath,
    this.totalListeningSeconds = 0,
  });

  /// Formatted listening time string (e.g. "12 hrs 34 mins" or "45 mins")
  String get formattedListeningTime {
    final hours = totalListeningSeconds ~/ 3600;
    final minutes = (totalListeningSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours hrs ${minutes > 0 ? '$minutes mins' : ''}'.trim();
    }
    if (minutes > 0) {
      return '$minutes mins';
    }
    return '$totalListeningSeconds secs';
  }

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarPath,
    int? totalListeningSeconds,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      totalListeningSeconds: totalListeningSeconds ?? this.totalListeningSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'bio': bio,
      'avatarPath': avatarPath,
      'totalListeningSeconds': totalListeningSeconds,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) {
    return UserProfile(
      displayName: (map['displayName'] as String?) ?? DynamicsConstants.defaultUserName,
      bio: (map['bio'] as String?) ?? DynamicsConstants.defaultUserBio,
      avatarPath: map['avatarPath'] as String?,
      totalListeningSeconds: (map['totalListeningSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          bio == other.bio &&
          avatarPath == other.avatarPath &&
          totalListeningSeconds == other.totalListeningSeconds;

  @override
  int get hashCode =>
      displayName.hashCode ^
      bio.hashCode ^
      avatarPath.hashCode ^
      totalListeningSeconds.hashCode;

  @override
  String toString() =>
      'UserProfile(name: "$displayName", listeningTime: $formattedListeningTime)';
}
