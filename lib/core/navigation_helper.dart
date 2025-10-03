import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/logout_service.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static bool _isNavigatingToHome = false;
  
  // Global method to navigate to login page
  static void navigateToLogin(BuildContext context) {
    try {
      // Strategy 1: Direct navigation
      GoRouter.of(context).go('/login');
    } catch (e) {
      // Strategy 2: Try with post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          GoRouter.of(context).go('/login');
        } catch (e2) {
          // Strategy 3: Try with delay
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              GoRouter.of(context).go('/login');
            } catch (e3) {
              // Strategy 4: Final attempt
              Future.delayed(const Duration(milliseconds: 500), () {
                try {
                  GoRouter.of(context).go('/login');
                } catch (e4) {
                  // Final fallback - do nothing
                }
              });
            }
          });
        }
      });
    }
  }
  
  // Safe navigation to home - prevents multiple simultaneous calls
  static Future<void> navigateToHome(BuildContext context) async {
    if (_isNavigatingToHome) return;
    
    try {
      _isNavigatingToHome = true;
      
      // Small delay to prevent navigation conflicts
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (context.mounted) {
        GoRouter.of(context).go('/home');
      }
    } finally {
      // Reset flag after a delay to allow future navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _isNavigatingToHome = false;
      });
    }
  }
  
  // Show logout success message
  static void showLogoutMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('You have been signed out successfully.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  // Force logout with navigation and message - now uses LogoutService
  static void forceLogout(BuildContext context) {
    LogoutService.executeLogout(context);
  }
  
  static void testNavigation(BuildContext context) {
    try {
      GoRouter.of(context).go('/login');
    } catch (e) {
      // Handle navigation error
    }
  }
} 