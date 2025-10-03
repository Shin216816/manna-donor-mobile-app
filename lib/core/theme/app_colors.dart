import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFE0E7FF);

  // Secondary Colors
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryContainer = Color(0xFFD1FAE5);

  // Accent Colors

  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentContainer = Color(0xFFFEF3C7);

  // Success Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);

  // Warning Colors
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);

  // Error Colors
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);

  // Info Colors
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);
  static const Color infoContainer = Color(0xFFDBEAFE);

  // Neutral Colors
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFF0F0F0);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color onSurfaceVariant = Color(0xFF6B7280);
  static const Color onBackground = Color(0xFF1F2937);
  static const Color onPrimaryContainer = Color(0xFF1F2937);

  // Special Colors
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF2A2A2A);
  static const Color darkSurfaceContainer = Color(0xFF3A3A3A);

  static const Color darkOnPrimary = Color(0xFF000000);
  static const Color darkOnSecondary = Color(0xFF000000);
  static const Color darkOnSurface = Color(0xFFE5E7EB);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
  static const Color darkOnBackground = Color(0xFFE5E7EB);

  static const Color darkDivider = Color(0xFF374151);
  static const Color darkOutline = Color(0xFF4B5563);
  static const Color darkOutlineVariant = Color(0xFF374151);

  // Semantic Colors
  static const Color donation = Color(0xFF10B981);
  static const Color roundup = Color(0xFF6366F1);
  static const Color church = Color(0xFF8B5CF6);
  static const Color bank = Color(0xFF3B82F6);
  static const Color profile = Color(0xFFF59E0B);

  // Status Colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color processing = Color(0xFF3B82F6);
  static const Color completed = Color(0xFF10B981);
  static const Color failed = Color(0xFFEF4444);
  static const Color cancelled = Color(0xFF6B7280);

  // Legacy Colors (for existing screens)
  static const Color darkPrimary = Color(0xFF4F46E5);
  static const Color darkPrimaryDark = Color(0xFF3730A3);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextPrimary = Color(0xFFE5E7EB);
  static const Color darkInputFill = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF4B5563);
  static const Color darkRoundupBackground = Color(0xFF1A1A1A);
  static const Color darkRoundupCard = Color(0xFF2A2A2A);
  static const Color darkRoundupPrimary = Color(0xFF6366F1);

  // Legacy Light Colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color inputFill = Color(0xFFF9FAFB);
  static const Color border = Color(0xFFD1D5DB);
  static const Color roundupBackground = Color(0xFFF8FAFC);
  static const Color roundupCard = Color(0xFFFFFFFF);
  static const Color roundupPrimary = Color(0xFF6366F1);
  static const Color roundupSecondary = Color(0xFF10B981);
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color gradientStart = Color(0xFF6366F1);
  static const Color gradientEnd = Color(0xFF8B5CF6);

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: secondary,
    tertiary: accent,
    onTertiary: onPrimary,
    tertiaryContainer: accentContainer,
    onTertiaryContainer: accent,
    error: error,
    onError: onPrimary,
    errorContainer: errorContainer,
    onErrorContainer: error,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerHighest: surfaceVariant,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: shadow,
    scrim: overlay,
    inverseSurface: neutral800,
    onInverseSurface: neutral50,
    inversePrimary: primaryLight,
    surfaceTint: primary,
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: primary,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: secondary,
    tertiary: accent,
    onTertiary: onPrimary,
    tertiaryContainer: accentContainer,
    onTertiaryContainer: accent,
    error: error,
    onError: onPrimary,
    errorContainer: errorContainer,
    onErrorContainer: error,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceVariant,
    onSurfaceVariant: darkOnSurfaceVariant,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    shadow: shadow,
    scrim: overlay,
    inverseSurface: neutral50,
    onInverseSurface: neutral900,
    inversePrimary: primaryDark,
    surfaceTint: primary,
  );

  // Get color based on theme
  static Color getBackgroundColor(bool isDark) {
    return isDark ? darkBackground : background;
  }

  static Color getSurfaceColor(bool isDark) {
    return isDark ? darkSurface : surface;
  }

  static Color getOnSurfaceColor(bool isDark) {
    return isDark ? darkOnSurface : onSurface;
  }

  static Color getDividerColor(bool isDark) {
    return isDark ? darkDivider : divider;
  }

  static Color getOutlineColor(bool isDark) {
    return isDark ? darkOutline : outline;
  }
}
