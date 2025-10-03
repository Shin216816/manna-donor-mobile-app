import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_theme.dart';
import 'package:manna_donate_app/core/api_service.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';
import 'package:manna_donate_app/core/logout_service.dart';
import 'package:manna_donate_app/core/background_update_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import screens
import 'package:manna_donate_app/presentation/pages/home/splash_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/login_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/register_screen.dart';
// Removed old verification screen import
import 'package:manna_donate_app/presentation/pages/home/modern_home_screen.dart';
import 'package:manna_donate_app/presentation/pages/bank/link_bank_account_screen.dart';
import 'package:manna_donate_app/presentation/pages/church/church_selection_screen.dart';
import 'package:manna_donate_app/presentation/pages/donation/donation_preferences_screen.dart';
import 'package:manna_donate_app/presentation/pages/donation/donation_history_screen.dart';
import 'package:manna_donate_app/presentation/pages/donation/roundup_donation_screen.dart';
import 'package:manna_donate_app/presentation/pages/donation/enhanced_roundup_dashboard_screen.dart';
import 'package:manna_donate_app/presentation/pages/notifications/church_messages_screen.dart';
import 'package:manna_donate_app/presentation/pages/profile/profile_screen.dart';
import 'package:manna_donate_app/presentation/pages/settings/settings_screen.dart';
import 'package:manna_donate_app/presentation/pages/help/help_screen.dart';
import 'package:manna_donate_app/presentation/pages/security/lock_screen.dart';
import 'package:manna_donate_app/presentation/pages/security/pin_unlock_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/change_password_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/forgot_password_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/verify_otp_screen.dart';
import 'package:manna_donate_app/presentation/pages/auth/reset_password_screen.dart';
import 'package:manna_donate_app/presentation/pages/payment/payment_methods_screen.dart';
import 'package:manna_donate_app/presentation/pages/payment/add_payment_method_screen.dart';
import 'package:manna_donate_app/presentation/pages/bank/bank_accounts_screen.dart';


import 'package:manna_donate_app/presentation/pages/transactions/transactions_screen.dart';
import 'package:manna_donate_app/presentation/widgets/app_bottom_navbar.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

// Custom theme wrapper to prevent app rebuilds
class ThemeWrapper extends StatelessWidget {
  final Widget child;

  const ThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Safely access theme provider with null check
        if (themeProvider == null) {
          return this.child;
        }

        // Apply theme overlay without rebuilding the entire app
        return Theme(
          data: themeProvider.isDarkMode
              ? AppTheme.darkTheme
              : AppTheme.lightTheme,
          child: this.child,
        );
      },
    );
  }
}

class _AppState extends State<App> with WidgetsBindingObserver {
  static const sessionTimeout = Duration(minutes: 15);
  Timer? _sessionTimer;
  final BackgroundUpdateManager _updateManager = BackgroundUpdateManager();

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(sessionTimeout, _handleSessionTimeout);
  }

  void _handleSessionTimeout() {
    // Access provider safely after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Use LogoutService for proper logout workflow
        LogoutService.executeLogout(context);
        _showSnackBar(
          'Session expired. Please log in again.',
          backgroundColor: AppColors.error,
        );
      }
    });
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _forceNavigateToLogin(BuildContext context) {
    try {
      // Strategy 1: Try immediate navigation
      GoRouter.of(context).go('/login');
      _showSnackBar(
        'You have been signed out successfully.',
        backgroundColor: AppColors.success,
      );
    } catch (e) {
      // Strategy 1 failed, try strategy 2
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          GoRouter.of(context).go('/login');
          _showSnackBar(
            'You have been signed out successfully.',
            backgroundColor: AppColors.success,
          );
        } catch (e2) {
          // Strategy 2 failed, try strategy 3
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              GoRouter.of(context).go('/login');
              _showSnackBar(
                'You have been signed out successfully.',
                backgroundColor: AppColors.success,
              );
            } catch (e3) {
              // All strategies failed, handle gracefully
              // Fallback to basic initialization
            }
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetSessionTimer();

    // Start background updates when app initializes
    _updateManager.startBackgroundUpdates();

    // Set logout callback for proper navigation after logout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.setLogoutCallback(() {
          if (mounted) {
            context.go('/login');
          }
        });
        
        // Load auth state after the app is ready
        // This ensures the splash screen can show before authentication is checked
        authProvider.initializeAuthState();
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _updateManager.stopBackgroundUpdates();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _resetSessionTimer();
    } else if (state == AppLifecycleState.paused) {
      _sessionTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Manna - Roundup Donations',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Default to light theme
          routerConfig: _createRouter(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return ThemeWrapper(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(
                    1.0,
                  ), // Prevent text scaling
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }

  static GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      redirect: (context, state) {
        try {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );

          // Wait for auth provider to initialize
          if (authProvider.isLoading) {
            return null;
          }

          final currentLocation = state.matchedLocation;

          // Define auth routes (routes that don't require authentication)
          final authRoutes = [
            '/login',
            '/register',
            '/forgot-password',
            '/verify-otp',
            '/reset-password',
          ];

          final isOnAuthRoute = authRoutes.any(
            (route) => currentLocation.startsWith(route),
          );

          // Check if user is properly authenticated (without triggering state changes)
          final isAuthenticated = authProvider.isAuthenticated;

      
          if (isAuthenticated && isOnAuthRoute) {
            return null;
          }

          // If not authenticated and not on splash or auth route, redirect to login
          if (!isAuthenticated && currentLocation != '/' && !isOnAuthRoute) {
            return '/login';
          }

          // Don't redirect from splash - let splash handle navigation for all users
          // This allows the video to complete and provides consistent startup experience
          if (currentLocation == '/') {
            return null;
          }
        } catch (e) {
          // On any error, redirect to login for safety
          return '/login';
        }
      },
      routes: [
        // Splash screen
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

        // Authentication routes
        GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) => const VerifyOtpScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),

        

        // Main app routes (require authentication)
        ShellRoute(
          builder: (context, state, child) => _MainScaffold(child: child),
          routes: [
            // Home/Dashboard
            GoRoute(
              path: '/home',
              builder: (context, state) => const ModernHomeScreen(),
            ),

            // Bank account linking
            GoRoute(
              path: '/link-bank-account',
              builder: (context, state) => const LinkBankAccountScreen(),
            ),

            // Bank accounts
            GoRoute(
              path: '/bank-accounts',
              builder: (context, state) => const BankAccountsScreen(),
            ),

            // Church selection
            GoRoute(
              path: '/church-selection',
              builder: (context, state) => const ChurchSelectionScreen(),
            ),

            // Donation management
            GoRoute(
              path: '/donation-preferences',
              builder: (context, state) => const DonationPreferencesScreen(),
            ),
            GoRoute(
              path: '/donation-history',
              builder: (context, state) => const DonationHistoryScreen(),
            ),
            GoRoute(
              path: '/donation-dashboard',
              builder: (context, state) =>
                  const EnhancedRoundupDashboardScreen(),
            ),
            GoRoute(
              path: '/roundup-donate',
              builder: (context, state) => const RoundupDonationScreen(),
            ),
            GoRoute(
              path: '/enhanced-roundup-dashboard',
              builder: (context, state) =>
                  const EnhancedRoundupDashboardScreen(),
            ),
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
            GoRoute(
              path: '/church-messages',
              builder: (context, state) => const ChurchMessagesScreen(),
            ),

            // Profile and settings
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/change-password',
              builder: (context, state) => const ChangePasswordScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/help',
              builder: (context, state) => const HelpScreen(),
            ),

            // Payment methods
            GoRoute(
              path: '/payment-methods',
              builder: (context, state) => const PaymentMethodsScreen(),
            ),
            GoRoute(
              path: '/add-payment-method',
              builder: (context, state) => const AddPaymentMethodScreen(),
            ),

            // Security
            GoRoute(
              path: '/lock',
              builder: (context, state) => const LockScreen(),
            ),
            GoRoute(
              path: '/pin-unlock',
              builder: (context, state) => const PinUnlockScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

class _MainScaffold extends StatefulWidget {
  final Widget child;

  const _MainScaffold({required this.child});

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold> {
  int _currentIndex = 0;

  final List<_NavigationItem> _navigationItems = [
    _NavigationItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _NavigationItem(
      icon: Icons.volunteer_activism_rounded,
      label: 'Roundup',
      route: '/enhanced-roundup-dashboard',
    ),
    _NavigationItem(
      icon: Icons.account_balance_rounded,
      label: 'Bank',
      route: '/bank-accounts',
    ),
    _NavigationItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();

  }



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      // Return a loading screen while redirecting
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final currentRoute = GoRouterState.of(context).matchedLocation;

    // Update current index based on route
    for (int i = 0; i < _navigationItems.length; i++) {
      if (currentRoute == _navigationItems[i].route) {
        _currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNavBar(
        activeIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            context.go(_navigationItems[index].route);
          }
        },
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
