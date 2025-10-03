import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/church_message_provider.dart';
import 'package:manna_donate_app/data/repository/analytics_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/core/fetch_flags_manager.dart';

class EnhancedRoundupDashboardScreen extends StatefulWidget {
  const EnhancedRoundupDashboardScreen({super.key});

  @override
  State<EnhancedRoundupDashboardScreen> createState() =>
      _EnhancedRoundupDashboardScreenState();
}

class _EnhancedRoundupDashboardScreenState
    extends State<EnhancedRoundupDashboardScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isInitialLoadComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Defer data loading to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithCacheFirst();
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  /// Load data with true cache-first strategy - only load from server if cache is empty
  Future<void> _loadDataWithCacheFirst() async {
    try {
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
      final churchMessageProvider = Provider.of<ChurchMessageProvider>(
        context,
        listen: false,
      );
      final analyticsProvider = Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      );

      // Check if we have essential data in cache first
      bool hasCachedData = await _checkEssentialDataCache(
        roundupProvider,
        churchMessageProvider,
      );

      if (hasCachedData) {
        // Mark as complete immediately since we have cached data
        if (mounted) {
          setState(() {
            _isInitialLoadComplete = true;
          });
        }
      } else {
        // Show loading overlay and fetch from server
        await _loadEssentialDataFromServer(
          roundupProvider,
          churchMessageProvider,
        );
      }

      // Load additional data in background (always cache-first)
      _loadBackgroundData(roundupProvider, analyticsProvider);
    } catch (e) {
      // Error handling is managed by the providers
    }
  }

  /// Check if essential data exists in cache
  Future<bool> _checkEssentialDataCache(
    RoundupProvider roundupProvider,
    ChurchMessageProvider churchMessageProvider,
  ) async {
    try {
      // Check if we have roundup transactions in cache OR if we've already fetched them once
      final hasRoundupTransactions =
          roundupProvider.roundupTransactions.isNotEmpty || FetchFlagsManager.transactionsFetchedOnce;

      // Check if we have church messages in cache OR if we've already fetched them once
      final hasChurchMessages = churchMessageProvider.messages.isNotEmpty || FetchFlagsManager.churchMessagesFetchedOnce;

      // Check if we have enhanced roundup status in cache
      final hasRoundupStatus = roundupProvider.enhancedRoundupStatus != null;

      // Return true if we have all essential data
      return hasRoundupTransactions && hasChurchMessages && hasRoundupStatus;
    } catch (e) {
      return false;
    }
  }

  /// Load essential data from server with loading states
  Future<void> _loadEssentialDataFromServer(
    RoundupProvider roundupProvider,
    ChurchMessageProvider churchMessageProvider,
  ) async {
    try {
      // Prepare list of futures to wait for
      List<Future<void>> futures = [
        // Enhanced roundup status
        roundupProvider.smartFetchEnhancedRoundupStatus(),
      ];

      // Church messages - ONLY fetch if not fetched once before
      if (!FetchFlagsManager.churchMessagesFetchedOnce) {
        futures.add(churchMessageProvider.fetchMessagesWithLoading());
        FetchFlagsManager.setChurchMessagesFetchedOnce(true); // Mark as fetched
      }

      // Wait for all futures to complete
      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _isInitialLoadComplete = true;
        });
      }
    } catch (e) {
      // Even if there's an error, mark as complete to show the screen
      if (mounted) {
        setState(() {
          _isInitialLoadComplete = true;
        });
      }
    }
  }

  /// Load additional data in background without blocking UI (cache-first)
  void _loadBackgroundData(
    RoundupProvider roundupProvider,
    AnalyticsProvider analyticsProvider,
  ) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // Use smart fetch methods that check cache first
        await Future.wait([
          roundupProvider.smartFetchRoundupSettings(), // Cache-first
          analyticsProvider.loadMobileImpactSummary(), // Cache-first
          analyticsProvider.loadMobileDashboard(), // Cache-first
        ]);
      } catch (e) {}
    });
  }

  /// Refresh all data from server (bypass cache)
  Future<void> _refreshAllData() async {
    try {
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
      final churchMessageProvider = Provider.of<ChurchMessageProvider>(
        context,
        listen: false,
      );
      final analyticsProvider = Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      );

      // Force refresh all data from server
      await Future.wait([
        roundupProvider.refreshRoundupTransactionsCache(),
        roundupProvider.refreshEnhancedRoundupStatus(),
        roundupProvider.refreshRoundupSettings(),
        churchMessageProvider.refreshMessages(),
        analyticsProvider.refreshMobileImpactSummary(),
        analyticsProvider.refreshMobileDashboard(),
      ]);
    } catch (e) {}
  }

  /// Reset fetch flags (for debugging/testing)
  static void resetFetchFlags() {
    FetchFlagsManager.resetRoundupDashboardFlags();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final roundupProvider = Provider.of<RoundupProvider>(context);
    final churchMessageProvider = Provider.of<ChurchMessageProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Roundup Dashboard'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: _refreshAllData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 100, bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Enhanced roundup status card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEnhancedRoundupStatusCard(
                        isDark,
                        roundupProvider,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total amounts card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTotalAmountsCard(isDark, roundupProvider),
                    ),
                    const SizedBox(height: 20),

                    // Recent transactions section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildRecentTransactionsSection(
                        isDark,
                        roundupProvider,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Church messages section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildChurchMessagesSection(
                        isDark,
                        churchMessageProvider,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay for initial load
          if (!_isInitialLoadComplete)
            Container(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.8)
                  : AppColors.background.withValues(alpha: 0.8),
              child: Center(
                child: LoadingWave(
                  message: 'Loading roundup data...',
                  color: AppColors.primary,
                  size: 50,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRoundupStatusCard(
    bool isDark,
    RoundupProvider roundupProvider,
  ) {
    // Use ONLY the cached transaction calculation for consistency
    final accumulatedAmount = roundupProvider.accumulatedRoundups;
    final isTransferReady = accumulatedAmount >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkRoundupBackground, AppColors.darkRoundupCard]
              : [AppColors.roundupBackground, AppColors.roundupCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.roundupPrimary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with icon
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.roundupPrimary,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month Roundups',
                      style: AppTextStyles.getRoundupSubtitle(isDark: isDark),
                    ),
                    Text(
                      'Pending Transfer',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Amount display
          Text(
            '\$${accumulatedAmount.toStringAsFixed(2)}',
            style: AppTextStyles.getRoundupAmount(
              isDark: isDark,
            ).copyWith(fontSize: 32),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.roundupPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.roundupPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isTransferReady ? 'Ready for Transfer' : 'Accumulating',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: AppColors.roundupPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountsCard(bool isDark, RoundupProvider roundupProvider) {
    final totalRoundups = roundupProvider.allTimeAccumulatedRoundups;
    final totalRoundupable = roundupProvider.totalRoundupableAmount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkSurface, AppColors.darkCard]
              : [AppColors.surface, AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roundup Statistics',
                      style: AppTextStyles.getRoundupSubtitle(isDark: isDark),
                    ),
                    Text(
                      'Total Impact',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Two columns for amounts
          Row(
            children: [
              // Total Transferred
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.send, color: AppColors.success, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'All-Time Roundups',
                        style: AppTextStyles.getCaption(isDark: isDark)
                            .copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalRoundups.toStringAsFixed(2)}',
                        style: AppTextStyles.getRoundupAmount(
                          isDark: isDark,
                        ).copyWith(fontSize: 20, color: AppColors.success),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Total Roundupable
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase Amount',
                        style: AppTextStyles.getCaption(isDark: isDark)
                            .copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${totalRoundupable.toStringAsFixed(2)}',
                        style: AppTextStyles.getRoundupAmount(
                          isDark: isDark,
                        ).copyWith(fontSize: 20, color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNextTransferCard(bool isDark, RoundupProvider roundupProvider) {
    final nextTransferDate =
        roundupProvider.enhancedRoundupStatus?.nextTransferDate ??
        DateTime.now().add(const Duration(days: 3));
    // Only show estimated amount if there are actual roundup transactions with amounts
    final roundupTransactions = roundupProvider.roundupTransactions;
    final hasValidRoundupTransactions =
        roundupTransactions.isNotEmpty &&
        roundupTransactions.any(
          (transaction) =>
              (transaction['roundup_amount']?.toDouble() ?? 0.0) > 0.0,
        );

    final backendEstimatedAmount =
        roundupProvider.enhancedRoundupStatus?.estimatedNextTransfer ?? 0.0;
    final estimatedAmount = hasValidRoundupTransactions
        ? backendEstimatedAmount
        : 0.0;
    final frequency =
        roundupProvider.enhancedRoundupStatus?.transferFrequencyDisplay ??
        'weekly';

    // Verify calculation accuracy
    final bankProvider = Provider.of<BankProvider>(context, listen: false);
    final localCalculation = bankProvider.thisMonthRoundupCalculation;
    final localRoundupAmount = localCalculation['totalRoundupAmount'] as double;
    final difference = (estimatedAmount - localRoundupAmount).abs();
    final percentageDifference = localRoundupAmount > 0
        ? (difference / localRoundupAmount * 100)
        : 0.0;
    final isCalculationAccurate = percentageDifference <= 5.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.info.withValues(alpha: 0.1),
                  AppColors.info.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.info.withValues(alpha: 0.08),
                  AppColors.info.withValues(alpha: 0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with enhanced icon and styling
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info,
                      AppColors.info.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.schedule, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Next Transfer Date',
                      style: AppTextStyles.getBody(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, MMMM d').format(nextTransferDate),
                      style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                        fontSize: 20,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Enhanced amount section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.info.withValues(alpha: 0.15),
                        AppColors.info.withValues(alpha: 0.08),
                      ]
                    : [
                        AppColors.info.withValues(alpha: 0.12),
                        AppColors.info.withValues(alpha: 0.06),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Transfered Amount',
                          style: AppTextStyles.getCaption(
                            isDark: isDark,
                          ).copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isCalculationAccurate
                              ? Icons.check_circle
                              : Icons.warning,
                          color: isCalculationAccurate
                              ? AppColors.success
                              : AppColors.warning,
                          size: 16,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        frequency.toUpperCase(),
                        style: AppTextStyles.getCaption(isDark: isDark)
                            .copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${estimatedAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                        fontSize: 28,
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'USD',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: AppColors.info.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasValidRoundupTransactions
                                  ? 'Your next roundup transfer of ~\$${estimatedAmount.toStringAsFixed(2)} will occur on ${DateFormat('MMM d').format(nextTransferDate)}'
                                  : 'No roundup transfers scheduled. Start making purchases to accumulate roundups.',
                              style: AppTextStyles.getBodySmall(isDark: isDark)
                                  .copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (!isCalculationAccurate) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Verification: Local calculation shows \$${localRoundupAmount.toStringAsFixed(2)} (${percentageDifference.toStringAsFixed(1)}% difference)',
                          style: AppTextStyles.getBodySmall(
                            isDark: isDark,
                          ).copyWith(color: AppColors.warning, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChurchMessagesSection(
    bool isDark,
    ChurchMessageProvider churchMessageProvider,
  ) {
    final messages = churchMessageProvider.latestMessages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.03),
                ]
              : [
                  AppColors.primary.withValues(alpha: 0.06),
                  AppColors.primary.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.church, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Church Messages',
                    style: AppTextStyles.getTitle(
                      isDark: isDark,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => context.go('/church-messages'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: AppTextStyles.getBodySmall(isDark: isDark).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (messages.isEmpty)
            Container(
              width: double.infinity, // Take full width
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 40,
              ), // Balanced padding
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center content vertically
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center content horizontally
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.message_outlined,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: AppTextStyles.getBody(
                      isDark: isDark,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                    textAlign: TextAlign.center, // Ensure text is centered
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'please wait messages from your church',
                    style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(messages.length, (index) {
              final message = messages[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getMessageTypeColor(
                      message.messageType,
                    ).withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getMessageTypeColor(
                        message.messageType,
                      ).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getMessageTypeColor(message.messageType),
                                _getMessageTypeColor(
                                  message.messageType,
                                ).withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _getMessageTypeColor(
                                  message.messageType,
                                ).withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _getMessageTypeIcon(message.messageType),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.churchName ?? 'Church',
                                style: AppTextStyles.getBody(isDark: isDark)
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getMessageTypeLabel(message.messageType),
                                style: AppTextStyles.getCaption(isDark: isDark)
                                    .copyWith(
                                      color: _getMessageTypeColor(
                                        message.messageType,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMessageTypeColor(
                              message.messageType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('MMM d').format(message.createdAt),
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: _getMessageTypeColor(
                                    message.messageType,
                                  ),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message.title,
                      style: AppTextStyles.getBody(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message.message,
                      style: AppTextStyles.getBodySmall(isDark: isDark)
                          .copyWith(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    bool isDark,
    RoundupProvider roundupProvider,
  ) {
    final transactions = roundupProvider.roundupTransactions;

    // Data is loaded in initState and background loading - no need to trigger here
    // to avoid infinite loops in build method

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.secondary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.03),
                ]
              : [
                  AppColors.secondary.withValues(alpha: 0.06),
                  AppColors.secondary.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recent Transactions',
                    style: AppTextStyles.getTitle(
                      isDark: isDark,
                    ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () => context.go('/transactions'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: AppTextStyles.getBodySmall(isDark: isDark).copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (roundupProvider.loading && transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: LoadingWave(
                  message: 'Loading transactions...',
                  color: AppColors.secondary,
                  size: 40,
                  isDark: isDark,
                ),
              ),
            )
          else if (transactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 28,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions found',
                    style: AppTextStyles.getBody(
                      isDark: isDark,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link your bank account and make purchases to see roundup transactions',
                    style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...List.generate(
              transactions.length.clamp(
                0,
                3,
              ), // Show up to 3 recent transactions
              (index) {
                final transaction = transactions[index];

                // Extract real transaction data
                final merchant = transaction['merchant'] ?? 'Unknown Merchant';
                final amount = transaction['amount']?.toDouble() ?? 0.0;
                final roundupAmount =
                    transaction['roundup_amount']?.toDouble() ?? 0.0;
                final date = transaction['date'] ?? DateTime.now().toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBackground.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.secondary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForMerchant(merchant),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              merchant,
                              style: AppTextStyles.getBody(isDark: isDark)
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, y').format(
                                DateTime.tryParse(date) ?? DateTime.now(),
                              ),
                              style: AppTextStyles.getCaption(isDark: isDark)
                                  .copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '-\$${amount.toStringAsFixed(2)}',
                            style: AppTextStyles.getBody(isDark: isDark)
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+\$${roundupAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.getCaption(isDark: isDark)
                                  .copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(
    bool isDark,
    AnalyticsProvider analyticsProvider,
  ) {
    // Get real impact data from analytics provider
    final mealsProvided = analyticsProvider.mealsProvided;
    final studentsHelped = analyticsProvider.studentsHelped;
    final medicalVisits = analyticsProvider.medicalVisits;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Impact This Month',
            style: AppTextStyles.getTitle(isDark: isDark),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  isDark,
                  mealsProvided.toString(),
                  'Meals Provided',
                  Icons.restaurant,
                  AppColors.success,
                ),
              ),
              Expanded(
                child: _buildImpactItem(
                  isDark,
                  studentsHelped.toString(),
                  'Students Helped',
                  Icons.school,
                  AppColors.info,
                ),
              ),
              Expanded(
                child: _buildImpactItem(
                  isDark,
                  medicalVisits.toString(),
                  'Medical Visits',
                  Icons.local_hospital,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(
    bool isDark,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.getTitle(
            isDark: isDark,
          ).copyWith(color: color, fontSize: 20),
        ),
        Text(
          label,
          style: AppTextStyles.getCaption(isDark: isDark),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.warning.withValues(alpha: 0.08),
                  AppColors.warning.withValues(alpha: 0.03),
                ]
              : [
                  AppColors.warning.withValues(alpha: 0.06),
                  AppColors.warning.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: AppTextStyles.getTitle(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  isDark,
                  'Messages',
                  'Church communications',
                  Icons.message,
                  AppColors.info,
                  () => context.go('/church-messages'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  isDark,
                  'History',
                  'Giving history',
                  Icons.history,
                  AppColors.secondary,
                  () => context.go('/donation-history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  isDark,
                  'Settings',
                  'Roundup preferences',
                  Icons.settings,
                  AppColors.primary,
                  () => context.go('/donation-preferences'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  isDark,
                  'Bank',
                  'Account management',
                  Icons.account_balance,
                  AppColors.success,
                  () => context.go('/bank-accounts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedText(
    String text,
    TextStyle style,
    bool isDark,
    Color color,
  ) {
    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildActionCard(
    bool isDark,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 140, // Increased height to prevent overflow
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)]
                : [
                    color.withValues(alpha: 0.12),
                    color.withValues(alpha: 0.06),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            _buildAnimatedText(
              title,
              AppTextStyles.getBody(isDark: isDark).copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
              isDark,
              color,
            ),
            const SizedBox(height: 2),
            _buildAnimatedText(
              subtitle,
              AppTextStyles.getCaption(isDark: isDark).copyWith(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              isDark,
              color,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMessageTypeColor(String type) {
    switch (type) {
      case 'thank_you':
        return AppColors.success;
      case 'impact_update':
        return AppColors.info;
      case 'receipt':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getMessageTypeIcon(String type) {
    switch (type) {
      case 'thank_you':
        return Icons.favorite;
      case 'impact_update':
        return Icons.trending_up;
      case 'receipt':
        return Icons.receipt;
      default:
        return Icons.message;
    }
  }

  String _getMessageTypeLabel(String type) {
    switch (type) {
      case 'thank_you':
        return 'Thank You';
      case 'impact_update':
        return 'Impact Update';
      case 'receipt':
        return 'Receipt';
      default:
        return 'Message';
    }
  }

  IconData _getIconForMerchant(String merchantName) {
    final lowerMerchant = merchantName.toLowerCase();
    if (lowerMerchant.contains('starbucks') ||
        lowerMerchant.contains('coffee')) {
      return Icons.coffee;
    } else if (lowerMerchant.contains('gas') ||
        lowerMerchant.contains('shell') ||
        lowerMerchant.contains('exxon')) {
      return Icons.local_gas_station;
    } else if (lowerMerchant.contains('walmart') ||
        lowerMerchant.contains('target') ||
        lowerMerchant.contains('amazon')) {
      return Icons.shopping_cart;
    } else if (lowerMerchant.contains('restaurant') ||
        lowerMerchant.contains('chipotle') ||
        lowerMerchant.contains('mcdonalds')) {
      return Icons.restaurant;
    } else {
      return Icons.receipt;
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
}
