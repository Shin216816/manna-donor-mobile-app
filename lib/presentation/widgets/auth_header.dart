import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final TextAlign titleAlign;
  final TextAlign subtitleAlign;
  final bool showDivider;
  final Color? dividerColor;
  final double? titleSize;
  final double? subtitleSize;
  final FontWeight? titleWeight;
  final FontWeight? subtitleWeight;
  final Color? titleColor;
  final Color? subtitleColor;
  final bool showThemeToggle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.isDark = false,
    this.padding,
    this.titleAlign = TextAlign.center,
    this.subtitleAlign = TextAlign.center,
    this.showDivider = false,
    this.dividerColor,
    this.titleSize,
    this.subtitleSize,
    this.titleWeight,
    this.subtitleWeight,
    this.titleColor,
    this.subtitleColor,
    this.showThemeToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(4, 8),
          ),
        ],
      ),
      child: Padding(
        padding:
            padding ?? EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header Row
            Row(
              children: [
                // Leading Widget
                if (leading != null) ...[leading!, SizedBox(width: 16.sp)],

                // Title
                Expanded(
                  child: Text(
                    title,
                    style: _getTitleStyle(isDark),
                    textAlign: titleAlign,
                  ),
                ),

                // Theme Toggle
                if (showThemeToggle) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        try {
                          themeProvider.toggleTheme();
                        } catch (e) {
                          // Show error message to user
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to change theme: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: Icon(
                        isDark ? Icons.light_mode : Icons.dark_mode,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      splashRadius: 20.sp,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                ],

                // Trailing Widget
                if (trailing != null) ...[SizedBox(width: 16.sp), trailing!],
              ],
            ),

            // Subtitle
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: 8.sp),
              Text(
                subtitle,
                style: _getSubtitleStyle(isDark),
                textAlign: subtitleAlign,
              ),
            ],

            // Divider
            if (showDivider) ...[
              SizedBox(height: 16.sp),
              Divider(
                color: dividerColor ?? Colors.white.withValues(alpha: 0.3),
                thickness: 1,
              ),
            ],
            SizedBox(height: 16.sp),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
  }

  TextStyle _getTitleStyle(bool isDark) {
    return AppTextStyles.getTitle(isDark: false).copyWith(
      color: titleColor ?? Colors.white,
      fontWeight: titleWeight ?? FontWeight.bold,
      fontSize: titleSize ?? 22,
    );
  }

  TextStyle _getSubtitleStyle(bool isDark) {
    return AppTextStyles.bodyLarge(
      color: subtitleColor ?? Colors.white.withValues(alpha: 0.9),
      weight: subtitleWeight ?? AppTextStyles.regular,
      isDark: isDark,
    ).copyWith(fontSize: subtitleSize);
  }
}
