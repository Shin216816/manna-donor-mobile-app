import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui'; // Added for ImageFilter

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/utils.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';
import 'package:manna_donate_app/core/logout_service.dart';
import '../../core/utils/image_utils.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      backgroundColor: AppColors.getSurfaceColor(isDark),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.user;

          return Column(
            children: [
              // Simple Header - Centered Avatar and Name
              Container(
                width: double.infinity,
                height: 160.sp,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Centered Avatar
                    ImageUtils.buildProfileImage(
                      radius: 50.sp,
                      imageUrl: user?.profilePictureUrl,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      fallbackIcon: Icon(
                        Icons.person,
                        size: 50.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      showErrorHandling:
                          false, // Silent error handling in drawer
                    ),
                    SizedBox(height: 12.sp),
                    // Centered Name
                    Text(
                      user?.name ?? 'User Name',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 16.sp),
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home_rounded,
                      title: 'Home',
                      onTap: () => context.go('/home'),
                      isDark: isDark,
                      index: 0,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.account_balance_rounded,
                      title: 'Bank Accounts',
                      onTap: () => context.go('/bank-accounts'),
                      isDark: isDark,
                      index: 1,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.history_rounded,
                      title: 'Donation History',
                      onTap: () => context.go('/donation-history'),
                      isDark: isDark,
                      index: 2,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.receipt_long_rounded,
                      title: 'Transactions',
                      onTap: () => context.go('/transactions'),
                      isDark: isDark,
                      index: 3,
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.message_rounded,
                      title: 'Church Messages',
                      onTap: () => context.go('/church-messages'),
                      isDark: isDark,
                      index: 4,
                    ),
                    // Church Admin Communication (only for church admins)
                    if (user?.isChurchAdmin == true) ...[
                      _buildDrawerItem(
                        context,
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Send Message to Donors',
                        onTap: () => context.go('/church-admin-communication'),
                        isDark: isDark,
                        index: 5,
                      ),
                    ],
                    _buildDrawerItem(
                      context,
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      onTap: () => context.go('/profile'),
                      isDark: isDark,
                      index: user?.isChurchAdmin == true ? 6 : 5,
                    ),

                    Divider(
                      color: AppColors.getDividerColor(isDark),
                      height: 24.sp, // Reduced height
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => context.go('/settings'),
                      isDark: isDark,
                      index: user?.isChurchAdmin == true ? 7 : 6,
                    ),
                    Divider(
                      color: AppColors.getDividerColor(isDark),
                      height: 24.sp, // Reduced height
                    ),

                    _buildDrawerItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      onTap: () => LogoutService.executeLogout(context),
                      isDark: isDark,
                      isDestructive: true,
                      index: user?.isChurchAdmin == true ? 12 : 11,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
    int index = 0,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.sp),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.sp),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40.sp,
                  height: 40.sp,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.sp),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? AppColors.error
                        : AppColors.getOnSurfaceColor(
                            isDark,
                          ).withValues(alpha: 0.8),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 16.sp),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: isDestructive
                          ? AppColors.error
                          : AppColors.getOnSurfaceColor(isDark),
                      fontWeight: FontWeight.w500,
                      fontSize: 16.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.4),
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _referFriend(BuildContext context) async {
    try {
      final String shareText = '''
Check out Manna - the app that makes giving easy! 


With Manna, you can automatically round up your everyday purchases and donate the spare change to your favorite churches and charities.

Download now: https://manna.com/download

#Manna #RoundupDonations #GiveBack
''';

      await Share.share(
        shareText,
        subject: 'Join me on Manna - Roundup Donations',
      );

      if (context.mounted) {
        AppUtils.showSuccessSnackBar(context, 'Share dialog opened!');
      }
    } catch (e) {
      if (context.mounted) {
        AppUtils.showErrorSnackBar(context, 'Failed to open share dialog');
      }
    }
  }

  void _rateApp(BuildContext context) async {
    try {
      // For Android, open Play Store
      final Uri url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.manna.donate',
      );

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          AppUtils.showSuccessSnackBar(context, 'Opening app store...');
        }
      } else {
        if (context.mounted) {
          AppUtils.showErrorSnackBar(context, 'Could not open app store');
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppUtils.showErrorSnackBar(context, 'Failed to open app store');
      }
    }
  }

  void _contactSupport(BuildContext context) async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@manna.com',
        query: 'subject=Support Request from Manna App',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        if (context.mounted) {
          AppUtils.showSuccessSnackBar(context, 'Opening email app...');
        }
      } else {
        // Fallback: show support info
        if (context.mounted) {
          final themeProvider = Provider.of<ThemeProvider>(
            context,
            listen: false,
          );
          final isDark = themeProvider.isDarkMode;

          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.elasticOut,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.support_agent_rounded,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Contact Support',
                          style: AppTextStyles.getTitle(
                            isDark: isDark,
                          ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Support info
                        Column(
                          children: [
                            _buildSupportItem(
                              Icons.email_rounded,
                              'Email',
                              'support@manna.com',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildSupportItem(
                              Icons.phone_rounded,
                              'Phone',
                              '+1 (555) 123-4567',
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildSupportItem(
                              Icons.schedule_rounded,
                              'Hours',
                              'Mon-Fri 9AM-6PM EST',
                              isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Close button
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: ElevatedButton(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/home');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Close',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppUtils.showErrorSnackBar(context, 'Failed to open email app');
      }
    }
  }

  Widget _buildSupportItem(
    IconData icon,
    String title,
    String value,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkTextSecondary.withValues(alpha: 0.2)
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.getBody(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
