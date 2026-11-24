/// App-wide constants for Dynamics
class DynamicsConstants {
  // --- APP INFO ---
  static const String appName = 'Dynamics';
  static const String appTagline = 'Ad-Free Offline Music Experience';

  // --- HIVE BOX NAMES ---
  static const String boxSongs = 'dynamics_songs_box';
  static const String boxLyrics = 'dynamics_lyrics_box';
  static const String boxProfile = 'dynamics_profile_box';
  static const String boxSettings = 'dynamics_settings_box';

  // --- STORAGE KEYS ---
  static const String keyProfile = 'user_profile';
  static const String keyRepeatMode = 'repeat_mode';
  static const String keyShuffleMode = 'shuffle_mode';

  // --- API ENDPOINTS ---
  static const String lrclibApiBase = 'https://lrclib.net/api/get';
  static const String itunesSearchApiBase = 'https://itunes.apple.com/search';

  // --- DEFAULTS ---
  static const String defaultUserName = 'Rey Cannavaro';
  static const String defaultUserBio = 'Living in Dynamics 🎧';
  static const int minListeningSecondsForPlayCount = 30;

  // --- SUPPORTED AUDIO EXTENSIONS ---
  static const List<String> supportedAudioExtensions = [
    'mp3',
    'flac',
    'm4a',
    'wav',
    'aac',
    'ogg',
  ];
}
