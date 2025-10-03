import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/analytics_provider.dart';

import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/repository/church_message_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/core/fetch_flags_manager.dart';

import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _typeController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _typeAnimation;

  bool _isLoading = false;
  String? _error;
  String? _errorType;
  int _retryCount = 0;
  int _maxRetries = 3;
  bool _isSettingUpPayment = false;
  String _currentStep = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Defer data initialization to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _typeController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _typeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _typeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _startAnimations();
  }

  Future<void> _initializeData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
      final analyticsProvider = Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      );
      final churchMessageProvider = Provider.of<ChurchMessageProvider>(
        context,
        listen: false,
      );

      // Check if we already have essential data loaded
      final hasEssentialData = await _checkEssentialDataCache(
        authProvider,
        bankProvider,
        roundupProvider,
        churchMessageProvider,
      );

      if (hasEssentialData) {
        // Essential data is already loaded, load from cache if needed
        await _loadDataFromCacheIfNeeded(
          roundupProvider,
          churchMessageProvider,
        );

        // No loading screen needed - data is already available
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Start typewriter animation immediately
          _startTypewriterAnimation();
        }
      } else {
        // First visit after login - show loading screen and fetch fresh data from server
        setState(() {
          _isLoading = true;
        });

        await _loadEssentialData(
          authProvider,
          bankProvider,
          roundupProvider,
          analyticsProvider,
          churchMessageProvider,
        );

        // Wait for providers to notify listeners and UI to update
        if (mounted) {
          // Wait for essential data to be available in providers
          int attempts = 0;
          const maxAttempts = 10;

          while (attempts < maxAttempts) {
            // Check if essential data is now available
            final hasUserProfile = authProvider.user != null;
            final hasRoundupTransactions =
                roundupProvider.roundupTransactions.isNotEmpty;
            final hasChurchMessages = churchMessageProvider.messages.isNotEmpty;
            final hasPaymentMethods = bankProvider.paymentMethods.isNotEmpty;
            final hasBankAccounts = bankProvider.accounts.isNotEmpty;
            final hasPreferences = bankProvider.preferences != null;

            if (hasUserProfile &&
                hasRoundupTransactions &&
                hasChurchMessages &&
                hasPaymentMethods &&
                hasBankAccounts &&
                hasPreferences) {
              // Essential data is available, UI can be updated
              break;
            }

            // Wait a bit and try again
            await Future.delayed(const Duration(milliseconds: 100));
            attempts++;
          }

          // Force a rebuild to ensure UI is updated with new data
          setState(() {});

          // Now hide loading screen after UI is updated with cached data
          setState(() {
            _isLoading = false;
          });
          // Start typewriter animation after loading is complete
          _startTypewriterAnimation();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Start typewriter animation even if there was an error
        _startTypewriterAnimation();
      }
    }
  }

  /// Check if essential data exists in cache
  Future<bool> _checkEssentialDataCache(
    AuthProvider authProvider,
    BankProvider bankProvider,
    RoundupProvider roundupProvider,
    ChurchMessageProvider churchMessageProvider,
  ) async {
    try {
      // Check if home screen data has been fetched once (use flag to prevent double fetching)
      final hasHomeScreenDataFetched =
          FetchFlagsManager.homeScreenDataFetchedOnce;

      // If home screen data has been fetched once, don't fetch again
      // This prevents fetching data multiple times on the same session
      if (hasHomeScreenDataFetched) {
        return true;
      }

      // Check if we have user profile (required)
      final hasUserProfile = authProvider.user != null;
      if (!hasUserProfile) {
        return false; // User profile is essential
      }

      // Check if we have roundup transactions in cache (required)
      final hasRoundupTransactions =
          roundupProvider.roundupTransactions.isNotEmpty;
      if (!hasRoundupTransactions) {
        return false; // Roundup transactions are essential
      }

      // Check if we have church messages in cache (required)
      final hasChurchMessages = churchMessageProvider.messages.isNotEmpty;
      if (!hasChurchMessages) {
        return false; // Church messages are essential
      }

      // Check if we have payment methods in cache (required)
      final hasPaymentMethods = bankProvider.paymentMethods.isNotEmpty;
      if (!hasPaymentMethods) {
        return false; // Payment methods are essential
      }

      // Check if we have bank accounts in cache (required)
      final hasBankAccounts = bankProvider.accounts.isNotEmpty;
      if (!hasBankAccounts) {
        return false; // Bank accounts are essential
      }

      // Check if we have preferences in cache (required)
      final hasPreferences = bankProvider.preferences != null;
      if (!hasPreferences) {
        return false; // Preferences are essential
      }

      // Return true if we have all essential data
      return hasUserProfile &&
          hasRoundupTransactions &&
          hasChurchMessages &&
          hasPaymentMethods &&
          hasBankAccounts &&
          hasPreferences;
    } catch (e) {
      return false;
    }
  }

  /// Load essential data from server and update cache (first visit after login)
  Future<void> _loadEssentialData(
    AuthProvider authProvider,
    BankProvider bankProvider,
    RoundupProvider roundupProvider,
    AnalyticsProvider analyticsProvider,
    ChurchMessageProvider churchMessageProvider,
  ) async {
    try {
      // Load all essential data with fresh data from server (bypass cache)
      // Use individual try-catch blocks to handle cases where some data might not be available
      List<Future<void>> essentialFutures = [
        _safeRefresh(() => authProvider.refreshProfile(), 'Profile'),
        _safeRefresh(
          () => churchMessageProvider.refreshMessages(),
          'Church Messages',
        ),
        _safeRefresh(
          () => roundupProvider.refreshRoundupTransactions(),
          'Roundup Transactions',
        ),
        _safeRefresh(
          () => roundupProvider.refreshEnhancedRoundupStatus(),
          'Roundup Status',
        ),
        _safeRefresh(
          () => roundupProvider.refreshDonationHistory(),
          'Donation History',
        ),
        _safeRefresh(() => bankProvider.refreshBankAccounts(), 'Bank Accounts'),
        _safeRefresh(
          () => bankProvider.smartFetchPaymentMethods(),
          'Payment Methods',
        ),
        _safeRefresh(() => bankProvider.refreshPreferences(), 'Preferences'),
      ];

      // Wait for all essential data to complete
      await Future.wait(essentialFutures);

      // Mark home screen data as fetched once
      FetchFlagsManager.setHomeScreenDataFetchedOnce(true);
      FetchFlagsManager.setTransactionsFetchedOnce(true);
      FetchFlagsManager.setChurchMessagesFetchedOnce(true);
    } catch (e) {
      // Handle error but continue to show screen
    }
  }

  /// Safely refresh data with error handling (handles both Future<bool> and Future<void>)
  Future<void> _safeRefresh(
    Future<dynamic> Function() refreshFunction,
    String dataName,
  ) async {
    try {
      final result = await refreshFunction();
      if (result is bool && !result) {
        print('Failed to refresh $dataName');
      }
    } catch (e) {
      print('Error refreshing $dataName: $e');
    }
  }

  /// Safely refresh data and return boolean result
  Future<bool> _safeRefreshBool(
    Future<bool> Function() refreshFunction,
    String dataName,
  ) async {
    try {
      final success = await refreshFunction();
      if (!success) {
        print('Failed to refresh $dataName');
      }
      return success;
    } catch (e) {
      print('Error refreshing $dataName: $e');
      return false;
    }
  }

  /// Load data from cache if needed (for subsequent visits)
  Future<void> _loadDataFromCacheIfNeeded(
    RoundupProvider roundupProvider,
    ChurchMessageProvider churchMessageProvider,
  ) async {
    try {
      List<Future<void>> cacheFutures = [];

      // Load roundup transactions from cache if empty
      if (roundupProvider.roundupTransactions.isEmpty) {
        cacheFutures.add(roundupProvider.smartFetchRoundupTransactions());
      }

      // Load church messages from cache if empty
      if (churchMessageProvider.messages.isEmpty) {
        cacheFutures.add(churchMessageProvider.fetchMessages());
      }

      // Wait for all cache loading to complete
      if (cacheFutures.isNotEmpty) {
        await Future.wait(cacheFutures);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Load additional data in background using cache-first approach (subsequent visits)
  void _loadDataInBackground(
    AuthProvider authProvider,
    BankProvider bankProvider,
    RoundupProvider roundupProvider,
    AnalyticsProvider analyticsProvider,
    ChurchMessageProvider churchMessageProvider,
  ) {
    // Load additional data in background after essential data is loaded
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // Check current status after fetching
        final hasChurch = authProvider.user?.churchIds != null;
        final hasBankAccounts = bankProvider.hasLinkedAccounts;
        final hasPreferences = bankProvider.hasUserPreferences;

        // Only load additional data if user has completed setup
        if (hasChurch && hasBankAccounts && hasPreferences) {
          await Future.wait([
            roundupProvider.smartFetchRoundupSettings(),
            analyticsProvider.loadMobileImpactSummary(),
            analyticsProvider.loadMobileDashboard(),
          ]);
        }
      } catch (e) {
        // Handle error silently
      }
    });
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _slideController.forward();
    _fadeController.forward();
    _scaleController.forward();
    _waveController.repeat(reverse: true);
  }

  /// Start typewriter animation after loading is complete
  void _startTypewriterAnimation() {
    // Start typewriter animation 500ms after loading is finished
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _typeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _waveController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  /// Build enhanced loading screen with animations and progress indicators
  Widget _buildEnhancedLoadingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackground,
                    AppColors.darkBackground.withValues(alpha: 0.95),
                  ]
                : [
                    AppColors.background,
                    AppColors.background.withValues(alpha: 0.95),
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Top section with logo and title
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated logo container
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.roundupPrimary,
                                    AppColors.roundupPrimary.withValues(
                                      alpha: 0.8,
                                    ),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.roundupPrimary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // App title with fade animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Manna',
                                style: AppTextStyles.getTitle(isDark: isDark)
                                    .copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Subtitle with slide animation
                            SlideTransition(
                              position: _slideAnimation,
                              child: Text(
                                'Your Giving Journey',
                                style: AppTextStyles.getBody(isDark: isDark)
                                    .copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Middle section with loading indicators
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          // Loading message with typewriter effect
                          _buildLoadingMessage(isDark),

                          const SizedBox(height: 30),

                          // Progress indicators
                          _buildProgressIndicators(isDark),

                          const SizedBox(height: 30),

                          // Loading tips
                          _buildLoadingTips(isDark),
                        ],
                      ),
                    ),

                    // Bottom section with progress bar
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Animated progress bar
                            _buildAnimatedProgressBar(isDark),

                            const SizedBox(height: 15),

                            // Progress text
                            Text(
                              'Preparing your dashboard...',
                              style: AppTextStyles.getCaption(isDark: isDark)
                                  .copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                            ),

                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build loading message with typewriter effect
  Widget _buildLoadingMessage(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(
          alpha: 0.1,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? AppColors.darkPrimary : AppColors.primary)
              .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading your data',
            style: AppTextStyles.getBody(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress indicators for different data types
  Widget _buildProgressIndicators(bool isDark) {
    final indicators = [
      {
        'icon': Icons.account_circle,
        'text': 'Profile',
        'color': AppColors.primary as Color,
      },
      {
        'icon': Icons.account_balance,
        'text': 'Bank Accounts',
        'color': AppColors.success as Color,
      },
      {
        'icon': Icons.favorite,
        'text': 'Transactions',
        'color': AppColors.roundupPrimary as Color,
      },
      {
        'icon': Icons.church,
        'text': 'Church Messages',
        'color': AppColors.warning as Color,
      },
    ];

    return Column(
      children: indicators.asMap().entries.map((entry) {
        final index = entry.key;
        final indicator = entry.value;

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value * (1 - (index * 0.2)),
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isDark ? AppColors.darkBorder : AppColors.border)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: (indicator['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          indicator['icon'] as IconData,
                          color: indicator['color'] as Color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          indicator['text'] as String,
                          style: AppTextStyles.getBody(
                            isDark: isDark,
                          ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ),
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: indicator['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  /// Build loading tips
  Widget _buildLoadingTips(bool isDark) {
    final tips = [
      'Setting up your giving preferences...',
      'Connecting to your bank accounts...',
      'Loading your donation history...',
      'Preparing your roundup dashboard...',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface.withValues(alpha: 0.5),
                  AppColors.darkSurface.withValues(alpha: 0.3),
                ]
              : [
                  AppColors.surface.withValues(alpha: 0.5),
                  AppColors.surface.withValues(alpha: 0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 18),
              const SizedBox(width: 6),
              Text(
                'Did you know?',
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final tipIndex =
                  ((_pulseAnimation.value * tips.length) % tips.length).floor();
              return Text(
                tips[tipIndex],
                style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build animated progress bar
  Widget _buildAnimatedProgressBar(bool isDark) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.surface).withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.3 + (0.4 * _pulseAnimation.value),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.roundupPrimary,
                    AppColors.roundupPrimary.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.roundupPrimary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final bankProvider = Provider.of<BankProvider>(context);
    final roundupProvider = Provider.of<RoundupProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
      // Return a loading screen while redirecting
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
              SizedBox(height: 16.sp),
              Text(
                'Redirecting to login...',
                style: AppTextStyles.getBody(isDark: isDark),
              ),
            ],
          ),
        ),
      );
    }

    // Show enhanced loading screen if data is still loading
    if (_isLoading) {
      return _buildEnhancedLoadingScreen(isDark);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Manna'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Main content - always visible
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                final roundupProvider = Provider.of<RoundupProvider>(
                  context,
                  listen: false,
                );
                final bankProvider = Provider.of<BankProvider>(
                  context,
                  listen: false,
                );
                final analyticsProvider = Provider.of<AnalyticsProvider>(
                  context,
                  listen: false,
                );

                // Fetch fresh data from backend (bypass cache)

                await Future.wait([
                  roundupProvider.refreshRoundupTransactionsCache(),
                  roundupProvider.refreshEnhancedRoundupStatus(),
                  roundupProvider.refreshDonationHistory(),
                  bankProvider.refreshBankAccounts(),
                  bankProvider.smartFetchPaymentMethods(),
                  bankProvider.refreshPreferences(),
                  analyticsProvider.refreshMobileImpactSummary(),
                  analyticsProvider.refreshMobileDashboard(),
                ]);
              },
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
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
                        // Welcome section
                        _buildWelcomeSection(isDark, authProvider),
                        const SizedBox(height: 16),

                        // Onboarding mission cards
                        _buildOnboardingMissionCards(
                          isDark,
                          authProvider,
                          bankProvider,
                        ),
                        const SizedBox(height: 16),

                        // Roundup summary card
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildRoundupSummaryCard(
                              isDark,
                              roundupProvider,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Recent donations
                        _buildRecentDonations(isDark, roundupProvider),
                        const SizedBox(height: 16),

                        // Setup prompts
                        if (!bankProvider.hasLinkedAccounts)
                          _buildSetupPrompt(
                            isDark,
                            'Link Bank Account',
                            'Connect your bank to start roundup donations',
                            Icons.account_balance,
                            '/link-bank-account',
                          ),
                        // Donation preferences are optional - only show if user has linked accounts
                        if (bankProvider.hasLinkedAccounts)
                          _buildSetupPrompt(
                            isDark,
                            'Donation Preferences',
                            'Customize your donation settings (optional)',
                            Icons.favorite,
                            '/donation-preferences',
                          ),

                        // Church Admin Communication (for church admins)
                        if (authProvider.user?.isChurchAdmin == true)
                          _buildSetupPrompt(
                            isDark,
                            'Send Message to Donors',
                            'Communicate with your donors directly',
                            Icons.message,
                            '/church-admin-communication',
                          ),
                        const SizedBox(height: 16),

                        // Quick actions
                        _buildQuickActions(isDark),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark, AuthProvider authProvider) {
    final userName = authProvider.user?.firstName ?? 'User';
    final timeOfDay = _getTimeOfDay();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return Container(
                padding: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.darkPrimary.withValues(alpha: 0.08),
                            AppColors.darkPrimaryDark.withValues(alpha: 0.04),
                          ]
                        : [
                            AppColors.primary.withValues(alpha: 0.06),
                            AppColors.primaryDark.withValues(alpha: 0.03),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.sp),
                  boxShadow: [
                    // Inner shadow for depth
                    BoxShadow(
                      color:
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                    // Outer glow effect that extends outward
                    BoxShadow(
                      color:
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 0),
                      spreadRadius: 1,
                    ),
                    // Additional outer glow for more dramatic effect
                    BoxShadow(
                      color:
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.04),
                      blurRadius: 25,
                      offset: const Offset(0, 0),
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main content
                    Row(
                      children: [
                        SizedBox(width: 16.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedBuilder(
                                animation: _typeAnimation,
                                builder: (context, child) {
                                  final greetingText = '$timeOfDay, $userName!';
                                  final displayedText = _getTypewriterText(
                                    greetingText,
                                    _typeAnimation.value,
                                  );

                                  return Row(
                                    children: [
                                      Text(
                                        displayedText,
                                        style:
                                            AppTextStyles.getTitle(
                                              isDark: isDark,
                                            ).copyWith(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (_typeAnimation.value < 1.0)
                                        AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _pulseAnimation.value,
                                              child: Container(
                                                width: 3.sp,
                                                height: 20.sp,
                                                margin: EdgeInsets.only(
                                                  left: 2.sp,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: (isDark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.primary),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        1.5.sp,
                                                      ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          (isDark
                                                                  ? AppColors
                                                                        .darkPrimary
                                                                  : AppColors
                                                                        .primary)
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                      blurRadius: 2,
                                                      offset: const Offset(
                                                        0,
                                                        1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(height: 4.sp),
                              Text(
                                'Ready to make a difference with your spare change?',
                                style:
                                    AppTextStyles.getBodySmall(
                                      isDark: isDark,
                                    ).copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                      fontSize: 12.sp,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Active badge positioned at top-right corner
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoundupSummaryCard(
    bool isDark,
    RoundupProvider roundupProvider,
  ) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkRoundupBackground,
                        AppColors.darkRoundupCard,
                      ]
                    : [AppColors.roundupBackground, AppColors.roundupCard],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.sp),
              boxShadow: [
                BoxShadow(
                  color: AppColors.roundupPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with enhanced animations
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 45.sp,
                            height: 45.sp,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.roundupPrimary,
                                  AppColors.roundupPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.roundupPrimary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.volunteer_activism,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Roundup',
                            style:
                                AppTextStyles.getRoundupSubtitle(
                                  isDark: isDark,
                                ).copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 3.sp),
                          Builder(
                            builder: (context) {
                              // Get user registration date from auth provider
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              final userRegistrationDate =
                                  authProvider.user?.createdAt;

                              // Calculate total amount including pending amount
                              final totalAmount = roundupProvider
                                  .getThisMonthRoundupTotalWithPending(
                                    userRegistrationDate,
                                  );
                              final pendingAmount = roundupProvider
                                  .getPendingAmount(userRegistrationDate);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${totalAmount.toStringAsFixed(2)}',
                                    style:
                                        AppTextStyles.getRoundupAmount(
                                          isDark: isDark,
                                        ).copyWith(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (pendingAmount > 0)
                                    Text(
                                      '(+ \$${pendingAmount.toStringAsFixed(2)} pending)',
                                      style:
                                          AppTextStyles.getCaption(
                                            isDark: isDark,
                                          ).copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                            fontSize: 10.sp,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Status indicator - shows donation pause state
                    Consumer<BankProvider>(
                      builder: (context, bankProvider, child) {
                        final preferences = bankProvider.preferences;
                        final isPaused = preferences?.pause ?? false;

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.sp,
                            vertical: 4.sp,
                          ),
                          decoration: BoxDecoration(
                            color: isPaused
                                ? AppColors.warning.withValues(alpha: 0.08)
                                : AppColors.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.sp),
                            border: Border.all(
                              color: isPaused
                                  ? AppColors.warning.withValues(alpha: 0.2)
                                  : AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPaused
                                    ? Icons.pause_circle
                                    : Icons.trending_up,
                                color: isPaused
                                    ? AppColors.warning
                                    : AppColors.success,
                                size: 12.sp,
                              ),
                              SizedBox(width: 3.sp),
                              Text(
                                isPaused ? 'Paused' : 'Active',
                                style: AppTextStyles.getCaption(isDark: isDark)
                                    .copyWith(
                                      color: isPaused
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.sp,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 16.sp),

                // This Month's Stats
                Text(
                  'This Month',
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.sp),
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12.sp),
                        boxShadow: [
                          // Inner shadow for depth
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.03,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                          // Outer glow effect that extends outward
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.08 + (0.12 * _waveAnimation.value),
                            ),
                            blurRadius: 12 + (8 * _waveAnimation.value),
                            offset: const Offset(0, 0),
                            spreadRadius: 1 + (2 * _waveAnimation.value),
                          ),
                          // Additional outer glow for more dramatic effect
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.04 + (0.08 * _waveAnimation.value),
                            ),
                            blurRadius: 20 + (12 * _waveAnimation.value),
                            offset: const Offset(0, 0),
                            spreadRadius: 2 + (3 * _waveAnimation.value),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false,
                                );
                                final userRegistrationDate =
                                    authProvider.user?.createdAt;
                                final totalAmount = roundupProvider
                                    .getThisMonthRoundupTotalWithPending(
                                      userRegistrationDate,
                                    );

                                return _buildCompactStatItem(
                                  isDark,
                                  'Roundup',
                                  '\$${totalAmount.toStringAsFixed(2)}',
                                  Icons.trending_up,
                                  AppColors.success,
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 16.sp),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final totalTransactions =
                                    roundupProvider.thisMonthTransactionCount;
                                return _buildCompactStatItem(
                                  isDark,
                                  'Transactions',
                                  '$totalTransactions',
                                  Icons.receipt_long,
                                  AppColors.primary,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.sp),

                // Last Month's Stats
                Text(
                  'Last Month Roundup',
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 12.sp),
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: EdgeInsets.all(16.sp),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(12.sp),
                        boxShadow: [
                          // Inner shadow for depth
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.03,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                            spreadRadius: 0,
                          ),
                          // Outer glow effect that extends outward
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.08 + (0.12 * _waveAnimation.value),
                            ),
                            blurRadius: 12 + (8 * _waveAnimation.value),
                            offset: const Offset(0, 0),
                            spreadRadius: 1 + (2 * _waveAnimation.value),
                          ),
                          // Additional outer glow for more dramatic effect
                          BoxShadow(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.04 + (0.08 * _waveAnimation.value),
                            ),
                            blurRadius: 20 + (12 * _waveAnimation.value),
                            offset: const Offset(0, 0),
                            spreadRadius: 2 + (3 * _waveAnimation.value),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final lastMonthAmount =
                                        roundupProvider.lastMonthRoundupTotal;
                                    return _buildCompactStatItem(
                                      isDark,
                                      'Roundup',
                                      '\$${lastMonthAmount.toStringAsFixed(2)}',
                                      Icons.trending_up,
                                      AppColors.roundupPrimary,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16.sp),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final lastMonthTransactions =
                                        roundupProvider
                                            .lastMonthTransactionCount;
                                    return _buildCompactStatItem(
                                      isDark,
                                      'Transactions',
                                      '$lastMonthTransactions',
                                      Icons.receipt_long,
                                      AppColors.warning,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.sp),
                          Row(
                            children: [
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final lastMonthDonations =
                                        roundupProvider.lastMonthDonationTotal;
                                    return _buildCompactStatItem(
                                      isDark,
                                      'Total Donations',
                                      '\$${lastMonthDonations.toStringAsFixed(2)}',
                                      Icons.favorite,
                                      AppColors.primary,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 16.sp),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final lastDonationDate =
                                        roundupProvider.lastDonationDate;
                                    return _buildCompactStatItem(
                                      isDark,
                                      'Last Donation',
                                      lastDonationDate != null
                                          ? _formatLastDonationDate(
                                              lastDonationDate,
                                            )
                                          : 'Empty yet',
                                      Icons.calendar_today,
                                      AppColors.warning,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.99,
          child: Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.08),
                  color.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(color: color.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 32.sp,
                  height: 32.sp,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Icon(icon, color: color, size: 16.sp),
                ),
                SizedBox(height: 8.sp),
                Text(
                  value,
                  style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                    color: color,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.sp),
                Text(
                  label,
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build compact stat item with icon and value in one line
  Widget _buildCompactStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 28.sp,
          height: 28.sp,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6.sp),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        SizedBox(width: 10.sp),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  color: color,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.roundupPrimary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.getBody(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.roundupPrimary,
            ),
          ),
          Text(label, style: AppTextStyles.getCaption(isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quick Actions',
                  style: AppTextStyles.getTitle(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.sp,
                    vertical: 4.sp,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.sp),
                  ),
                  child: Text(
                    '4 Actions',
                    style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedActionCard(
                    isDark,
                    'Preferences',
                    'Manage donation settings',
                    Icons.settings,
                    () => context.go('/donation-preferences'),
                    [AppColors.warning, AppColors.warningDark],
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: _buildEnhancedActionCard(
                    isDark,
                    'History',
                    'View donation history',
                    Icons.history,
                    () => context.go('/donation-history'),
                    [AppColors.success, AppColors.successDark],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedActionCard(
                    isDark,
                    'Transactions',
                    'View all roundup transactions',
                    Icons.receipt_long,
                    () => context.go('/transactions'),
                    [AppColors.info, AppColors.infoDark],
                  ),
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: _buildEnhancedActionCard(
                    isDark,
                    'Dashboard',
                    'Enhanced roundup dashboard',
                    Icons.dashboard,
                    () => context.go('/enhanced-roundup-dashboard'),
                    [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedActionCard(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    List<Color> gradient,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.99,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.sp),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 36.sp,
                    height: 36.sp,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18.sp),
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    title,
                    style: AppTextStyles.getBody(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.sp),
                  Text(
                    subtitle,
                    style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 9.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.sp),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.sp,
                      vertical: 4.sp,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(16.sp),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40.sp,
              height: 40.sp,
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
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.getBody(
                isDark: isDark,
              ).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.getCaption(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(
    bool isDark,
    String value,
    String label,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.roundupPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.roundupPrimary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.getTitle(
            isDark: isDark,
          ).copyWith(color: AppColors.roundupPrimary, fontSize: 20),
        ),
        Text(
          label,
          style: AppTextStyles.getCaption(isDark: isDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentDonations(bool isDark, RoundupProvider roundupProvider) {
    // Load donation history using cache-first approach only if not already fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (roundupProvider.donationHistory.isEmpty &&
          !roundupProvider.loading &&
          !roundupProvider.donationHistoryFetched &&
          !FetchFlagsManager.homeScreenDataFetchedOnce) {
        // Use smart fetch for cache-first approach only on first visit
        roundupProvider.smartFetchDonationHistory();
      }
    });

    return Container(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Donations',
            style: AppTextStyles.getTitle(isDark: isDark),
          ),
          const SizedBox(height: 16),
          if (roundupProvider.loading)
            Container(
              padding: const EdgeInsets.fromLTRB(60, 20, 60, 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: LoadingWave(
                  message: 'Loading donations...',
                  color: AppColors.roundupPrimary,
                  size: 32,
                  isDark: isDark,
                ),
              ),
            )
          else if (roundupProvider.donationHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary)
                          .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.favorite_outline,
                        color: AppColors.roundupPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No donation history yet',
                      style: AppTextStyles.getBody(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start making donations to see your history here',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(roundupProvider.donationHistory.length, (index) {
              final donation = roundupProvider.donationHistory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: AppColors.roundupPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.churchName ?? 'Donation',
                            style: AppTextStyles.getBody(
                              isDark: isDark,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            donation.statusDisplay,
                            style: AppTextStyles.getCaption(isDark: isDark),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${donation.amount.toStringAsFixed(2)}',
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.roundupPrimary,
                          ),
                        ),
                        Text(
                          _formatDate(donation.date),
                          style: AppTextStyles.getCaption(isDark: isDark),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkPrimary.withValues(alpha: 0.1),
                  AppColors.darkPrimaryDark.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primaryDark.withValues(alpha: 0.05),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.getBody(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.getCaption(isDark: isDark)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await context.push(route);
              // If bank linking was successful, refresh bank accounts using cache-first approach
              if (result == true && route == '/link-bank-account') {
                final bankProvider = Provider.of<BankProvider>(
                  context,
                  listen: false,
                );
                await bankProvider.smartFetchBankAccounts();
              }
            },
            icon: Icon(
              Icons.arrow_forward_ios,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getTimeOfDayIcon(String timeOfDay) {
    switch (timeOfDay) {
      case 'Good Morning':
        return Icons.wb_sunny;
      case 'Good Afternoon':
        return Icons.wb_sunny_outlined;
      case 'Good Evening':
        return Icons.nightlight_round;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Format last donation date for display
  String _formatLastDonationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference < 365) {
      final months = (difference / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Get typewriter text based on animation progress
  String _getTypewriterText(String fullText, double progress) {
    if (progress <= 0) return '';
    if (progress >= 1) return fullText;

    final charCount = (fullText.length * progress).floor();
    return fullText.substring(0, charCount.clamp(0, fullText.length));
  }

  /// Build onboarding mission cards for incomplete setup
  Widget _buildOnboardingMissionCards(
    bool isDark,
    AuthProvider authProvider,
    BankProvider bankProvider,
  ) {
    final List<Widget> missionCards = [];

    // Check if user has no church
    if (authProvider.user?.churchIds.isEmpty ?? true) {
      missionCards.add(
        _buildMissionCard(
          isDark,
          'Select Your Church',
          'Choose a church to support with your donations',
          Icons.church,
          '/church-selection',
          [AppColors.primary, AppColors.primaryDark],
        ),
      );
    }

    // Check if user has no linked bank accounts
    if (!bankProvider.hasLinkedAccounts) {
      missionCards.add(
        _buildMissionCard(
          isDark,
          'Link Bank Account',
          'Connect your bank to start roundup donations',
          Icons.account_balance,
          '/link-bank-account',
          [AppColors.success, AppColors.successDark],
        ),
      );
    }

    // Check if user has no payment methods
    if (bankProvider.paymentMethods.isEmpty) {
      missionCards.add(
        _buildMissionCard(
          isDark,
          'Add Payment Method',
          'Set up a payment method for donations',
          Icons.payment,
          '/payment-methods',
          [AppColors.warning, AppColors.warningDark],
        ),
      );
    }

    // Note: Donation preferences are optional since server provides defaults
    // Only show if user explicitly wants to customize preferences
    // This is now handled as an optional setup step, not a required onboarding step

    // If no mission cards needed, return empty container
    if (missionCards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complete Your Setup',
          style: AppTextStyles.getBody(
            isDark: isDark,
          ).copyWith(fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        SizedBox(height: 12.sp),
        ...missionCards.map(
          (card) => Padding(
            padding: EdgeInsets.only(bottom: 12.sp),
            child: card,
          ),
        ),
      ],
    );
  }

  /// Build individual mission card
  Widget _buildMissionCard(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    String route,
    List<Color> gradient,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (0.02 * _pulseAnimation.value),
          child: GestureDetector(
            onTap: () => context.go(route),
            child: Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.sp),
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.sp,
                    height: 48.sp,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.sp),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Text(
                          subtitle,
                          style: AppTextStyles.getCaption(isDark: isDark)
                              .copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.sp,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Get error color based on error type
  Color _getErrorColor(bool isDark) {
    switch (_errorType) {
      case 'network':
        return AppColors.warning;
      case 'stripe':
        return AppColors.error;
      case 'validation':
        return AppColors.info;
      case 'unknown':
      default:
        return AppColors.error;
    }
  }

  /// Get error icon based on error type
  IconData _getErrorIcon() {
    switch (_errorType) {
      case 'network':
        return Icons.wifi_off;
      case 'stripe':
        return Icons.payment;
      case 'validation':
        return Icons.info_outline;
      case 'unknown':
      default:
        return Icons.error_outline;
    }
  }

  /// Get error title based on error type
  String _getErrorTitle() {
    switch (_errorType) {
      case 'network':
        return 'Connection Error';
      case 'stripe':
        return 'Payment Error';
      case 'validation':
        return 'Validation Error';
      case 'unknown':
      default:
        return 'Error';
    }
  }

  /// Get action button text based on error type
  String _getActionButtonText() {
    switch (_errorType) {
      case 'network':
        return 'Check Connection';
      case 'stripe':
        return 'Contact Support';
      case 'validation':
        return 'Try Again';
      case 'unknown':
      default:
        return 'Get Help';
    }
  }

  /// Get action button action based on error type
  VoidCallback? _getActionButtonAction() {
    switch (_errorType) {
      case 'network':
        return () {
          // Show network status or refresh
          _retryOperation();
        };
      case 'stripe':
        return () {
          // Navigate to support or help
          _showSupportDialog();
        };
      case 'validation':
        return () {
          // Retry the operation
          _retryOperation();
        };
      case 'unknown':
      default:
        return () {
          // Show help or contact support
          _showSupportDialog();
        };
    }
  }

  /// Get action button icon based on error type
  IconData _getActionButtonIcon() {
    switch (_errorType) {
      case 'network':
        return Icons.wifi;
      case 'stripe':
        return Icons.support_agent;
      case 'validation':
        return Icons.refresh;
      case 'unknown':
      default:
        return Icons.help_outline;
    }
  }

  /// Retry the current operation
  void _retryOperation() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _clearError();
      // Implement retry logic here
    } else {
      _errorType = 'unknown';
      _error = 'Maximum retry attempts reached';
    }
  }

  /// Show support dialog
  void _showSupportDialog() {
    // Implement support dialog logic here
    _clearError();
  }

  /// Clear error state
  void _clearError() {
    setState(() {
      _error = null;
      _errorType = null;
      _retryCount = 0;
    });
  }

  /// Setup payment method (placeholder)
  Future<void> _setupPaymentMethod() async {
    // This is a placeholder method - implement actual payment setup logic
    setState(() {
      _isSettingUpPayment = true;
      _currentStep = 'Setting up payment method...';
    });

    try {
      // Simulate payment setup
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _isSettingUpPayment = false;
        _currentStep = 'Setup complete!';
      });
    } catch (e) {
      setState(() {
        _isSettingUpPayment = false;
        _error = 'Failed to setup payment method: $e';
        _errorType = 'stripe';
      });
    }
  }
}
