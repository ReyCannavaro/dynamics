import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable Spotify-styled album art container supporting raw bytes with a dark placeholder fallback
class AlbumArtImage extends StatelessWidget {
  final Uint8List? bytes;
  final double size;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final BoxFit fit;

  const AlbumArtImage({
    super.key,
    required this.bytes,
    this.size = 48.0,
    this.borderRadius,
    this.boxShadow,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? DynamicsTheme.radiusCard;

    Widget imageContent;

    if (bytes != null && bytes!.isNotEmpty) {
      imageContent = Image.memory(
        bytes!,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      imageContent = _buildPlaceholder();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DynamicsTheme.darkCard,
        borderRadius: effectiveRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: imageContent,
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: DynamicsTheme.darkCard,
      alignment: Alignment.center,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.45,
        color: DynamicsTheme.textMuted,
      ),
    );
  }
}
