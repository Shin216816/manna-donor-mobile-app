import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'enhanced_loading_widget.dart';

enum ButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
  success,
  warning,
}

enum ButtonSize { small, medium, large }

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final ButtonVariant variant;
  final ButtonSize size;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool isDark;
  final bool fullWidth;
  final bool disabled;
  final String? loadingText;
  final Widget? child;
  final bool enableHapticFeedback;
  final Duration? animationDuration;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.small,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.isDark = false,
    this.fullWidth = false,
    this.disabled = false,
    this.loadingText,
    this.child,
    this.enableHapticFeedback = true,
    this.animationDuration,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

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
                  onTap: (widget.disabled || widget.isLoading)
                      ? null
                      : _handleTap,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16.sp,
            height: 16.sp,
            child: EnhancedLoadingWidget(
              type: LoadingType.spinner,
              color: _getForegroundColor(isDark),
              size: 16,
              showMessage: false,
            ),
          ),
          if (widget.loadingText != null) ...[
            SizedBox(width: 12.sp),
            Flexible(
              child: Text(
                widget.loadingText!,
                style: _getTextStyle(isDark),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ],
        ],
      );
    }

    if (widget.child != null) {
      return widget.child!;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: _getIconSize(),
            color: _getForegroundColor(isDark),
          ),
          SizedBox(width: 8.sp),
        ],
        Flexible(
          child: Text(
            widget.text,
            style: _getTextStyle(isDark),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  double _getWidth() {
    if (widget.width != null) return widget.width!;
    if (widget.fullWidth) return double.infinity;
    return _getSizeWidth();
  }

  double _getHeight() {
    if (widget.height != null) return widget.height!;
    return _getSizeHeight();
  }

  double _getSizeWidth() {
    switch (widget.size) {
      case ButtonSize.small:
        return 70.sp;
      case ButtonSize.medium:
        return 100.sp;
      case ButtonSize.large:
        return 140.sp;
    }
  }

  double _getSizeHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 40.sp;
      case ButtonSize.medium:
        return 40.sp;
      case ButtonSize.large:
        return 40.sp;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.padding != null) return widget.padding!;

    switch (widget.size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp);
      case ButtonSize.medium:
        return EdgeInsets.symmetric(horizontal: 20.sp, vertical: 8.sp);
      case ButtonSize.large:
        return EdgeInsets.symmetric(horizontal: 24.sp, vertical: 8.sp);
    }
  }

  double _getBorderRadius() {
    if (widget.borderRadius != null) return widget.borderRadius!;

    switch (widget.size) {
      case ButtonSize.small:
        return 12.sp;
      case ButtonSize.medium:
        return 12.sp;
      case ButtonSize.large:
        return 12.sp;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 18.sp;
      case ButtonSize.medium:
        return 20.sp;
      case ButtonSize.large:
        return 24.sp;
    }
  }

  Color _getBackgroundColor(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return isDark ? AppColors.neutral700 : AppColors.neutral200;
    }

    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.secondary:
        return AppColors.secondary;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return Colors.transparent;
      case ButtonVariant.danger:
        return AppColors.error;
      case ButtonVariant.success:
        return AppColors.success;
      case ButtonVariant.warning:
        return AppColors.warning;
    }
  }

  Color _getForegroundColor(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return isDark ? AppColors.neutral500 : AppColors.neutral400;
    }

    if (widget.foregroundColor != null) {
      return widget.foregroundColor!;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
      case ButtonVariant.danger:
      case ButtonVariant.success:
      case ButtonVariant.warning:
        return AppColors.onPrimary;
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return AppColors.primary;
    }
  }

  Border? _getBorder(bool isDark) {
    if (widget.variant == ButtonVariant.outlined) {
      return Border.all(
        color: widget.borderColor ?? AppColors.primary,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow>? _getBoxShadow(bool isDark) {
    if (widget.disabled || widget.isLoading) {
      return null;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case ButtonVariant.secondary:
        return [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case ButtonVariant.outlined:
      case ButtonVariant.text:
        return null;
      case ButtonVariant.danger:
        return [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case ButtonVariant.success:
        return [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case ButtonVariant.warning:
        return [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }

  TextStyle _getTextStyle(bool isDark) {
    switch (widget.size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall(
          color: _getForegroundColor(isDark),
          weight: AppTextStyles.medium,
        );
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium(
          color: _getForegroundColor(isDark),
          weight: AppTextStyles.medium,
        );
      case ButtonSize.large:
        return AppTextStyles.buttonMedium(
          color: _getForegroundColor(isDark),
          weight: AppTextStyles.medium,
        );
    }
  }
}
