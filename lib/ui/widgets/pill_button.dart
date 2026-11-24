import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum PillButtonVariant {
  primary, // Spotify Green background, black text
  dark, // Dark Surface (#1F1F1F) background, white text
  outlined, // Transparent background, gray border, white text
}

/// Standardized Spotify 500px/9999px pill button with uppercase letter-spacing
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final PillButtonVariant variant;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.variant = PillButtonVariant.dark,
    this.fontSize = 13.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (variant) {
      case PillButtonVariant.primary:
        backgroundColor = DynamicsTheme.spotifyGreen;
        textColor = Colors.black;
        break;
      case PillButtonVariant.dark:
        backgroundColor = DynamicsTheme.midDark;
        textColor = DynamicsTheme.textBase;
        break;
      case PillButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        textColor = DynamicsTheme.textBase;
        border = Border.all(color: DynamicsTheme.lightBorder, width: 1.0);
        break;
    }

    return Material(
      color: backgroundColor,
      borderRadius: DynamicsTheme.radiusFullPill,
      child: InkWell(
        onTap: onTap,
        borderRadius: DynamicsTheme.radiusFullPill,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: DynamicsTheme.radiusFullPill,
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
