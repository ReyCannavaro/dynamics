# Dynamics — Agent Operating Guidelines & Architecture Spec

## 1. Project Mission & Overview

**Dynamics** is a personal, premium offline-first music player mobile application built with Flutter. It delivers an ad-free, Spotify-grade listening experience powered entirely by the user's own audio files (MP3, FLAC, M4A). 

Key differentiators:
- **Zero Ads, Zero Subscriptions:** Fully private, local-first listening experience.
- **Smart Metadata Auto-Detection:** Automatically extracts ID3 tags (Title, Artist, Album, Album Art) upon file/folder import, with intelligent fallback search.
- **Synchronized Karaoke Lyrics:** Automatically queries LRCLIB (`https://lrclib.net`) to fetch timestamped lyrics (`.lrc`) and caches them permanently for offline karaoke-style playback.
- **True Background Playback:** Native lock-screen audio notification and background service handling via `just_audio` and `audio_service`.
- **Personalized Offline Profile:** Local-only user profile with avatars, bio, and real-time offline listening statistics (listening minutes, top played songs) without needing an external cloud database.
- **Strict Spotify Design Language:** Built strictly against the specifications documented in [DESIGN.md](DESIGN.md).

---

## 2. Agent Principles & Directives

Every AI agent operating in this repository **must** strictly abide by the following directives:

1. **Strict Design Fidelity:** Always follow the colors, geometries, typography, and spacing scales defined in `.agents/DESIGN.md` and `lib/core/theme.dart`. Never invent random accent colors or square button styles.
2. **Offline-First Resilience:** Network access is only a progressive enhancement (used for fetching lyrics and missing metadata). The app must be 100% operational when the device is completely offline or in Airplane Mode.
3. **Non-Blocking IO & State Management:** Audio playback, ID3 tag extraction, and file operations must never block the UI thread. Use asynchronous futures/streams and Provider state management.
4. **Permanent Cache Discipline:** Once metadata, album art, or synced lyrics are retrieved, they must be saved to local storage (Hive) so subsequent plays require zero network requests.
5. **Clean Architecture:** Maintain strict separation between `core/`, `models/`, `services/`, `providers/`, and `ui/`.

---

## 3. Technology Stack & Dependencies

| Domain | Library / Tool | Purpose |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.44+ (Dart 3) | Cross-platform mobile development (Target: Android/Desktop) |
| **Audio Engine** | `just_audio` | Robust audio streaming, playlist queue, position tracking |
| **Background Playback**| `just_audio_background`, `audio_service` | Android foreground service, lock screen media controls |
| **Tag Extraction** | `audiotags` | Extraction of ID3v1/ID3v2 tags and embedded album art bytes |
| **File Picker** | `file_picker` | Picking individual tracks or scanning whole music directories |
| **Storage & DB** | `hive`, `hive_flutter` | Lightweight, fast NoSQL key-value database for metadata & lyrics |
| **Key-Value Config** | `shared_preferences` | User preferences, active playback state persistence |
| **Networking** | `http` | Fetching synchronized lyrics from the LRCLIB API |
| **State Management** | `provider` | Reactive state management for player, library, and profile |

---

## 4. Architectural Layers & Structure

```
lib/
├── core/
│   ├── theme.dart            # Spotify design system tokens, colors, styles, shadows
│   └── constants.dart        # API URLs (LRCLIB), Hive box names, default assets
├── models/
│   ├── song.dart             # Song entity (id, title, artist, album, duration, path, coverArt)
│   ├── lyric_line.dart       # Single timestamped lyric (timestamp Duration, text)
│   └── user_profile.dart     # Offline user profile (name, bio, avatar, listening stats)
├── services/
│   ├── audio_player_service.dart # JustAudio wrapper with background media items
│   ├── metadata_service.dart     # ID3 tag extraction & cover art byte handling
│   ├── lyrics_service.dart       # LRCLIB API client & LRC parser (.lrc regex engine)
│   └── storage_service.dart      # Hive boxes initialization and CRUD operations
├── providers/
│   ├── player_provider.dart      # Audio state, playback position, current song, queue
│   ├── library_provider.dart     # Track list, import pipelines, search, sorting
│   └── profile_provider.dart     # Offline profile data, listening minutes tracking
└── ui/
    ├── screens/
    │   ├── main_scaffold.dart    # Bottom nav (Home/Library, Search, Profile) + MiniPlayer
    │   ├── home_screen.dart      # Song list, quick import button, playlist view
    │   ├── search_screen.dart    # Filter and find local songs by title/artist/album
    │   ├── player_screen.dart    # Full-screen player, scrubber, controls, album art
    │   ├── lyrics_screen.dart    # Auto-scrolling karaoke synchronized lyrics view
    │   └── profile_screen.dart   # Offline user profile, stats, top tracks
    └── widgets/
        ├── mini_player.dart      # Floating bottom bar with play/pause and progress
        ├── song_tile.dart        # Spotify-styled song row with thumbnail and popup menu
        ├── pill_button.dart      # Standardized Spotify 500px/9999px pill button
        └── album_art_image.dart  # Renders embedded bytes or fallback vinyl placeholder
```

---

## 5. Detailed Feature Specifications

### 5.1 Smart Audio File Import & Metadata Extraction
- **Action:** User taps "Import Songs" or "Import Folder".
- **Workflow:**
  1. `file_picker` picks files with audio extensions (`mp3`, `flac`, `m4a`, `wav`, `aac`).
  2. For each file, `MetadataService` uses `audiotags` to read embedded tags:
     - Title (fallback to clean filename if tag is empty).
     - Artist (fallback to "Unknown Artist").
     - Album (fallback to "Unknown Album").
     - Duration & Embedded picture bytes.
  3. If embedded tags are missing or generic, query online search (e.g. iTunes Search API / MusicBrainz) for high-res cover art and correct titles.
  4. Save song record into Hive `songsBox`.

### 5.2 Synced Lyrics Engine (LRCLIB Integration)
- **API Target:** `https://lrclib.net/api/get?artist_name={artist}&track_name={title}&album_name={album}&duration={seconds}`
- **Format:** Synchronized LRC lines formatted as `[mm:ss.xx] Lyric text`.
- **Workflow:**
  1. Check Hive `lyricsBox` for existing cached lyrics of the song ID.
  2. If missing and online, send GET request to LRCLIB API.
  3. Parse returned `syncedLyrics` into a `List<LyricLine>`:
     ```dart
     class LyricLine {
       final Duration time;
       final String text;
     }
     ```
  4. Cache the raw LRC into Hive.
  5. During playback, compare current `player.position` stream to `LyricLine.time` to highlight active line and trigger smooth auto-scroll.

### 5.3 Audio Engine & Background Notification
- Use `just_audio` with `AudioSource.uri(..., tag: MediaItem(...))`.
- Supply `MediaItem`:
  - `id`: Song ID.
  - `album`: Song album.
  - `title`: Song title.
  - `artist`: Song artist.
  - `artUri`: File URI or temporary file for the notification thumbnail.
- Maintain a dynamic playlist (`ConcatenatingAudioSource`) for gapless playback, repeat modes (off, all, one), and shuffle.

### 5.4 Personalized Offline Profile & Local Stats
- **No external authentication.** Data is stored locally in `profileBox`.
- User can edit:
  - Display Name (Default: "Rey Cannavaro").
  - Bio / Tagline (Default: "Living in Dynamics 🎧").
  - Avatar image (stored in local app documents).
- **Listening Stats Counter:**
  - Whenever a song plays for >30 seconds, increment that song's `playCount`.
  - Accumulate `totalListeningSeconds` into the profile.
  - Display "Top 5 Most Played Tracks" and "Total Time Listened" in the Profile Screen (offline Spotify Wrapped feel).

---

## 6. Design System Enforcement (from DESIGN.md)

1. **Achromatic Dark Theme:**
   - Base background: `#121212` (`DynamicsTheme.nearBlack`)
   - Cards/Containers: `#181818` (`DynamicsTheme.darkSurface`)
   - Interactive elements: `#1F1F1F` (`DynamicsTheme.midDark`)
2. **Spotify Green:**
   - Accent color: `#1ED760` (`DynamicsTheme.spotifyGreen`)
   - **Rule:** Never use green as a background for cards or large surfaces. Green is strictly functional: play/pause buttons, active slider track, active tab indicator.
3. **Pill & Circular Geometry:**
   - Buttons: `BorderRadius.circular(9999)` or `500`
   - Play/Pause circular controls: `50%` radius circular containers
   - Card corners: `BorderRadius.circular(8)`
4. **Typography Contrast:**
   - Primary text: Pure White `#FFFFFF` (FontWeight 700 for titles, 400 for standard)
   - Secondary text: Silver `#B3B3B3`
   - Button text: Uppercase with letter spacing `1.4`–`2.0` px.

---

## 7. Verification Checklist for Agents

Before completing any task or PR:
- [ ] Run `flutter analyze` — ensure zero errors and zero warnings.
- [ ] Verify null-safety and robust error handling for missing files, corrupt audio tags, or offline HTTP failures.
- [ ] Ensure all colors and UI components use tokens from `DynamicsTheme`.
- [ ] Test background audio lifecycle (Android service compatibility).
