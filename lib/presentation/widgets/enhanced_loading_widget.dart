import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';

enum LoadingType {
  spinner,
  dots,
  pulse,
  wave,
  bounce,
  rotate,
  shimmer,
  heartbeat,
}

class EnhancedLoadingWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final Color? color;
  final double size;
  final bool showMessage;
  final Duration animationDuration;
  final bool isDark;

  const EnhancedLoadingWidget({
    super.key,
    this.type = LoadingType.spinner,
    this.message,
    this.color,
    this.size = 40,
    this.showMessage = true,
    this.animationDuration = const Duration(milliseconds: 1500),
    this.isDark = false,
  });

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late AnimationController _waveController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    switch (widget.type) {
      case LoadingType.spinner:
      case LoadingType.rotate:
        _controller.repeat();
        break;
      case LoadingType.pulse:
      case LoadingType.heartbeat:
        _pulseController.repeat(reverse: true);
        break;
      case LoadingType.bounce:
        _bounceController.repeat(reverse: true);
        break;
      case LoadingType.wave:
        _waveController.repeat();
        break;
      case LoadingType.dots:
      case LoadingType.shimmer:
        // These use flutter_animate
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark || Theme.of(context).brightness == Brightness.dark;
    final color = widget.color ?? (isDark ? AppColors.darkPrimary : AppColors.primary);

    // For very small containers, only show the animation without message
    if (widget.size < 20) {
      return SizedBox(
        width: widget.size.sp,
        height: widget.size.sp,
        child: _buildLoadingAnimation(color),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLoadingAnimation(color),
        if (widget.showMessage && widget.message != null) ...[
          SizedBox(height: 16.sp),
          Text(
            widget.message!,
            style: AppTextStyles.bodyMedium(
              color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
              isDark: isDark,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
        ],
      ],
    );
  }

  Widget _buildLoadingAnimation(Color color) {
    switch (widget.type) {
      case LoadingType.spinner:
        return _buildSpinner(color);
      case LoadingType.dots:
        return _buildDots(color);
      case LoadingType.pulse:
        return _buildPulse(color);
      case LoadingType.wave:
        return _buildWave(color);
      case LoadingType.bounce:
        return _buildBounce(color);
      case LoadingType.rotate:
        return _buildRotate(color);
      case LoadingType.shimmer:
        return _buildShimmer(color);
      case LoadingType.heartbeat:
        return _buildHeartbeat(color);
    }
  }

  Widget _buildSpinner(Color color) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: widget.size.sp,
            height: widget.size.sp,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.size.sp / 2),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 3.sp,
              ),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeWidth: 3.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.sp),
          child: Container(
            width: 12.sp,
            height: 12.sp,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ).animate().scale(
            delay: (index * 200).ms,
            duration: 600.ms,
            curve: Curves.easeInOut,
          ).then().scale(
            duration: 600.ms,
            curve: Curves.easeInOut,
          ),
        );
      }),
    );
  }

  Widget _buildPulse(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size.sp,
            height: widget.size.sp,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: (widget.size * 0.5).sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWave(Color color) {
    return SizedBox(
      width: widget.size.sp,
      height: widget.size.sp,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              final waveValue = (_waveAnimation.value + (index * 0.2)) % 1.0;
              final maxHeight = widget.size.sp;
              final minHeight = maxHeight * 0.15;
              final height = minHeight + (maxHeight * 0.5 * waveValue);
              
              // Ultra-compact sizing for very small containers
              final totalWidth = widget.size.sp;
              final barWidth = (totalWidth * 0.06).sp.clamp(0.5, 2.0);
              final margin = (totalWidth * 0.005).sp.clamp(0.1, 0.4);
              
              return Container(
                margin: EdgeInsets.symmetric(horizontal: margin),
                width: barWidth,
                height: height.clamp(0, maxHeight * 0.95), // Prevent vertical overflow
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(barWidth / 2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildBounce(Color color) {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * _bounceAnimation.value),
          child: Container(
            width: widget.size.sp,
            height: widget.size.sp,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_upward,
              color: Colors.white,
              size: (widget.size * 0.4).sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRotate(Color color) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: widget.size.sp,
            height: widget.size.sp,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh,
              color: Colors.white,
              size: (widget.size * 0.5).sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer(Color color) {
    return Container(
      width: widget.size.sp,
      height: widget.size.sp,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color,
            color.withValues(alpha: 0.3),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(8.sp),
      ),
    ).animate().shimmer(
      duration: 1500.ms,
      color: color.withValues(alpha: 0.8),
    );
  }

  Widget _buildHeartbeat(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size.sp,
            height: widget.size.sp,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.favorite,
              color: Colors.white,
              size: (widget.size * 0.6).sp,
            ),
          ),
        );
      },
    );
  }
}

// Convenience widget for common loading scenarios
class LoadingSpinner extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isDark;

  const LoadingSpinner({
    super.key,
    this.message,
    this.color,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      type: LoadingType.spinner,
      message: message,
      color: color,
      size: size,
      isDark: isDark,
    );
  }
}

class LoadingDots extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isDark;

  const LoadingDots({
    super.key,
    this.message,
    this.color,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      type: LoadingType.dots,
      message: message,
      color: color,
      size: size,
      isDark: isDark,
    );
  }
}

class LoadingPulse extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isDark;

  const LoadingPulse({
    super.key,
    this.message,
    this.color,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      type: LoadingType.pulse,
      message: message,
      color: color,
      size: size,
      isDark: isDark,
    );
  }
}

class LoadingWave extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isDark;

  const LoadingWave({
    super.key,
    this.message,
    this.color,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      type: LoadingType.wave,
      message: message,
      color: color,
      size: size,
      isDark: isDark,
    );
  }
}

class LoadingBounce extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool isDark;

  const LoadingBounce({
    super.key,
    this.message,
    this.color,
    this.size = 40,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedLoadingWidget(
      type: LoadingType.bounce,
      message: message,
      color: color,
      size: size,
      isDark: isDark,
    );
  }
} 