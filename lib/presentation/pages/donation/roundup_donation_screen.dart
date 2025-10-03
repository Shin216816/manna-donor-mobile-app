import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

class RoundupDonationScreen extends StatefulWidget {
  const RoundupDonationScreen({super.key});

  @override
  State<RoundupDonationScreen> createState() => _RoundupDonationScreenState();
}

class _RoundupDonationScreenState extends State<RoundupDonationScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _realTransactions = [];
  double _totalRoundup = 0.0;
  bool _isProcessing = false;
  bool _showSuccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _loadRealTransactionData();
  }

  Future<void> _loadRealTransactionData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );
              await roundupProvider.smartFetchRoundupTransactions();

      if (mounted) {
        setState(() {
          _realTransactions = roundupProvider.roundupTransactions;
          _totalRoundup = _realTransactions.fold(
            0.0,
            (sum, transaction) => sum + (transaction['roundup_amount'] ?? 0.0),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processRoundupDonation() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
      _showSuccess = true;
    });

    _confettiController.play();

    // Reset after showing success
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSuccess = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Roundup Donations'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.sp, 12.sp, 24.sp, 24.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Confetti widget
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 2,
                      emissionFrequency: 0.05,
                      numberOfParticles: 50,
                      gravity: 0.05,
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                        Colors.green,
                        Colors.blue,
                      ],
                    ),
                  ),

                  // Main roundup card
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildRoundupCard(isDark),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Recent transactions
                  _buildRecentTransactions(isDark),

                  const SizedBox(height: 16),

                  // Donation button
                  _buildDonationButton(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundupCard(bool isDark) {
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
          // Icon and title
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 40,
                    color: AppColors.roundupPrimary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Text(
            'Total Roundup Available',
            style: AppTextStyles.getRoundupSubtitle(isDark: isDark),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          Text(
            '\$${_totalRoundup.toStringAsFixed(2)}',
            style: AppTextStyles.getRoundupAmount(isDark: isDark),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'From ${_realTransactions.length} recent transactions',
            style: AppTextStyles.getBodySmall(isDark: isDark).copyWith(
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

  Widget _buildRecentTransactions(bool isDark) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              EnhancedLoadingWidget(
                type: LoadingType.spinner,
                message: 'Processing donation...',
                color: AppColors.primary,
                size: 40,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading transactions...',
                style: AppTextStyles.getBody(isDark: isDark),
              ),
            ],
          ),
        ),
      );
    }

    if (_realTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions found',
                style: AppTextStyles.getTitle(isDark: isDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Link your bank account to see roundup transactions',
                style: AppTextStyles.getBody(isDark: isDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: AppTextStyles.getTitle(isDark: isDark),
          ),
          const SizedBox(height: 16),
          ...List.generate(_realTransactions.length, (index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildTransactionCard(
                    _realTransactions[index],
                    isDark,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction, bool isDark) {
    // Extract real transaction data
    final merchant = transaction['merchant'] ?? 'Unknown Merchant';
    final amount = transaction['amount']?.toDouble() ?? 0.0;
    final roundupAmount = transaction['roundup_amount']?.toDouble() ?? 0.0;
    final date = transaction['date'] ?? DateTime.now().toString();

    // Determine icon based on merchant name
    IconData getIconForMerchant(String merchantName) {
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
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.roundupPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              getIconForMerchant(merchant),
              color: AppColors.roundupPrimary,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Transaction details
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
                const SizedBox(height: 4),
                Text(
                  _formatDate(DateTime.tryParse(date) ?? DateTime.now()),
                  style: AppTextStyles.getCaption(isDark: isDark),
                ),
              ],
            ),
          ),

          // Amount and roundup
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${amount.toStringAsFixed(2)}',
                style: AppTextStyles.getBody(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${roundupAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: AppColors.roundupPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationButton(bool isDark) {
    if (_showSuccess) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            Text(
              'Donation Successful!',
              style: AppTextStyles.getTitle(
                isDark: isDark,
              ).copyWith(color: AppColors.success),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your roundup donation of \$${_totalRoundup.toStringAsFixed(2)} has been processed.',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ModernButton(
      text: 'Donate \$${_totalRoundup.toStringAsFixed(2)}',
      onPressed: _isProcessing ? null : _processRoundupDonation,
      isLoading: _isProcessing,
    );
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

  @override
  void dispose() {
    _confettiController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}
