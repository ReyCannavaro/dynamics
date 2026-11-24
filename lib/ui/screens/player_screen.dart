import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../widgets/album_art_image.dart';
import 'lyrics_screen.dart';

/// Full-screen Spotify-styled Now Playing player screen
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: DynamicsTheme.nearBlack,
        body: Center(
          child: Text(
            'No song currently playing',
            style: TextStyle(color: DynamicsTheme.textMuted),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final artSize = (screenWidth * 0.82).clamp(240.0, 340.0);

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            children: [
              // Top Bar (Dismiss Chevron, Source Label, Options)
              _buildTopBar(context, song),

              const Spacer(flex: 1),

              // Large Center Album Art with Heavy Elevation Shadow
              Center(
                child: AlbumArtImage(
                  bytes: song.coverArtBytes,
                  size: artSize,
                  borderRadius: DynamicsTheme.radiusCard,
                  boxShadow: DynamicsTheme.heavyShadow,
                ),
              ),

              const Spacer(flex: 1),

              // Track Title, Artist & Favorite Toggle Row
              _buildTrackDetails(song, player),

              const SizedBox(height: 16),

              // Scrubber / Seekbar & Time Labels
              _buildScrubber(player),

              const SizedBox(height: 8),

              // Playback Controls Row (Shuffle, Prev, Play/Pause, Next, Repeat)
              _buildControlBar(player),

              const SizedBox(height: 16),

              // Bottom Actions Bar (Offline label / Lyrics button)
              _buildBottomActions(context, song),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Song song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          color: DynamicsTheme.textBase,
          splashRadius: 22,
          onPressed: () => Navigator.of(context).pop(),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PLAYING FROM YOUR LIBRARY',
              style: TextStyle(
                color: DynamicsTheme.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.album.isNotEmpty ? song.album : 'Dynamics Offline',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DynamicsTheme.textBase,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 22),
          color: DynamicsTheme.textBase,
          splashRadius: 22,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${song.title} (${song.formattedDuration})'),
                duration: const Duration(seconds: 1),
                backgroundColor: DynamicsTheme.darkSurface,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrackDetails(Song song, PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DynamicsTheme.textBase,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                song.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DynamicsTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: song.isFavorite ? DynamicsTheme.spotifyGreen : DynamicsTheme.textBase,
            size: 26,
          ),
          splashRadius: 24,
          onPressed: () => player.toggleFavorite(),
        ),
      ],
    );
  }

  Widget _buildScrubber(PlayerProvider player) {
    final totalDurationMs = player.duration.inMilliseconds.toDouble();
    final currentPositionMs = player.position.inMilliseconds.toDouble();

    // Use drag value if user is scrubbing, otherwise current playback position
    final sliderValue = (_dragValue ?? currentPositionMs).clamp(0.0, totalDurationMs > 0 ? totalDurationMs : 1.0);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: DynamicsTheme.textBase,
            inactiveTrackColor: DynamicsTheme.borderGray,
            thumbColor: DynamicsTheme.textBase,
            overlayColor: DynamicsTheme.textBase.withValues(alpha: 0.15),
          ),
          child: Slider(
            min: 0.0,
            max: totalDurationMs > 0 ? totalDurationMs : 1.0,
            value: sliderValue,
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
            },
            onChangeEnd: (value) {
              player.seek(Duration(milliseconds: value.toInt()));
              setState(() {
                _dragValue = null;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                player.formattedPosition,
                style: const TextStyle(
                  color: DynamicsTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                player.formattedDuration,
                style: const TextStyle(
                  color: DynamicsTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar(PlayerProvider player) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle Button
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: player.isShuffle ? DynamicsTheme.spotifyGreen : DynamicsTheme.textMuted,
            size: 24,
          ),
          splashRadius: 22,
          onPressed: () => player.toggleShuffle(),
        ),

        // Skip Previous
        IconButton(
          icon: const Icon(
            Icons.skip_previous_rounded,
            color: DynamicsTheme.textBase,
            size: 38,
          ),
          splashRadius: 26,
          onPressed: () => player.previous(),
        ),

        // Big Circular Play/Pause Button (50% radius, Spotify Green)
        GestureDetector(
          onTap: () => player.togglePlayPause(),
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: DynamicsTheme.spotifyGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 36,
              ),
            ),
          ),
        ),

        // Skip Next
        IconButton(
          icon: const Icon(
            Icons.skip_next_rounded,
            color: DynamicsTheme.textBase,
            size: 38,
          ),
          splashRadius: 26,
          onPressed: () => player.next(),
        ),

        // Repeat Mode Button
        IconButton(
          icon: Icon(
            player.loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
            color: player.loopMode != LoopMode.off ? DynamicsTheme.spotifyGreen : DynamicsTheme.textMuted,
            size: 24,
          ),
          splashRadius: 22,
          onPressed: () => player.toggleRepeat(),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context, Song song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.devices_rounded, size: 16, color: DynamicsTheme.spotifyGreen),
            SizedBox(width: 8),
            Text(
              'Offline Listening',
              style: TextStyle(
                color: DynamicsTheme.spotifyGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Lyrics shortcut button (opens Stage 6 Karaoke view)
        InkWell(
          borderRadius: DynamicsTheme.radiusCard,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LyricsScreen(song: song),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: DynamicsTheme.midDark,
              borderRadius: DynamicsTheme.radiusBadge,
            ),
            child: const Row(
              children: [
                Icon(Icons.lyrics_outlined, size: 14, color: DynamicsTheme.spotifyGreen),
                SizedBox(width: 6),
                Text(
                  'LYRICS',
                  style: TextStyle(
                    color: DynamicsTheme.spotifyGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
