import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static String? get displayFontFamily {
    try {
      return GoogleFonts.sora().fontFamily;
    } catch (_) {
      return null;
    }
  }

  /// Primary Display Font: Sora (Fallback: Plus Jakarta Sans / system)
  static TextStyle displayFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  /// Secondary Body Font: Inter
  static TextStyle bodyFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    try {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  /// Builds a complete TextTheme based on the ColorScheme
  static TextTheme createTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display XL (40px)
      displayLarge: displayFont(
        fontSize: 40.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        height: 1.15,
        color: colorScheme.onSurface,
      ),
      // Display L (34px)
      displayMedium: displayFont(
        fontSize: 34.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      // Display M (30px)
      displaySmall: displayFont(
        fontSize: 30.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      // H1 (28px)
      headlineLarge: displayFont(
        fontSize: 28.0,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.25,
        color: colorScheme.onSurface,
      ),
      // H2 (24px)
      headlineMedium: displayFont(
        fontSize: 24.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: colorScheme.onSurface,
      ),
      // H3 (20px)
      headlineSmall: displayFont(
        fontSize: 20.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      // Card Title (18px)
      titleLarge: displayFont(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      // Section Title (16px)
      titleMedium: displayFont(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      // Subtitle (14px)
      titleSmall: displayFont(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      // Body Large (16px)
      bodyLarge: bodyFont(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      // Body Medium (14px)
      bodyMedium: bodyFont(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: colorScheme.onSurfaceVariant,
      ),
      // Caption (12px)
      bodySmall: bodyFont(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: colorScheme.onSurfaceVariant,
      ),
      // Button Label (14px)
      labelLarge: displayFont(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      // Badge / Chip Label (12px)
      labelMedium: bodyFont(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.2,
        color: colorScheme.onSurface,
      ),
      // Micro Text (11px)
      labelSmall: bodyFont(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        height: 1.2,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
