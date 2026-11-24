# Dynamics — Detailed 7-Stage Execution Roadmap

This roadmap breaks down the complete development lifecycle of **Dynamics** into seven structured, verifiable stages. Every stage adheres strictly to the architectural standards in [.agents/AGENTS.md](AGENTS.md) and the Spotify visual design language specified in [.agents/DESIGN.md](DESIGN.md).

---

## Stage 1: Foundation, Data Models & Hive Local Database

### Objective
Establish the core domain entities and lightweight, zero-latency local database storage using Hive. Ensure the app has a persistent, offline-first data layer before building UI or playback logic.

### Technical Tasks
1. **Core Constants (`lib/core/constants.dart`):**
   - Define Hive box names: `songsBox`, `lyricsBox`, `profileBox`, `settingsBox`.
   - Define API endpoints: `https://lrclib.net/api/get` (LRCLIB), iTunes search fallback URL.
   - Define fallback asset constants (vinyl placeholder, default avatar).
2. **Domain Models (`lib/models/`):**
   - `Song` (`lib/models/song.dart`):
     - Fields: `String id`, `String title`, `String artist`, `String album`, `int durationMs`, `String filePath`, `List<int>? coverArtBytes`, `int playCount`, `int lastPlayedEpochMs`, `bool isFavorite`.
     - JSON/Map serialization and deserialization (`toMap()` and `fromMap()`) for schema-less Hive storage.
   - `LyricLine` (`lib/models/lyric_line.dart`):
     - Fields: `Duration timestamp`, `String text`.
   - `UserProfile` (`lib/models/user_profile.dart`):
     - Fields: `String displayName` (Default: "Rey Cannavaro"), `String bio` (Default: "Living in Dynamics 🎧"), `String? avatarPath`, `int totalListeningSeconds`.
3. **Storage Service (`lib/services/storage_service.dart`):**
   - Initialize Hive in the application documents directory via `Hive.initFlutter()`.
   - Open and expose typed boxes: `songsBox`, `lyricsBox`, `profileBox`.
   - Implement CRUD operations for songs, lyrics caching, and profile state.
   - Seed default `UserProfile` if first launch.

### Verification Checklist
- [ ] Hive initializes without errors on desktop and Android.
- [ ] Storing, reading, and deleting a dummy song in `songsBox` persists across app restarts.
- [ ] `flutter analyze` returns 0 issues.

---

## Stage 2: Audio Engine & Background Playback Service

### Objective
Build a robust, gapless audio player engine with native background playback, lock-screen notification controls, and state streams.

### Technical Tasks
1. **Audio Player Service (`lib/services/audio_player_service.dart`):**
   - Initialize `just_audio.AudioPlayer`.
   - Maintain a dynamic `ConcatenatingAudioSource` playlist queue.
   - Wrap tracks inside `AudioSource.uri(Uri.file(song.filePath), tag: MediaItem(...))` to integrate with `just_audio_background` and `audio_service`.
   - Supply notification metadata: `id`, `title`, `artist`, `album`, `artUri` (write cover art bytes to temporary cache for lock-screen display).
   - Implement playback controls: `play()`, `pause()`, `seek(Duration)`, `skipToNext()`, `skipToPrevious()`, `setShuffleMode(bool)`, `setLoopMode(LoopMode)`.
   - Expose reactive streams: `playbackStateStream`, `positionStream`, `durationStream`, `currentIndexStream`.
2. **Player Provider (`lib/providers/player_provider.dart`):**
   - Bridge between UI and `AudioPlayerService`.
   - Track active `Song? currentSong`, `bool isPlaying`, `Duration currentPosition`, `Duration totalDuration`, `bool isShuffleEnabled`, `LoopMode loopMode`.
   - Implement 30-second listening milestone hook: if a track plays for $\ge 30$ seconds, dispatch event to increment its `playCount` and accumulate listening time.

### Verification Checklist
- [ ] Audio plays smoothly from a local file path.
- [ ] Player state changes (playing, paused, completed) reflect in real-time streams.
- [ ] Background notification appears on Android with operational media controls.
- [ ] Lock screen displays song title, artist, and artwork.

---

## Stage 3: Smart File Import & ID3 Metadata Engine

### Objective
Allow users to pick audio files or entire music folders, automatically extract embedded ID3 tags & cover artwork, apply smart filename cleaning, and store tracks into the library.

### Technical Tasks
1. **Metadata Service (`lib/services/metadata_service.dart`):**
   - Integrate `audiotags` to read ID3v1/ID3v2 metadata from file paths (`mp3`, `flac`, `m4a`, `wav`, `aac`).
   - Extract `title`, `artist`, `album`, `duration`, and raw image bytes (`Picture.bytes`).
   - **Smart Fallback Cleaner:** If `title` tag is missing, parse filename: remove extension, replace underscores with spaces, strip leading track numbers (`01 - `, `1. `).
   - Fallback `artist` to "Unknown Artist", `album` to "Unknown Album".
   - (Optional) Online metadata fallback: Query public search APIs (e.g. iTunes Search API) if embedded artwork is absent and device is online.
2. **Library Provider (`lib/providers/library_provider.dart`):**
   - `importSingleFile()`: Open `FilePicker.platform.pickFiles()` with audio extensions filter.
   - `importFolder()`: Scan selected directory recursively for supported audio files.
   - Batch extraction without blocking the UI thread (using async batches).
   - Save parsed `Song` instances to Hive `songsBox` and update in-memory state.
   - Expose sorting (By Date Added, Title, Artist, Most Played).
3. **Album Art Widget (`lib/ui/widgets/album_art_image.dart`):**
   - Display embedded bytes if available (`Image.memory`).
   - Display a sleek dark vinyl/note placeholder icon if null.

### Verification Checklist
- [ ] Can pick individual audio files and entire folders.
- [ ] ID3 tags (Title, Artist, Album, Cover Art) correctly extracted.
- [ ] Files with empty tags receive clean titles and graceful placeholders.
- [ ] Imported tracks immediately appear in local Hive storage.

---

## Stage 4: Spotify Shell UI, Navigation & Library Screen

### Objective
Implement the primary visual shell of Dynamics adhering strictly to [DESIGN.md](DESIGN.md): near-black dark surfaces, Spotify Green accents, bottom navigation, song tiles, and the floating Mini Player.

### Technical Tasks
1. **Design Tokens & Components:**
   - Use `DynamicsTheme` ([lib/core/theme.dart](../lib/core/theme.dart)).
   - `PillButton` (`lib/ui/widgets/pill_button.dart`): Spotify pill button (radius 500px or 9999px, uppercase text, letter spacing 1.4px).
   - `SongTile` (`lib/ui/widgets/song_tile.dart`): 56px height track row with 48px rounded cover art (radius 4px), title in bold white, artist in silver (`#B3B3B3`), playing indicator, and popup menu.
2. **Mini Player (`lib/ui/widgets/mini_player.dart`):**
   - Floats directly above the bottom navigation bar.
   - Background: Dark Surface (`#181818` or `#1F1F1F`) with subtle border shadow.
   - Displays cover thumbnail, scrolling song title, artist, and circular play/pause button.
   - Thin 2px progress bar in Spotify Green (`#1ED760`) at the bottom/top edge of the mini player.
   - Tap anywhere on the mini player to open the full-screen player.
3. **Main Scaffold (`lib/ui/screens/main_scaffold.dart`):**
   - Bottom navigation bar: **Library / Home**, **Search**, **Profile**.
   - Persistent `MiniPlayer` visibility conditional on `playerProvider.currentSong != null`.
4. **Home / Library Screen (`lib/ui/screens/home_screen.dart`):**
   - Top bar with app branding "Dynamics" and "Import" pill button.
   - Empty state widget: Sleek dark illustration + "No songs yet. Import your music to start listening."
   - Scrollable track list rendered via `SongTile`. Tap to play track immediately.

### Verification Checklist
- [ ] Visual aesthetic matches Spotify mobile dark mode (`#121212`, `#181818`).
- [ ] Bottom navigation switches seamlessly between screens.
- [ ] Mini player appears when a song is playing and stays anchored.
- [ ] Song tiles show correct titles, artists, and thumbnail art.

---

## Stage 5: Full-Screen Now Playing Player Screen

### Objective
Create an immersive full-screen playback screen with large album art, real-time scrubber, Spotify playback controls, and lyrics toggle.

### Technical Tasks
1. **Full Player Screen (`lib/ui/screens/player_screen.dart`):**
   - Modal bottom sheet or slide-up transition from the Mini Player.
   - Background: Near-black (`#121212`) or subtle dynamic blurred gradient derived from album art.
   - Top bar: Chevron collapse button, playlist/album name, and more options button.
2. **Artwork & Track Details:**
   - Centered large album art with rounded corners (8px) and heavy elevation shadow (`rgba(0,0,0,0.5) 0px 8px 24px`).
   - Title in 22px bold white (`#FFFFFF`) with marquee text if overflowing.
   - Artist in 16px silver (`#B3B3B3`).
   - Favorite / Like heart button (toggles `isFavorite` in database).
3. **Scrubber / Seekbar:**
   - Custom Slider with Spotify styling: inactive track `#4D4D4D`, active track `#1ED760` or pure white.
   - Labels on sides: elapsed time `01:45` on the left, remaining or total duration `03:50` on the right (font size 12px silver).
   - Drag to seek with immediate feedback.
4. **Playback Control Bar:**
   - Shuffle button (toggles off / on with green dot indicator).
   - Previous track button (`Icons.skip_previous_rounded`).
   - Center Play/Pause button: 56px circular button (50% radius) in Spotify Green `#1ED760` with black icon.
   - Next track button (`Icons.skip_next_rounded`).
   - Repeat button (cycles Off -> Repeat All -> Repeat One).
5. **Lyrics Drawer Preview:**
   - Mini lyrics snippet card at the bottom of the screen. Tap expands to Stage 6 Karaoke view.

### Verification Checklist
- [ ] Full screen player opens smoothly from mini player.
- [ ] Seekbar scrubs smoothly and updates playback position.
- [ ] Controls (Play, Pause, Next, Prev, Shuffle, Repeat) function accurately.
- [ ] Like button updates `isFavorite` state in Hive.

---

## Stage 6: Synchronized Karaoke Lyrics Engine (LRCLIB)

### Objective
Integrate the open-source LRCLIB API to fetch, parse, and permanently cache synchronized lyrics (`.lrc`), rendering an auto-scrolling karaoke lyrics view in real time.

### Technical Tasks
1. **Lyrics Service (`lib/services/lyrics_service.dart`):**
   - Check local Hive `lyricsBox` by `song.id`. If exists, load instantly (offline).
   - If missing and online, send GET to `https://lrclib.net/api/get`:
     - Parameters: `artist_name`, `track_name`, `album_name`, `duration` (in seconds).
   - Parse returned `syncedLyrics` string using regex:
     - Pattern: `\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)`
     - Convert minutes, seconds, and hundredths into a Dart `Duration`.
     - Construct `List<LyricLine>`.
   - If `syncedLyrics` is null but `plainLyrics` exists, provide fallback static lyrics.
   - Cache raw response into Hive `lyricsBox`.
2. **Synchronized Karaoke View (`lib/ui/screens/lyrics_screen.dart`):**
   - Dedicated full-screen or expanded card lyrics view.
   - Dynamic synchronization: Compare `player.position` to `LyricLine.timestamp`.
   - **Active line styling:** Pure white text (`#FFFFFF`), bold font weight, slightly enlarged scale.
   - **Inactive lines styling:** Muted dark gray (`#535353`), regular weight.
   - **Auto-scroll:** `ScrollController.animateTo()` smoothly scrolls the active lyric line to center screen.
   - **Interactive Seek:** Tapping any lyric line immediately seeks the audio player to that exact timestamp!

### Verification Checklist
- [ ] Fetches synced lyrics from LRCLIB for recognized songs.
- [ ] Lyrics auto-scroll in sync with vocal audio.
- [ ] Tapping a lyric line seeks playback directly to that lyric timestamp.
- [ ] Lyrics cache permanently to Hive: works 100% offline on subsequent plays.

---

## Stage 7: Personalized Offline Profile, Local Stats & APK Build

### Objective
Build the personalized offline user profile with local listening statistics ("Dynamics Wrapped"), ensure complete offline resilience, and produce the final Android APK.

### Technical Tasks
1. **Offline User Profile Screen (`lib/ui/screens/profile_screen.dart`):**
   - Header with user avatar (circular 50%), Display Name ("Rey Cannavaro"), and Bio ("Living in Dynamics 🎧").
   - Inline edit dialog for name, bio, and custom avatar picture.
2. **Local Stats ("Dynamics Wrapped"):**
   - Real-time listening stats computed entirely from local storage:
     - **Total Listening Time:** Formatted in hours and minutes (e.g. "14 hrs 32 mins").
     - **Total Songs in Library:** Count of imported tracks.
     - **Top 5 Most Played Tracks:** Ranked list sorted by `song.playCount` with play count badges.
3. **Search & Filter Screen (`lib/ui/screens/search_screen.dart`):**
   - 500px pill search input with search icon.
   - Instant real-time filtering of local songs by title, artist, or album.
4. **Offline Resilience & Polish:**
   - Test entire app in Airplane Mode (playback, lyrics cache, profile stats, metadata).
   - Handle corrupt files, missing permissions, and empty states gracefully.
   - Run `flutter analyze` to ensure 0 errors and 0 warnings.
5. **Android Build Verification:**
   - Execute `flutter build apk --release` to verify compilation of native Android artifacts.

### Verification Checklist
- [ ] Profile displays local stats accurately without any external server.
- [ ] Top 5 tracks update as songs play past 30 seconds.
- [ ] App is 100% functional in Airplane Mode (zero network dependency).
- [ ] `flutter build apk` succeeds and generates an installable release `.apk`.
