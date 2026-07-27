import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Curated HSL & Rich Hex Colors matching Web App Bootstrap 5 UI
  static const Color primaryEmerald = Color(0xFF0D9488);
  static const Color accentCrimson = Color(0xFFF43F5E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoAzure = Color(0xFF3B82F6);
  static const Color slateGray = Color(0xFF64748B);
  
  // High-Contrast Midnight Obsidian & Light Backgrounds
  static const Color darkBg = Color(0xFF0B0F19);
  static const Color darkCardBg = Color(0xFF151D30);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCardBg = Color(0xFFFFFFFF);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryEmerald,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryEmerald,
      secondary: infoAzure,
      error: accentCrimson,
      surface: darkCardBg,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
    ),
    cardTheme: CardTheme(
      color: darkCardBg,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryEmerald,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: primaryEmerald,
      secondary: infoAzure,
      error: accentCrimson,
      surface: lightCardBg,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
      headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
      titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
    ),
    cardTheme: CardTheme(
      color: lightCardBg,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
    ),
  );
}
