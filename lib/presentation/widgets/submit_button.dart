import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';

class SubmitButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool isGradient;

  const SubmitButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.isGradient = false,
  }) : super(key: key);

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.enabled && !widget.loading) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = widget.enabled && !widget.loading
        ? (widget.backgroundColor ??
              (isDark ? AppColors.darkPrimary : AppColors.primary))
        : (isDark ? AppColors.darkSurfaceContainer : AppColors.neutral300);
    final txtColor = widget.enabled && !widget.loading
        ? (widget.textColor ?? Colors.white)
        : (isDark ? AppColors.darkOnSurfaceVariant : AppColors.neutral500);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: Container(
                width: widget.width ?? double.infinity,
                height: widget.height ?? 40.sp,
                decoration: BoxDecoration(
                  gradient: widget.isGradient
                      ? LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.darkPrimary,
                                  AppColors.darkPrimaryDark,
                                ]
                              : [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.isGradient ? null : bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: widget.enabled && !widget.loading
                      ? [
                          BoxShadow(
                            color: bgColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: widget.enabled && !widget.loading
                        ? widget.onPressed
                        : null,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: widget.loading
                            ? EnhancedLoadingWidget(
                                type: LoadingType.spinner,
                                size: 20,
                                showMessage: false,
                                color: txtColor,
                              )
                            : _buildContent(txtColor, isDark),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: LoadingWave(
            color: textColor,
            size: 20,
            isDark: false,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Loading...',
          style: AppTextStyles.button.copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildContent(Color textColor, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          widget.text,
          style: AppTextStyles.button.copyWith(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// Special roundup button with green gradient
class RoundupButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final double? width;
  final double? height;
  final IconData? icon;

  const RoundupButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return SubmitButton(
      text: text,
      onPressed: onPressed,
      loading: loading,
      enabled: enabled,
      width: width,
      height: height,
      icon: icon,
      isGradient: true,
      backgroundColor: isDark
          ? AppColors.darkRoundupPrimary
          : AppColors.roundupPrimary,
    );
  }
}
