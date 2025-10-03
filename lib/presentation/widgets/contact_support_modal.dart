import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';


class ContactSupportModal extends StatefulWidget {
  const ContactSupportModal({super.key});

  @override
  State<ContactSupportModal> createState() => _ContactSupportModalState();
}

class _ContactSupportModalState extends State<ContactSupportModal>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<SupportChannel> _supportChannels = [
    SupportChannel(
      title: 'Email Support',
      subtitle: 'Get help via email',
      description: 'Send us an email and we\'ll respond within 24 hours',
      icon: Icons.email_rounded,
      color: Colors.blue,
      action: () async {
        final uri = Uri(
          scheme: 'mailto',
          path: 'support@manna.com',
          query: 'subject=Support Request',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    ),
    SupportChannel(
      title: 'Phone Support',
      subtitle: 'Call us directly',
      description: 'Speak with our support team during business hours',
      icon: Icons.phone_rounded,
      color: Colors.green,
      action: () async {
        final uri = Uri(scheme: 'tel', path: '+1234567890');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    ),
    SupportChannel(
      title: 'Live Chat',
      subtitle: 'Chat with support',
      description: 'Real-time chat with our support team',
      icon: Icons.chat_rounded,
      color: Colors.orange,
      action: () {
        // Will be handled in the build method
      },
    ),
    SupportChannel(
      title: 'Help Center',
      subtitle: 'Browse articles',
      description: 'Find answers in our comprehensive help center',
      icon: Icons.help_center_rounded,
      color: Colors.purple,
      action: () {
        // Will be handled in the build method
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _showLiveChatUnavailable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Live Chat Unavailable',
          style: TextStyle(
            color: AppColors.getOnSurfaceColor(isDark),
          ),
        ),
        content: Text(
          'Live chat is not yet implemented. Please use email or phone support for immediate assistance.',
          style: TextStyle(
            color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpCenterUnavailable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Help Center Unavailable',
          style: TextStyle(
            color: AppColors.getOnSurfaceColor(isDark),
          ),
        ),
        content: Text(
          'Help center is not yet implemented. Please use email or phone support for assistance.',
          style: TextStyle(
            color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 400.sp,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: AppColors.getBackgroundColor(isDark),
                borderRadius: BorderRadius.circular(24.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  _buildHeader(isDark),
                  
                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.sp),
                      child: Column(
                        children: [
                          // Support Channels
                          _buildSupportChannels(isDark),
                          
                          SizedBox(height: 24.sp),
                          
                          // Additional Info
                          _buildAdditionalInfo(isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.sp)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.sp),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Support',
                  style: AppTextStyles.headlineMedium(
                    color: Colors.white,
                    isDark: false,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  'How can we help you?',
                  style: AppTextStyles.bodyMedium(
                    color: Colors.white.withValues(alpha: 0.9),
                    isDark: false,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildSupportChannels(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support Channels',
          style: AppTextStyles.titleLarge(
            color: AppColors.getOnSurfaceColor(isDark),
            isDark: isDark,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        SizedBox(height: 16.sp),
        ...List.generate(_supportChannels.length, (index) {
          final channel = _supportChannels[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12.sp),
            child: AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.getSurfaceColor(isDark),
                        borderRadius: BorderRadius.circular(16.sp),
                        border: Border.all(
                          color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16.sp),
                          onTap: () {
                            if (channel.title == 'Live Chat') {
                              _showLiveChatUnavailable();
                            } else if (channel.title == 'Help Center') {
                              _showHelpCenterUnavailable();
                            } else {
                              channel.action();
                            }
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16.sp),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.sp),
                                  decoration: BoxDecoration(
                                    color: channel.color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.sp),
                                  ),
                                  child: Icon(
                                    channel.icon,
                                    color: channel.color,
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: 16.sp),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        channel.title,
                                        style: AppTextStyles.titleMedium(
                                          color: AppColors.getOnSurfaceColor(isDark),
                                          isDark: isDark,
                                        ),
                                      ),
                                      SizedBox(height: 4.sp),
                                      Text(
                                        channel.subtitle,
                                        style: AppTextStyles.bodyMedium(
                                          color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                                          isDark: isDark,
                                        ),
                                      ),
                                      SizedBox(height: 8.sp),
                                      Text(
                                        channel.description,
                                        style: AppTextStyles.bodySmall(
                                          color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.6),
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.5),
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate().fadeIn(delay: (300 + index * 100).ms, duration: 600.ms).slideX(begin: -0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildAdditionalInfo(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_rounded,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text(
                    'Our support team is available Monday to Friday, 9 AM - 6 PM EST',
                    style: AppTextStyles.bodySmall(
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}

class SupportChannel {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  SupportChannel({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.action,
  });
} 