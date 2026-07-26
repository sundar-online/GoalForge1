import 'package:flutter/material.dart';

/// Semantic color tokens that adapt to the current theme (dark/light).
/// Use [AppThemeTokens.of(context)] to get the appropriate token set.
class AppThemeTokens {
  // --- Content / Text ---
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color contentDisabled;

  // --- Surface / Card ---
  final Color surfaceCard;
  final Color surfaceElevated;
  final Color surfaceInput;
  final Color surfaceChip;
  final Color surfaceChipSelected;
  final Color surfaceDarkBanner;
  final Color surfaceHeader;
  final Color surfaceModal;

  // --- Border ---
  final Color borderDefault;
  final Color borderSubtle;
  final Color borderStrong;

  // --- Icon ---
  final Color iconDefault;
  final Color iconSubtle;

  // --- Status ---
  final Color successText;
  final Color successBg;
  final Color successBorder;
  final Color warningText;
  final Color warningBg;

  // --- Interactive ---
  final Color buttonCircleBg;
  final Color buttonCircleIcon;
  final Color filterChipBg;
  final Color filterChipBorder;
  final Color filterChipText;
  final Color activeNavBg;
  final Color progressTrack;

  const AppThemeTokens({
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.contentDisabled,
    required this.surfaceCard,
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.surfaceChip,
    required this.surfaceChipSelected,
    required this.surfaceDarkBanner,
    required this.surfaceHeader,
    required this.surfaceModal,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderStrong,
    required this.iconDefault,
    required this.iconSubtle,
    required this.successText,
    required this.successBg,
    required this.successBorder,
    required this.warningText,
    required this.warningBg,
    required this.buttonCircleBg,
    required this.buttonCircleIcon,
    required this.filterChipBg,
    required this.filterChipBorder,
    required this.filterChipText,
    required this.activeNavBg,
    required this.progressTrack,
  });

  /// Light Mode tokens
  static const light = AppThemeTokens(
    contentPrimary: Color(0xFF0F172A),
    contentSecondary: Color(0xFF1E2235),
    contentTertiary: Color(0xFF64748B),
    contentDisabled: Color(0xFF94A3B8),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF8FAFC),
    surfaceInput: Color(0xFFF0F3F8),
    surfaceChip: Color(0xFFF0F3F8),
    surfaceChipSelected: Color(0xFFEEF2FF),
    surfaceDarkBanner: Color(0xFF1E2235),
    surfaceHeader: Color(0xFFFFFFFF),
    surfaceModal: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFE5E9F2),
    borderSubtle: Color(0xFFF1F5F9),
    borderStrong: Color(0xFFCBD5E1),
    iconDefault: Color(0xFF1E2235),
    iconSubtle: Color(0xFF8C97AB),
    successText: Color(0xFF00694E),
    successBg: Color(0xFFE6FBF5),
    successBorder: Color(0xFF00D9A5),
    warningText: Color(0xFFB25E09),
    warningBg: Color(0xFFFFF4E5),
    buttonCircleBg: Color(0xFFFFFFFF),
    buttonCircleIcon: Color(0xFF0F172A),
    filterChipBg: Color(0xFFFFFFFF),
    filterChipBorder: Color(0xFFE5E9F2),
    filterChipText: Color(0xFF1E2235),
    activeNavBg: Color(0xFF1C2033),
    progressTrack: Color(0xFFE2E8F0),
  );

  /// Dark Mode tokens
  static const dark = AppThemeTokens(
    contentPrimary: Color(0xFFE2E8F0),
    contentSecondary: Color(0xFFF1F5F9),
    contentTertiary: Color(0xFF94A3B8),
    contentDisabled: Color(0xFF64748B),
    surfaceCard: Color(0xFF161726),
    surfaceElevated: Color(0xFF1A1C2E),
    surfaceInput: Color(0xFF1E2038),
    surfaceChip: Color(0xFF1F2038),
    surfaceChipSelected: Color(0xFF272945),
    surfaceDarkBanner: Color(0xFF1B1E2E),
    surfaceHeader: Color(0xFF14151F),
    surfaceModal: Color(0xFF1E2038),
    borderDefault: Color(0x1AFFFFFF),
    borderSubtle: Color(0x0DFFFFFF),
    borderStrong: Color(0x33FFFFFF),
    iconDefault: Color(0xFFE2E8F0),
    iconSubtle: Color(0xFF64748B),
    successText: Color(0xFF4ADE80),
    successBg: Color(0xFF0F2E22),
    successBorder: Color(0xFF00D9A5),
    warningText: Color(0xFFFF9500),
    warningBg: Color(0xFF2A1A00),
    buttonCircleBg: Color(0xFF1F2038),
    buttonCircleIcon: Color(0xFFE2E8F0),
    filterChipBg: Color(0xFF1F2038),
    filterChipBorder: Color(0x1AFFFFFF),
    filterChipText: Color(0xFFE2E8F0),
    activeNavBg: Color(0xFF2C2F45),
    progressTrack: Color(0xFF2C2F45),
  );

  /// Get tokens for the current theme context.
  static AppThemeTokens of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
