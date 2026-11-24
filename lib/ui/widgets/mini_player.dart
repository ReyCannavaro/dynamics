import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/song.dart';
import 'album_art_image.dart';

/// Floating bottom mini-player bar adhering to Spotify design guidelines
class MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onToggleFavorite;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.progress,
    required this.onTap,
    required this.onPlayPause,
    this.onNext,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: DynamicsTheme.darkSurface,
        borderRadius: DynamicsTheme.radiusCard,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          borderRadius: DynamicsTheme.radiusCard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Cover Art
                    AlbumArtImage(
                      bytes: song.coverArtBytes,
                      size: 42,
                      borderRadius: DynamicsTheme.radiusSmall,
                    ),
                    const SizedBox(width: 12),

                    // Song Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DynamicsTheme.textBase,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: DynamicsTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Favorite Button
                    IconButton(
                      icon: Icon(
                        song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: song.isFavorite ? DynamicsTheme.spotifyGreen : DynamicsTheme.textMuted,
                        size: 20,
                      ),
                      splashRadius: 18,
                      onPressed: onToggleFavorite,
                    ),

                    // Circular Play/Pause Button
                    GestureDetector(
                      onTap: onPlayPause,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: DynamicsTheme.spotifyGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              // Thin Green Progress Bar at the bottom
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: DynamicsTheme.midDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(DynamicsTheme.spotifyGreen),
                  minHeight: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
