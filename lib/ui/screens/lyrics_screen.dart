import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/lyric_line.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import '../../services/lyrics_service.dart';

/// Real-time karaoke synchronized lyrics screen with auto-scroll and tap-to-seek
class LyricsScreen extends StatefulWidget {
  final Song song;

  const LyricsScreen({
    super.key,
    required this.song,
  });

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final LyricsService _lyricsService = LyricsService.instance;
  final ScrollController _scrollController = ScrollController();

  List<LyricLine> _lyrics = [];
  bool _isLoading = true;
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoading = true);

    final raw = await _lyricsService.getLyrics(widget.song);

    if (mounted) {
      setState(() {
        _lyrics = raw != null ? _lyricsService.parseLrc(raw) : [];
        _isLoading = false;
      });
    }
  }

  void _scrollToActiveLine(int activeIndex) {
    if (!_scrollController.hasClients || activeIndex < 0 || _lyrics.isEmpty) return;

    // Approximate line height ~58px. Center active line vertically.
    final screenHeight = MediaQuery.of(context).size.height;
    final targetOffset = (activeIndex * 58.0) - (screenHeight * 0.35);
    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final activeIndex = _lyricsService.getActiveLyricIndex(_lyrics, player.position);

    // Auto-scroll when active lyric line advances
    if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
      _lastActiveIndex = activeIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveLine(activeIndex);
      });
    }

    return Scaffold(
      backgroundColor: DynamicsTheme.nearBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context),

            // Lyrics List or Empty/Loading State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(DynamicsTheme.spotifyGreen),
                      ),
                    )
                  : _lyrics.isEmpty
                      ? _buildEmptyLyricsState()
                      : _buildLyricsList(player, activeIndex),
            ),

            // Bottom Mini Scrubber & Play/Pause
            _buildBottomControls(player),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            color: DynamicsTheme.textBase,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DynamicsTheme.textBase,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DynamicsTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DynamicsTheme.darkSurface,
              borderRadius: DynamicsTheme.radiusBadge,
              border: Border.all(color: DynamicsTheme.borderGray, width: 0.5),
            ),
            child: const Row(
              children: [
                Icon(Icons.mic_rounded, size: 12, color: DynamicsTheme.spotifyGreen),
                SizedBox(width: 4),
                Text(
                  'KARAOKE',
                  style: TextStyle(
                    color: DynamicsTheme.spotifyGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList(PlayerProvider player, int activeIndex) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      itemCount: _lyrics.length,
      itemBuilder: (context, index) {
        final line = _lyrics[index];
        final isActive = index == activeIndex;
        final isPast = index < activeIndex;

        Color textColor;
        double fontSize;
        FontWeight fontWeight;

        if (isActive) {
          textColor = DynamicsTheme.textBase;
          fontSize = 22.0;
          fontWeight = FontWeight.w800;
        } else if (isPast) {
          textColor = DynamicsTheme.textSecondary;
          fontSize = 17.0;
          fontWeight = FontWeight.w600;
        } else {
          textColor = DynamicsTheme.borderGray;
          fontSize = 17.0;
          fontWeight = FontWeight.w600;
        }

        return GestureDetector(
          onTap: () {
            // Instant seek to tapped lyric line
            if (line.timestamp > Duration.zero) {
              player.seek(line.timestamp);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
                height: 1.35,
                letterSpacing: -0.3,
              ),
              child: Text(
                line.text.isNotEmpty ? line.text : '♪',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyLyricsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: DynamicsTheme.darkSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lyrics_outlined,
                size: 32,
                color: DynamicsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Lyrics Available',
              style: TextStyle(
                color: DynamicsTheme.textBase,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We could not find synchronized lyrics for this song on LRCLIB. Once lyrics are fetched online, they are saved permanently for offline playback.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DynamicsTheme.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _fetchLyrics,
              icon: const Icon(Icons.refresh_rounded, color: DynamicsTheme.spotifyGreen, size: 18),
              label: const Text(
                'RETRY SEARCH',
                style: TextStyle(
                  color: DynamicsTheme.spotifyGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(PlayerProvider player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: DynamicsTheme.darkSurface,
        border: Border(top: BorderSide(color: DynamicsTheme.darkCard, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            player.formattedPosition,
            style: const TextStyle(color: DynamicsTheme.textMuted, fontSize: 11),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                activeTrackColor: DynamicsTheme.spotifyGreen,
                inactiveTrackColor: DynamicsTheme.borderGray,
                thumbColor: DynamicsTheme.textBase,
              ),
              child: Slider(
                min: 0.0,
                max: player.duration.inMilliseconds > 0
                    ? player.duration.inMilliseconds.toDouble()
                    : 1.0,
                value: player.position.inMilliseconds
                    .toDouble()
                    .clamp(0.0, player.duration.inMilliseconds.toDouble()),
                onChanged: (val) => player.seek(Duration(milliseconds: val.toInt())),
              ),
            ),
          ),
          Text(
            player.formattedDuration,
            style: const TextStyle(color: DynamicsTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => player.togglePlayPause(),
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: DynamicsTheme.spotifyGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(
                player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
