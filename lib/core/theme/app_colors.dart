import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Theme Colors (Web Design System Alignment)
  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryContainer = Color(0xFF4F46E5); // Indigo 600
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFF818CF8); // Indigo 400
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFF1F2038);
  static const Color onSecondaryContainer = Color(0xFFC7D2FE);

  static const Color tertiary = Color(0xFF22C55E); // Emerald 500 Success
  static const Color tertiaryContainer = Color(0xFF15803D);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryFixedDim = Color(0xFF4ADE80);

  static const Color background = Color(0xFF0B0B14); // Space Dark Background
  static const Color onBackground = Color(0xFFFFFFFF);

  static const Color surface = Color(0xFF161726); // Card Surface
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFF121321); // Input Fill
  static const Color onSurfaceVariant = Color(0xFF94A3B8); // Muted Text

  static const Color surfaceContainerLow = Color(0xFF161726);
  static const Color surfaceContainer = Color(0xFF1A1C2E);
  static const Color surfaceContainerHigh = Color(0xFF1F2038);
  static const Color surfaceContainerHighest = Color(0xFF272945);

  static const Color outline = Color(0x14FFFFFF); // 8% White Glass Border
  static const Color outlineVariant = Color(0x26FFFFFF); // 15% White Glass Border

  static const Color error = Color(0xFFEF4444); // Red 500 Danger
  static const Color errorContainer = Color(0xFF991B1B);
  static const Color onError = Color(0xFFFFFFFF);

  // Special/Rank Layer Colors
  static const Color inverseSurface = Color(0xFF1F2038); // Dark Floating Card
  static const Color primaryFixedDim = Color(0xFFA5B4FC);
  static const Color secondaryFixedDim = Color(0xFFC7D2FE);

  // Performance Alert Specifics
  static const Color alertWarningText = Color(0xFFB25E09);
  static const Color alertWarningBg = Color(0xFFFFF4E5);
  static const Color alertWarningBorder = Color(0xFFFFE7CC);

  static const Color alertErrorText = Color(0xFFBA1A1A);
  static const Color alertErrorBg = Color(0xFFFFEBEB);
  static const Color alertErrorBorder = Color(0xFFFFD6D6);

  static const Color alertSuccessText = Color(0xFF00694E);
  static const Color alertSuccessBg = Color(0xFFE6F9F3);
  static const Color alertSuccessBorder = Color(0xFFD1F2E8);

  static const Color alertInfoText = Color(0xFF0D52D0);
  static const Color alertInfoBg = Color(0xFFDBE1FF);
  static const Color alertInfoBorder = Color(0xFFC3C6D7);
}
