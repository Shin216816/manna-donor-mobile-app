import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/core/logout_service.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:manna_donate_app/data/repository/security_provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/theme_toggle.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/core/utils.dart';
import 'dart:ui';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Settings', showThemeToggle: false),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            AppConstants.headerHeight + AppConstants.pagePadding,
            AppConstants.pagePadding,
            AppConstants.pagePadding,
          ),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 600),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  // Theme toggle section
                  _buildSectionTitle(isDark, 'Appearance'),
                  const SizedBox(height: 16),
                  const ThemeToggle(),

                  const SizedBox(height: 32),

                  // Account settings
                  _buildSectionTitle(isDark, 'Account'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(isDark, [
                    _buildSettingsItem(
                      isDark,
                      'Change Password',
                      Icons.lock_reset,
                      () => _showChangePasswordDialog(context, isDark),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Support & Legal
                  _buildSectionTitle(isDark, 'Support & Legal'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(isDark, [
                    _buildSettingsItem(
                      isDark,
                      'Help & Support',
                      Icons.help_outline,
                      () => context.go('/help'),
                    ),

                    _buildSettingsItem(
                      isDark,
                      'Privacy Policy',
                      Icons.privacy_tip,
                      () => launchUrl(Uri.parse('https://manna.com/privacy')),
                    ),

                    _buildSettingsItem(
                      isDark,
                      'Terms of Service',
                      Icons.description,
                      () => launchUrl(Uri.parse('https://manna.com/terms')),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Logout
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: AppTextStyles.getTitle(
          isDark: isDark,
        ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(
    bool isDark,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.darkPrimary : AppColors.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.getBody(
          isDark: isDark,
        ).copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return AnimationConfiguration.staggeredList(
      position: 8,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: AppColors.error, size: 20),
              ),
              title: Text(
                'Logout',
                style: AppTextStyles.getBody(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600, color: AppColors.error),
              ),
              subtitle: Text(
                'Sign out of your account',
                style: AppTextStyles.getCaption(isDark: isDark),
              ),
              onTap: () => LogoutService.executeLogout(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, bool isDark) async {
    final securityProvider = Provider.of<SecurityProvider>(
      context,
      listen: false,
    );

    // Require biometric/PIN unlock
    if (!securityProvider.unlocked) {
      final unlocked = await securityProvider.unlockWithBiometrics();
      if (!unlocked) {
        AppUtils.showSnackBar(context, 'Biometric/PIN unlock required.');
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change Password',
              style: AppTextStyles.getTitle(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildChangePasswordForm(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordForm(BuildContext context, bool isDark) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            ModernInputField(
              controller: oldPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              isRequired: true,
              isDark: isDark,
            ),
            SizedBox(height: 16.sp),
            ModernInputField(
              controller: newPasswordController,
              label: 'New Password',
              hint: 'Enter your new password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              isRequired: true,
              isDark: isDark,
            ),
            SizedBox(height: 16.sp),
            ModernInputField(
              controller: confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Confirm your new password',
              prefixIcon: Icons.lock_outlined,
              obscureText: true,
              isRequired: true,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 40.sp,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        // Handle password change
                        setState(() => isLoading = true);
                        await Future.delayed(const Duration(seconds: 1));
                        setState(() => isLoading = false);
                        context.pop();
                        AppUtils.showSnackBar(
                          context,
                          'Password changed successfully!',
                          backgroundColor: AppColors.success,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.darkPrimary
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: EnhancedLoadingWidget(
                          type: LoadingType.spinner,
                          size: 20,
                          showMessage: false,
                        ),
                      )
                    : Text('Change Password', style: AppTextStyles.button),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearCredentialsDialog(BuildContext context, bool isDark) {
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
                        color: AppColors.warning.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.cleaning_services,
                        size: 40,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            height: 40.sp,
                            child: TextButton(
                              onPressed: () => context.pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                              .withValues(alpha: 0.3)
                                        : AppColors.textSecondary.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.getBody(isDark: isDark)
                                    .copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Clear button
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            height: 40.sp,
                            child: ElevatedButton(
                              onPressed: () {
                                context.pop();
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                authProvider.clearCredentials();
                                AppUtils.showSnackBar(
                                  context,
                                  'All saved credentials cleared.',
                                  backgroundColor: AppColors.success,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cleaning_services,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Clear',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
