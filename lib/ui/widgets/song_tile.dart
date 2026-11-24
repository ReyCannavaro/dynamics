import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/song.dart';
import 'album_art_image.dart';

/// Spotify-styled song row with thumbnail, title, artist, active playback indicator, and options menu
class SongTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

  const SongTile({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.isPlaying = false,
    required this.onTap,
    this.onToggleFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isCurrent ? DynamicsTheme.spotifyGreen : DynamicsTheme.textBase;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DynamicsTheme.radiusCard,
        splashColor: DynamicsTheme.darkCard.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // Album Art Thumbnail
              AlbumArtImage(
                bytes: song.coverArtBytes,
                size: 48,
                borderRadius: DynamicsTheme.radiusSmall,
              ),
              const SizedBox(width: 14),

              // Title and Artist Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 15,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${song.artist} • ${song.formattedDuration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DynamicsTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Playing Indicator
              if (isCurrent) ...[
                Icon(
                  isPlaying ? Icons.volume_up_rounded : Icons.pause_rounded,
                  color: DynamicsTheme.spotifyGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],

              // Favorite Heart Button
              IconButton(
                icon: Icon(
                  song.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: song.isFavorite ? DynamicsTheme.spotifyGreen : DynamicsTheme.textMuted,
                  size: 20,
                ),
                splashRadius: 20,
                onPressed: onToggleFavorite,
              ),

              // Options Menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: DynamicsTheme.textMuted,
                  size: 20,
                ),
                color: DynamicsTheme.darkSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: DynamicsTheme.radiusCard,
                ),
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: DynamicsTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text('Plays: ${song.playCount}', style: const TextStyle(color: DynamicsTheme.textBase, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: DynamicsTheme.negativeRed, size: 18),
                        SizedBox(width: 10),
                        Text('Remove from library', style: TextStyle(color: DynamicsTheme.negativeRed, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
