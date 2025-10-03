import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';

class SocialLoginButton extends StatefulWidget {
  final String iconPath;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool disabled;
  final double size;
  final bool isDark;

  const SocialLoginButton({
    super.key,
    required this.iconPath,
    this.onPressed,
    this.isLoading = false,
    this.disabled = false,
    this.size = 40,
    this.isDark = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
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
              width: widget.size.sp,
              height: widget.size.sp,
              decoration: BoxDecoration(
                color: (widget.disabled || widget.isLoading)
                    ? (widget.isDark ? AppColors.darkSurfaceContainer : AppColors.neutral300)
                    : (widget.isDark ? const Color(0xFF2A2A2A) : Colors.white),
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: (widget.disabled || widget.isLoading)
                      ? (widget.isDark ? AppColors.darkBorder : AppColors.neutral400)
                      : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : AppColors.neutral300),
                  width: 1,
                ),
                boxShadow: (widget.disabled || widget.isLoading)
                    ? null
                    : [
                        BoxShadow(
                          color: widget.isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.sp),
                  onTap: (widget.disabled || widget.isLoading)
                      ? null
                      : _handleTap,
                  child: Container(
                    padding: EdgeInsets.all(16.sp),
                    child: widget.isLoading
                        ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: EnhancedLoadingWidget(
                              type: LoadingType.spinner,
                              size: 20.sp,
                              showMessage: false,
                              color: widget.isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          )
                        : Opacity(
                            opacity: (widget.disabled || widget.isLoading) ? 0.5 : 1.0,
                            child: Image.asset(
                              widget.iconPath,
                              width: 24.sp,
                              height: 24.sp,
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }
}
