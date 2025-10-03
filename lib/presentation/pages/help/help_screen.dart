import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/contact_support_modal.dart';

import 'package:manna_donate_app/core/utils.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<HelpItem> _helpItems = [
    HelpItem(
      title: 'How do roundups work?',
      content:
          'Roundups automatically collect small amounts from your linked bank account based on your spending. These are transferred monthly to your selected churches.',
      icon: Icons.volunteer_activism_rounded,
    ),
    HelpItem(
      title: 'How do I link a bank account?',
      content:
          'Go to Bank Accounts and tap Add Bank. Follow the secure linking process to connect your bank account.',
      icon: Icons.account_balance_rounded,
    ),
    HelpItem(
      title: 'How do I change my church?',
      content:
          'Search for a church and select it from the list. You can change your church at any time from the church selection screen.',
      icon: Icons.church_rounded,
    ),
    HelpItem(
      title: 'How do I reset my password?',
      content:
          'Go to Login, tap Forgot Password, and follow the instructions sent to your email.',
      icon: Icons.lock_reset_rounded,
    ),
    HelpItem(
      title: 'How do I delete my account?',
      content:
          'Go to Settings, tap Delete Account, and confirm your decision. This action cannot be undone.',
      icon: Icons.delete_forever_rounded,
    ),
    HelpItem(
      title: 'How do I export my data?',
      content:
          'Go to Settings, tap Export My Data to download a copy of your donation history and preferences.',
      icon: Icons.download_rounded,
    ),
  ];

  final List<SupportOption> _supportOptions = [
    SupportOption(
      title: 'Email Support',
      subtitle: 'Get help via email',
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
  ];

  final List<LegalItem> _legalItems = [
    LegalItem(
      title: 'Privacy Policy',
      subtitle: 'How we protect your data',
      icon: Icons.privacy_tip_rounded,
      url: 'https://manna.com/privacy',
    ),
    LegalItem(
      title: 'Terms of Service',
      subtitle: 'Our terms and conditions',
      icon: Icons.description_rounded,
      url: 'https://manna.com/terms',
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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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

  void _showContactSupportModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ContactSupportModal(),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Help & Support', showThemeToggle: true),
      drawer: AppDrawer(),
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Support Options
              _buildSupportOptions(isDark),
              SizedBox(height: 32.sp),

              // FAQ Section
              _buildFAQSection(isDark),
              SizedBox(height: 32.sp),

              // Legal Section
              _buildLegalSection(isDark),
            ],
          ),
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
                onPressed: _showContactSupportModal,
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Contact Support'),
                backgroundColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.primary,
                foregroundColor: Colors.white,
              )
              .animate()
              .fadeIn(delay: 800.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
    );
  }

  Widget _buildSupportOptions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get Support',
          style: AppTextStyles.headlineMedium(
            color: AppColors.getOnSurfaceColor(isDark),
            isDark: isDark,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        SizedBox(height: 16.sp),
        ...List.generate(_supportOptions.length, (index) {
          final option = _supportOptions[index];
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
                              color: AppColors.getOutlineColor(
                                isDark,
                              ).withValues(alpha: 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16.sp),
                            leading: Container(
                              padding: EdgeInsets.all(12.sp),
                              decoration: BoxDecoration(
                                color: option.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.sp),
                              ),
                              child: Icon(
                                option.icon,
                                color: option.color,
                                size: 24.sp,
                              ),
                            ),
                            title: Text(
                              option.title,
                              style: AppTextStyles.titleMedium(
                                color: AppColors.getOnSurfaceColor(isDark),
                                isDark: isDark,
                              ),
                            ),
                            subtitle: Text(
                              option.subtitle,
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.getOnSurfaceColor(
                                  isDark,
                                ).withValues(alpha: 0.7),
                                isDark: isDark,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: AppColors.getOnSurfaceColor(
                                isDark,
                              ).withValues(alpha: 0.5),
                              size: 16.sp,
                            ),
                            onTap: () {
                              if (option.title == 'Live Chat') {
                                _showContactSupportModal();
                              } else {
                                option.action();
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
              .animate()
              .fadeIn(delay: (300 + index * 100).ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildFAQSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequently Asked Questions',
          style: AppTextStyles.headlineMedium(
            color: AppColors.getOnSurfaceColor(isDark),
            isDark: isDark,
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        SizedBox(height: 16.sp),
        ...List.generate(_helpItems.length, (index) {
          final item = _helpItems[index];
          return Container(
                margin: EdgeInsets.only(bottom: 12.sp),
                child: AnimatedBuilder(
                  animation: _scaleController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(isDark),
                          borderRadius: BorderRadius.circular(16.sp),
                          border: Border.all(
                            color: AppColors.getOutlineColor(
                              isDark,
                            ).withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: EdgeInsets.all(8.sp),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: AppTextStyles.titleMedium(
                              color: AppColors.getOnSurfaceColor(isDark),
                              isDark: isDark,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16.sp),
                              child: Text(
                                item.content,
                                style: AppTextStyles.bodyMedium(
                                  color: AppColors.getOnSurfaceColor(
                                    isDark,
                                  ).withValues(alpha: 0.8),
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
              .animate()
              .fadeIn(delay: (500 + index * 100).ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0);
        }),
      ],
    );
  }

  Widget _buildLegalSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Legal Information',
          style: AppTextStyles.headlineMedium(
            color: AppColors.getOnSurfaceColor(isDark),
            isDark: isDark,
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        SizedBox(height: 16.sp),
        ...List.generate(_legalItems.length, (index) {
          final item = _legalItems[index];
          return Container(
                margin: EdgeInsets.only(bottom: 12.sp),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceColor(isDark),
                          borderRadius: BorderRadius.circular(16.sp),
                          border: Border.all(
                            color: AppColors.getOutlineColor(
                              isDark,
                            ).withValues(alpha: 0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.sp),
                          leading: Container(
                            padding: EdgeInsets.all(8.sp),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.secondary,
                              size: 20.sp,
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: AppTextStyles.titleMedium(
                              color: AppColors.getOnSurfaceColor(isDark),
                              isDark: isDark,
                            ),
                          ),
                          subtitle: Text(
                            item.subtitle,
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.getOnSurfaceColor(
                                isDark,
                              ).withValues(alpha: 0.7),
                              isDark: isDark,
                            ),
                          ),
                          trailing: Icon(
                            Icons.open_in_new_rounded,
                            color: AppColors.getOnSurfaceColor(
                              isDark,
                            ).withValues(alpha: 0.5),
                            size: 16.sp,
                          ),
                          onTap: () async {
                            final uri = Uri.parse(item.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              AppUtils.showSnackBar(
                                context,
                                'Could not open link',
                                backgroundColor: Colors.red,
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              )
              .animate()
              .fadeIn(delay: (700 + index * 100).ms, duration: 600.ms)
              .slideX(begin: 0.2, end: 0);
        }),
      ],
    );
  }
}

class HelpItem {
  final String title;
  final String content;
  final IconData icon;

  HelpItem({required this.title, required this.content, required this.icon});
}

class SupportOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback action;

  SupportOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.action,
  });
}

class LegalItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;

  LegalItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
  });
}
