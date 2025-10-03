import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';


class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];
  double _totalRoundup = 0.0;
  double _totalSpent = 0.0;
  DateTime? _nextRoundupDate;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer data loading to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
      final bankProvider = Provider.of<BankProvider>(context, listen: false);

      // Try to load from cache first for immediate display
      await roundupProvider.smartFetchRoundupTransactions();
      
      if (mounted) {
        setState(() {
          _transactions = roundupProvider.roundupTransactions;
          if (_transactions.isNotEmpty) {
          } else {
          }
          _calculateTotals();
          _calculateNextRoundupDate();
          _isLoading = false;
        });
      }

      // Load additional data in background
      _loadDataInBackground(roundupProvider, bankProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load transactions: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh data by fetching fresh data from server and updating cache
  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
      final bankProvider = Provider.of<BankProvider>(context, listen: false);

      // Force refresh from server (bypass cache) and update cache with fresh data
      await Future.wait([
        roundupProvider.refreshRoundupTransactions(),
        roundupProvider.refreshEnhancedRoundupStatus(),
        roundupProvider.refreshRoundupSettings(),
        bankProvider.refreshBankAccounts(),
      ]);
      
      if (mounted) {
        setState(() {
          _transactions = roundupProvider.roundupTransactions;
          _calculateTotals();
          _calculateNextRoundupDate();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to refresh transactions: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Load data in background without blocking UI
  void _loadDataInBackground(
    RoundupProvider roundupProvider,
    BankProvider bankProvider,
  ) {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        // Fetch fresh data in background
        await Future.wait([
          roundupProvider.smartFetchRoundupTransactions(), // Use cache-first
          roundupProvider.smartFetchEnhancedRoundupStatus(),
          roundupProvider.smartFetchRoundupSettings(),
          bankProvider.smartFetchPreferences(),
        ]);

        if (mounted) {
          setState(() {
            _transactions = roundupProvider.roundupTransactions;
            _calculateTotals();
            _calculateNextRoundupDate();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load transactions: $e';
          });
        }
      }
    });
  }

  void _calculateTotals() {
    _totalRoundup = _transactions.fold(
      0.0,
      (sum, transaction) => sum + (transaction['roundup_amount'] ?? 0.0),
    );

    _totalSpent = _transactions.fold(
      0.0,
      (sum, transaction) => sum + (transaction['amount'] ?? 0.0),
    );
  }

  void _calculateNextRoundupDate() {
    final roundupProvider = Provider.of<RoundupProvider>(
      context,
      listen: false,
    );

    // Use enhanced roundup status for accurate next transfer date (same as enhanced dashboard)
    if (roundupProvider.enhancedRoundupStatus != null) {
      final enhancedStatus = roundupProvider.enhancedRoundupStatus!;
      _nextRoundupDate = enhancedStatus.nextTransferDate;
    } else {
      // Fallback to roundup settings if enhanced status is not available
      if (roundupProvider.roundupSettings != null) {
        final settings = roundupProvider.roundupSettings!;
        final isPaused = settings['pause'] ?? false;

        if (!isPaused) {
          final frequency = settings['frequency'] ?? 'monthly';
          final nextDate = _calculateNextScheduleDate(frequency);
          _nextRoundupDate = nextDate;
        } else {
          _nextRoundupDate = null;
        }
      } else {
        _nextRoundupDate = null;
      }
    }
  }

  DateTime _calculateNextScheduleDate(String frequency) {
    final now = DateTime.now();

    switch (frequency.toLowerCase()) {
      case 'biweekly':
        // Next bi-week (every 2 weeks)
        return now.add(const Duration(days: 14));
      case 'monthly':
        // Next month same day
        final nextMonth = DateTime(now.year, now.month + 1, now.day);
        return nextMonth;
      default:
        // Default to monthly
        final nextMonth = DateTime(now.year, now.month + 1, now.day);
        return nextMonth;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(
        title: 'Roundup Transactions',
        showThemeToggle: false,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: Icon(
              Icons.refresh,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Stack(
        children: [
          // Main content - always visible
          SafeArea(
            child: _error != null
                ? _buildErrorState(isDark)
                : _buildContent(isDark),
          ),
          // Small loading indicator at top if data is still loading
          if (_isLoading)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: LoadingWave(
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          size: 12,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating transactions...',
                        style: AppTextStyles.getBodySmall(isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            SizedBox(height: 16.sp),
            Text(
              'Failed to load transactions',
              style: AppTextStyles.getTitle(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.sp),
            Text(
              _error!,
              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.sp),
            ElevatedButton(
              onPressed: _refreshData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.sp,
                  vertical: 8.sp,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Consumer<RoundupProvider>(
      builder: (context, roundupProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            final bankProvider = Provider.of<BankProvider>(context, listen: false);
            
            // Fetch fresh data from backend (bypass cache)
            await Future.wait([
              roundupProvider.refreshRoundupTransactionsCache(), // Use the improved method
              roundupProvider.refreshEnhancedRoundupStatus(),
              bankProvider.refreshBankAccounts(),
            ]);
            
            // Update local state
            if (mounted) {
              setState(() {
                _transactions = roundupProvider.roundupTransactions;
                _calculateTotals();
                _calculateNextRoundupDate();
              });
            }
          },
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  AppConstants.headerHeight + AppConstants.pagePadding,
                  AppConstants.pagePadding,
                  AppConstants.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Cards
                    _buildSummaryCards(isDark),
                    SizedBox(height: 24.sp),

                    // Transactions List
                    _buildTransactionsList(isDark),
                  ],
                ),
              ),
              // Loading overlay when refreshing
              if (roundupProvider.loading)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LoadingWave(
                        message: 'Refreshing transactions...',
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        size: 40,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Column(
      children: [
        // Total Roundup Card
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Container(
              padding: EdgeInsets.all(20.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.roundupPrimary,
                    AppColors.roundupPrimary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.roundupPrimary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(12.sp),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.volunteer_activism,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 16.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Roundup',
                              style: AppTextStyles.getBody(isDark: false)
                                  .copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14.sp,
                                  ),
                            ),
                            Text(
                              _formatCurrency(_totalRoundup),
                              style: AppTextStyles.getTitle(isDark: false)
                                  .copyWith(
                                    color: Colors.white,
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.sp),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          isDark: false,
                          icon: Icons.shopping_cart,
                          label: 'Total Spent',
                          value: _formatCurrency(_totalSpent),
                        ),
                      ),
                      SizedBox(width: 16.sp),
                      Expanded(
                        child: _buildSummaryItem(
                          isDark: false,
                          icon: Icons.receipt_long,
                          label: 'Transactions',
                          value: _transactions.length.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        SizedBox(height: 16.sp),

        // Next Roundup Date Card
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(_slideAnimation),
            child: Container(
              padding: EdgeInsets.all(20.sp),
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
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.schedule,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Roundup Schedule',
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          _nextRoundupDate != null
                              ? DateFormat(
                                  'EEEE, MMM dd, yyyy',
                                ).format(_nextRoundupDate!)
                              : 'Not scheduled',
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                        if (_nextRoundupDate != null) ...[
                          SizedBox(height: 4.sp),
                          Text(
                            'Your roundups will be processed on this date',
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            SizedBox(width: 4.sp),
            Text(
              label,
              style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.sp),
        Text(
          value,
          style: AppTextStyles.getBody(isDark: isDark).copyWith(
            color: isDark ? Colors.white : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: AppTextStyles.getTitle(isDark: isDark),
            ),
            Text(
              '${_transactions.length} transactions',
              style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.sp),

        if (_transactions.isEmpty)
          _buildEmptyState(isDark)
        else
          ...List.generate(_transactions.length, (index) {
            final transaction = _transactions[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: _buildTransactionCard(transaction, isDark, index),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(32.sp),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48.sp,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
          SizedBox(height: 16.sp),
          Text(
            'No roundup transactions yet',
            style: AppTextStyles.getBody(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8.sp),
          Text(
            'Your roundup transactions will appear here once you make purchases with your linked bank account',
            style: AppTextStyles.getCaption(isDark: isDark).copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    bool isDark,
    int index,
  ) {
    final merchant = transaction['merchant'] ?? 'Unknown Merchant';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final roundupAmount = transaction['roundup_amount']?.toDouble() ?? 0.0;
    final date = transaction['date'] ?? DateTime.now().toString();
    final category = transaction['category'] ?? 'General';
    final accountName = transaction['account_name'] ?? 'Unknown Account';

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetails(transaction, isDark),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48.sp,
                                                      height: 40.sp,
                      decoration: BoxDecoration(
                        color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: AppColors.roundupPrimary,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant,
                            style: AppTextStyles.getBody(
                              isDark: isDark,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            category,
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            accountName,
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            _formatDate(date),
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(amount),
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.sp),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.sp,
                            vertical: 4.sp,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.roundupPrimary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${_formatCurrency(roundupAmount)}',
                            style: AppTextStyles.getCaption(isDark: isDark)
                                .copyWith(
                                  color: AppColors.roundupPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTransactionDetailsSheet(transaction, isDark),
    );
  }

  Widget _buildTransactionDetailsSheet(
    Map<String, dynamic> transaction,
    bool isDark,
  ) {
    final merchant = transaction['merchant'] ?? 'Unknown Merchant';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final roundupAmount = transaction['roundup_amount']?.toDouble() ?? 0.0;
    final date = transaction['date'] ?? DateTime.now().toString();
    final category = transaction['category'] ?? 'General';
    final accountName = transaction['account_name'] ?? 'Unknown Account';
    final transactionId = transaction['transaction_id'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.sp,
                  height: 4.sp,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2.sp),
                  ),
                ),
              ),
              SizedBox(height: 24.sp),

              // Transaction header
              Row(
                children: [
                  Container(
                    width: 56.sp,
                                                    height: 40.sp,
                    decoration: BoxDecoration(
                      color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: AppColors.roundupPrimary,
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchant,
                          style: AppTextStyles.getTitle(
                            isDark: isDark,
                          ).copyWith(fontSize: 20.sp),
                        ),
                        Text(
                          category,
                          style: AppTextStyles.getBody(isDark: isDark).copyWith(
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
              SizedBox(height: 24.sp),

              // Transaction details
              _buildDetailRow(
                'Purchase Amount',
                _formatCurrency(amount),
                isDark,
              ),
              _buildDetailRow(
                'Roundup Amount',
                _formatCurrency(roundupAmount),
                isDark,
                isRoundup: true,
              ),
              _buildDetailRow('Account', accountName, isDark),
              _buildDetailRow('Date', _formatDate(date), isDark),
              _buildDetailRow('Category', category, isDark),
              _buildDetailRow('Transaction ID', transactionId, isDark),

              SizedBox(height: 24.sp),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 40.sp,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 8.sp),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isRoundup = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.getBody(isDark: isDark).copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.getBody(isDark: isDark).copyWith(
              fontWeight: FontWeight.w600,
              color: isRoundup ? AppColors.roundupPrimary : null,
            ),
          ),
        ],
      ),
    );
  }
}
