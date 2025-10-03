import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

enum SocialAuthVariant {
  google,
  apple,
  facebook,
  twitter,
  github,
  microsoft,
  custom,
}

class SocialAuthButton extends StatefulWidget {
  final String text;
  final String? icon;
  final IconData? iconData;
  final SocialAuthVariant variant;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool isDark;
  final bool fullWidth;
  final String? loadingText;
  final bool enableHapticFeedback;
  final Duration? animationDuration;

  const SocialAuthButton({
    super.key,
    required this.text,
    this.icon,
    this.iconData,
    this.variant = SocialAuthVariant.custom,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isDark = false,
    this.fullWidth = false,
    this.loadingText,
    this.enableHapticFeedback = true,
    this.animationDuration,
  });

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration ?? const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Theme.of(context);
    final isDark = themeProvider.brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: (widget.disabled || widget.isLoading) ? null : _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: _getWidth(),
              height: _getHeight(),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(_getBorderRadius()),
                border: _getBorder(isDark),
                boxShadow: _getBoxShadow(isDark),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(_getBorderRadius()),
                  onTap: (widget.disabled || widget.isLoading) ? null : _handleTap,
                  child: Container(
                    padding: _getPadding(),
                    child: _buildContent(isDark),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildContent(bool isDark) {
    if (widget.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16.sp,
            height: 16.sp,
            child: EnhancedLoadingWidget(
              type: LoadingType.spinner,
              size: 16.sp,
              showMessage: false,
              color: _getForegroundColor(isDark),
            ),
          ),
          if (widget.loadingText != null) ...[
            SizedBox(width: 8.sp),
            Text(
              widget.loadingText!,
              style: _getTextStyle(isDark),
            ),
          ],
        ],
      );
    }

    // Show only icon for Google and Apple, text for others
    if (widget.variant == SocialAuthVariant.google || widget.variant == SocialAuthVariant.apple) {
      return _buildIcon(isDark);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildIcon(isDark),
        SizedBox(width: 12.sp),
        Text(
          widget.text,
          style: _getTextStyle(isDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIcon(bool isDark) {
    if (widget.icon != null) {
      // Check if it's a PNG file (Google/Apple logos)
      if (widget.icon!.endsWith('.png')) {
        return Image.asset(
          widget.icon!,
          width: 28.sp, // Slightly larger for better visibility
          height: 28.sp, // Slightly larger for better visibility
          fit: BoxFit.contain,
        );
      }
      // For SVG files
      return SvgPicture.asset(
        widget.icon!,
        width: 28.sp, // Consistent size with PNG icons
        height: 28.sp, // Consistent size with PNG icons
      );
    }

    if (widget.iconData != null) {
      return Icon(
        widget.iconData,
        size: 24.sp, // Larger size for better visibility
        color: _getForegroundColor(isDark),
      );
    }

    // Default icons based on variant
    switch (widget.variant) {
      case SocialAuthVariant.google:
        return SvgPicture.asset(
          'assets/icons/google.svg',
          width: 28.sp, // Consistent size
          height: 28.sp,
        );
      case SocialAuthVariant.apple:
        return SvgPicture.asset(
          'assets/icons/apple.svg',
          width: 28.sp, // Consistent size
          height: 28.sp,
        );
      case SocialAuthVariant.facebook:
        return SvgPicture.asset(
          'assets/icons/facebook.svg',
          width: 20.sp,
          height: 20.sp,
        );
      case SocialAuthVariant.twitter:
        return SvgPicture.asset(
          'assets/icons/twitter.svg',
          width: 20.sp,
          height: 20.sp,
        );
      case SocialAuthVariant.github:
        return SvgPicture.asset(
          'assets/icons/github.svg',
          width: 20.sp,
          height: 20.sp,
        );
      case SocialAuthVariant.microsoft:
        return SvgPicture.asset(
          'assets/icons/microsoft.svg',
          width: 20.sp,
          height: 20.sp,
        );
      case SocialAuthVariant.custom:
        return const SizedBox.shrink();
    }
  }

  double _getWidth() {
    if (widget.width != null) return widget.width!;
    if (widget.fullWidth) return double.infinity;
    return 120.sp;
  }

  double _getHeight() {
    if (widget.height != null) return widget.height!;
    return 52.sp; // Slightly taller for better touch targets
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.padding != null) return widget.padding!;
    return EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp);
  }

  double _getBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;
    return 12.sp;
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return isDark ? AppColors.darkSurface : AppColors.neutral300;
    }
    
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    switch (widget.variant) {
      case SocialAuthVariant.google:
        return isDark ? const Color(0xFF2A2A2A) : Colors.white; // Dark in dark mode, white in light mode
      case SocialAuthVariant.apple:
        return Colors.black; // Apple always has black background
      case SocialAuthVariant.facebook:
        return const Color(0xFF1877F2);
      case SocialAuthVariant.twitter:
        return const Color(0xFF1DA1F2);
      case SocialAuthVariant.github:
        return isDark ? Colors.white : Colors.black;
      case SocialAuthVariant.microsoft:
        return const Color(0xFF00A4EF);
      case SocialAuthVariant.custom:
        return AppColors.getSurfaceColor(isDark);
    }
  }

  Color _getForegroundColor(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return isDark ? AppColors.darkOnSurface : AppColors.neutral500;
    }
    
    if (widget.foregroundColor != null) {
      return widget.foregroundColor!;
    }

    switch (widget.variant) {
      case SocialAuthVariant.google:
        return isDark ? Colors.white : Colors.black87; // White text in dark mode, dark in light mode
      case SocialAuthVariant.apple:
        return Colors.white; // Apple always has white text/icon
      case SocialAuthVariant.facebook:
        return Colors.white;
      case SocialAuthVariant.twitter:
        return Colors.white;
      case SocialAuthVariant.github:
        return isDark ? Colors.black : Colors.white;
      case SocialAuthVariant.microsoft:
        return Colors.white;
      case SocialAuthVariant.custom:
        return AppColors.getOnSurfaceColor(isDark);
    }
  }

  Border? _getBorder(bool isDark) {
    if (widget.borderColor != null) {
      return Border.all(
        color: widget.borderColor!,
        width: 1,
      );
    }

    switch (widget.variant) {
      case SocialAuthVariant.google:
        return Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.neutral300, // White border in dark mode, gray in light mode
          width: 1,
        );
      case SocialAuthVariant.apple:
        return null; // Apple button has no border
      case SocialAuthVariant.facebook:
      case SocialAuthVariant.twitter:
      case SocialAuthVariant.github:
      case SocialAuthVariant.microsoft:
        return null;
      case SocialAuthVariant.custom:
        return Border.all(
          color: AppColors.getOutlineColor(isDark),
          width: 1,
        );
    }
  }

  List<BoxShadow>? _getBoxShadow(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return null;
    }

    switch (widget.variant) {
      case SocialAuthVariant.google:
        return [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1), // Stronger shadow in dark mode
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.apple:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // Apple has subtle shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.facebook:
        return [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.twitter:
        return [
          BoxShadow(
            color: const Color(0xFF1DA1F2).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.github:
        return [
          BoxShadow(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.microsoft:
        return [
          BoxShadow(
            color: const Color(0xFF00A4EF).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case SocialAuthVariant.custom:
        return [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
    }
  }

  TextStyle _getTextStyle(bool isDark) {
    return AppTextStyles.buttonMedium(
      color: _getForegroundColor(isDark),
      weight: AppTextStyles.medium,
    );
  }
} 