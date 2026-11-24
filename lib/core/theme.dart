import 'package:flutter/material.dart';

/// Spotify Design System constants and tokens defined in .agents/DESIGN.md
class DynamicsTheme {
  // --- COLOR PALETTE ---
  // Primary Brand & Backgrounds
  static const Color spotifyGreen = Color(0xFF1ED760);
  static const Color spotifyGreenBorder = Color(0xFF1DB954);
  static const Color nearBlack = Color(0xFF121212); // Deepest background
  static const Color darkSurface = Color(0xFF181818); // Cards, containers
  static const Color midDark = Color(0xFF1F1F1F); // Interactive surfaces, inputs, buttons

  // Elevated Surfaces & Borders
  static const Color darkCard = Color(0xFF252525);
  static const Color midCard = Color(0xFF272727);
  static const Color borderGray = Color(0xFF4D4D4D);
  static const Color lightBorder = Color(0xFF7C7C7C);
  static const Color separator = Color(0xFFB3B3B3);

  // Typography Colors
  static const Color textBase = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFB3B3B3);
  static const Color textSecondary = Color(0xFFCBCBCB);
  static const Color textLight = Color(0xFFFDFDFD);

  // Semantic Colors
  static const Color negativeRed = Color(0xFFF3727F);
  static const Color warningOrange = Color(0xFFFFA42B);
  static const Color announcementBlue = Color(0xFF539DF5);

  // --- SHADOWS ---
  static const List<BoxShadow> heavyShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.5),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  static const List<BoxShadow> mediumShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      offset: Offset(0, 8),
      blurRadius: 8,
    ),
  ];

  // --- BORDER RADIUS SCALE ---
  static const BorderRadius radiusBadge = BorderRadius.all(Radius.circular(2));
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusCard = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusPanel = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(500));
  static const BorderRadius radiusFullPill = BorderRadius.all(Radius.circular(9999));

  // --- THEMEDATA ---
  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: nearBlack,
      primaryColor: spotifyGreen,
      colorScheme: const ColorScheme.dark(
        primary: spotifyGreen,
        surface: darkSurface,
        onSurface: textBase,
      ),
      fontFamily: 'Roboto', // Fallback standard font
      appBarTheme: const AppBarTheme(
        backgroundColor: nearBlack,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textBase,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: textBase,
        unselectedItemColor: textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: const CardThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: radiusCard,
        ),
        elevation: 0,
      ),
    );
  }

  // --- TEXT STYLES ---
  static const TextStyle sectionTitle = TextStyle(
    color: textBase,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle heading = TextStyle(
    color: textBase,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyBold = TextStyle(
    color: textBase,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle body = TextStyle(
    color: textBase,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle caption = TextStyle(
    color: textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle captionBold = TextStyle(
    color: textBase,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle buttonUppercase = TextStyle(
    color: textBase,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
  );

  static const TextStyle small = TextStyle(
    color: textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
}
