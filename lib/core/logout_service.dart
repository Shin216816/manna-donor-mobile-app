import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

class LogoutService {
  static final LogoutService _instance = LogoutService._internal();
  static final Logger _logger = Logger();
  factory LogoutService() => _instance;
  LogoutService._internal();

  /// Show logout confirmation modal
  static Future<bool> showLogoutConfirmation(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AnimatedContainer(
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
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Sign Out',
                    style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),
                  
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Are you sure you want to sign out? You will need to log in again to access your account.',
                    style: AppTextStyles.getBody(isDark: isDark).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: -0.3, end: 0),
                  
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: ModernButton(
                          text: 'Cancel',
                          onPressed: () => Navigator.of(context).pop(false),
                          variant: ButtonVariant.outlined,
                          width: double.infinity,
                          height: 40.sp,
                        ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.3, end: 0),
                      ),
                      
                      const SizedBox(width: 16),

                      // Logout button
                      Expanded(
                        child: ModernButton(
                          text: 'Sign Out',
                          onPressed: () => Navigator.of(context).pop(true),
                          variant: ButtonVariant.danger,
                          width: double.infinity,
                          height: 40.sp,
                          icon: Icons.logout_rounded,
                        ).animate().fadeIn(duration: 400.ms, delay: 500.ms).slideY(begin: 0.3, end: 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ) ?? false;
  }

  /// Execute complete logout workflow
  static Future<void> executeLogout(BuildContext context) async {
    bool loadingDialogShown = false;
    
    try {
      // Show confirmation dialog
      final confirmed = await showLogoutConfirmation(context);
      
      if (!confirmed) {
        return; // User cancelled
      }

      // Show loading indicator
      _showLogoutLoading(context);
      loadingDialogShown = true;

      // Get auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Execute logout with strict 2-second timeout
      try {
        await Future.any([
          authProvider.logout(),
          Future.delayed(const Duration(seconds: 2)), // Strict 2 second timeout
        ]);
        
        _logger.i('Logout completed successfully');
      } catch (e) {
        _logger.e('Logout error: $e');
        // Continue with cleanup even if logout fails
      }

      // Hide loading indicator immediately
      if (loadingDialogShown) {
        _hideLoadingDialog(context);
        loadingDialogShown = false;
      }

      // Show success message briefly
      _showLogoutSuccess(context);

      // Navigate to login page immediately (no delay)
      if (context.mounted) {
        context.go('/login');
      }

    } catch (e) {
      // Hide loading indicator if showing
      if (loadingDialogShown) {
        _hideLoadingDialog(context);
        loadingDialogShown = false;
      }

      // Show error message briefly
      _showLogoutError(context, e.toString());

      // Navigate to login immediately even if logout fails (no delay)
      if (context.mounted) {
        context.go('/login');
      }
    } finally {
      // Ensure loading dialog is always hidden
      if (loadingDialogShown) {
        _hideLoadingDialog(context);
      }
    }
  }

  /// Show logout loading dialog
  static void _showLogoutLoading(BuildContext context) {
    // Get theme provider to determine dark mode
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false, // Prevent back button
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LoadingWave(
              message: 'Signing out...',
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 40,
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog safely
  static void _hideLoadingDialog(BuildContext context) {
    try {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.e('Error hiding loading dialog: $e');
    }
  }

  /// Show logout success message safely
  static void _showLogoutSuccess(BuildContext context) {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have been signed out successfully.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error showing logout success message: $e');
    }
  }

  /// Show logout error message safely
  static void _showLogoutError(BuildContext context, String error) {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $error'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error showing logout error message: $e');
    }
  }
} 