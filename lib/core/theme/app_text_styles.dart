import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Font families
  static const String primaryFont = 'Poppins';
  static const String secondaryFont = 'Inter';

  // Font weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Display styles
  static TextStyle displayLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 48.sp,
      fontWeight: weight ?? bold,
      letterSpacing: -0.25,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle displayMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 36.sp,
      fontWeight: weight ?? bold,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle displaySmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 28.sp,
      fontWeight: weight ?? bold,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Headline styles
  static TextStyle headlineLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 24.sp,
      fontWeight: weight ?? semiBold,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle headlineMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 20.sp,
      fontWeight: weight ?? semiBold,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle headlineSmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 18.sp,
      fontWeight: weight ?? semiBold,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Title styles
  static TextStyle titleLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 16.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle titleMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 14.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.15,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle titleSmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: primaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Body styles
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.5,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle bodyMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.25,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle bodySmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Label styles
  static TextStyle labelLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle labelMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.5,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle labelSmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 9.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.5,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Button styles
  static TextStyle buttonLarge({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 16.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle buttonMedium({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle buttonSmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Special styles
  static TextStyle caption({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color:
          color ?? AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
    );
  }

  static TextStyle overline({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 8.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 1.5,
      color:
          color ?? AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
    );
  }

  // Input styles
  static TextStyle inputText({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.5,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  static TextStyle inputLabel({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.1,
      color:
          color ?? AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
    );
  }

  static TextStyle inputHint({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 14.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.5,
      color:
          color ?? AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.5),
    );
  }

  // Link styles
  static TextStyle link({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 12.sp,
      fontWeight: weight ?? medium,
      letterSpacing: 0.25,
      color: color ?? AppColors.primary,
      decoration: TextDecoration.underline,
    );
  }

  // Error styles
  static TextStyle error({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color: color ?? AppColors.error,
    );
  }

  // Success styles
  static TextStyle success({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color: color ?? AppColors.success,
    );
  }

  // Warning styles
  static TextStyle warning({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color: color ?? AppColors.warning,
    );
  }

  // Info styles
  static TextStyle info({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: secondaryFont,
      fontSize: 10.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.4,
      color: color ?? AppColors.info,
    );
  }

  // Monospace styles
  static TextStyle monospace({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return TextStyle(
      fontFamily: 'Courier',
      fontSize: 12.sp,
      fontWeight: weight ?? regular,
      letterSpacing: 0.25,
      color: color ?? AppColors.getOnSurfaceColor(isDark),
    );
  }

  // Get text style based on theme
  static TextStyle getTextStyle({
    required TextStyle Function({Color? color, FontWeight? weight, bool isDark})
    style,
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return style(color: color, weight: weight, isDark: isDark);
  }

  // Legacy methods for existing screens
  static TextStyle getTitle({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return titleLarge(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getBody({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return bodyMedium(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getBodySmall({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return bodySmall(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getCaption({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return labelSmall(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getHeader({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return headlineLarge(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getSubtitle({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return titleMedium(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getButton({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return labelLarge(color: color, weight: weight, isDark: isDark);
  }

  static TextStyle getRoundupTitle({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return titleLarge(
      color: color ?? AppColors.roundupPrimary,
      weight: weight,
      isDark: isDark,
    );
  }

  static TextStyle getRoundupSubtitle({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return titleMedium(
      color: color ?? AppColors.roundupPrimary,
      weight: weight,
      isDark: isDark,
    );
  }

  static TextStyle getRoundupAmount({
    Color? color,
    FontWeight? weight,
    bool isDark = false,
  }) {
    return headlineLarge(
      color: color ?? AppColors.roundupPrimary,
      weight: weight,
      isDark: isDark,
    );
  }

  // Legacy getters for backward compatibility
  static TextStyle get title => titleLarge();
  static TextStyle get body => bodyMedium();
  static TextStyle get subtitle => titleMedium();
  static TextStyle get button => labelLarge();
  static TextStyle get header => headlineLarge();
}
