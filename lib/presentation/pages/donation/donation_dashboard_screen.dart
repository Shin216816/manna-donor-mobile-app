import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

/// Enhanced donation dashboard screen with comprehensive user information
/// Displays total donation stats, church information, preferences, and donation history
class DonationDashboardScreen extends StatefulWidget {
  const DonationDashboardScreen({super.key});

  @override
  State<DonationDashboardScreen> createState() =>
      _DonationDashboardScreenState();
}

class _DonationDashboardScreenState extends State<DonationDashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
    });

    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final churchProvider = Provider.of<ChurchProvider>(
        context,
        listen: false,
      );
      final roundupProvider = Provider.of<RoundupProvider>(
        context,
        listen: false,
      );

      // Data should already be loaded from cache during initial fetch
      // No need to fetch data here as it should be available from cache
      // The providers will automatically load from cache if data is missing
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final bankProvider = Provider.of<BankProvider>(context);
    final churchProvider = Provider.of<ChurchProvider>(context);
    final roundupProvider = Provider.of<RoundupProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppHeader(title: 'Donation Dashboard'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            RefreshIndicator(
              onRefresh: () async {
                final bankProvider = Provider.of<BankProvider>(
                  context,
                  listen: false,
                );
                final churchProvider = Provider.of<ChurchProvider>(
                  context,
                  listen: false,
                );
                final roundupProvider = Provider.of<RoundupProvider>(
                  context,
                  listen: false,
                );

                // Fetch fresh data from backend (bypass cache)
                await Future.wait([
                  bankProvider.refreshDashboard(),
                  bankProvider.refreshDonationHistory(),
                  bankProvider.refreshDonationSummary(),
                  churchProvider.refreshAvailableChurches(),
                  roundupProvider.refreshEnhancedRoundupStatus(),
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
                        verticalOffset: 20.0,
                        child: FadeInAnimation(child: widget),
                      ),
                      children: [
                        // User Welcome Section
                        _buildUserWelcomeSection(authProvider, isDark),
                        const SizedBox(height: 24),

                        // Total Donation Stats
                        _buildTotalDonationStats(bankProvider, isDark),
                        const SizedBox(height: 24),

                        // Church Information
                        _buildChurchInformation(
                          authProvider,
                          churchProvider,
                          isDark,
                        ),
                        const SizedBox(height: 24),

                        // Donation Preferences
                        _buildDonationPreferences(bankProvider, isDark),
                        const SizedBox(height: 24),

                        // Roundup Status
                        _buildRoundupStatus(roundupProvider, isDark),
                        const SizedBox(height: 24),

                        // Recent Donations
                        _buildRecentDonations(bankProvider, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            size: 12,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading dashboard...',
                          style: AppTextStyles.getBodySmall(isDark: isDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserWelcomeSection(AuthProvider authProvider, bool isDark) {
    final user = authProvider.user;
    final userName = user?.firstName ?? 'User';

    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.sp),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60.sp,
            height: 60.sp,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30.sp),
            ),
            child: Icon(Icons.person, color: Colors.white, size: 30.sp),
          ),
          SizedBox(width: 16.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName!',
                  style: AppTextStyles.titleMedium(
                    isDark: false,
                    color: Colors.white,
                    weight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  'Here\'s your donation overview',
                  style: AppTextStyles.bodyMedium(
                    isDark: false,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalDonationStats(BankProvider bankProvider, bool isDark) {
    final dashboard = bankProvider.dashboard;
    final donationSummary = bankProvider.donationSummary;
    final donationHistory = bankProvider.donationHistory;

    // Calculate stats from available data
    final totalAmount =
        dashboard?['total_amount'] ??
        donationSummary?['total_amount'] ??
        donationHistory.fold<double>(
          0.0,
          (sum, donation) => sum + donation.amount,
        );

    final totalDonations =
        dashboard?['total_donations'] ??
        donationSummary?['total_donations'] ??
        donationHistory.length;

    final firstDonationDate = donationHistory.isNotEmpty
        ? donationHistory.last.date
        : null;

    final lastDonationDate = donationHistory.isNotEmpty
        ? donationHistory.first.date
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Donation Stats',
          style: AppTextStyles.titleMedium(
            isDark: isDark,
            weight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDark,
                'Total Amount',
                '\$${totalAmount.toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.success,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildStatCard(
                isDark,
                'Total Donations',
                '$totalDonations',
                Icons.favorite,
                AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDark,
                'First Donation',
                firstDonationDate != null
                    ? DateFormat('MMM dd, yyyy').format(firstDonationDate)
                    : 'N/A',
                Icons.calendar_today,
                AppColors.warning,
              ),
            ),
            SizedBox(width: 12.sp),
            Expanded(
              child: _buildStatCard(
                isDark,
                'Last Donation',
                lastDonationDate != null
                    ? DateFormat('MMM dd, yyyy').format(lastDonationDate)
                    : 'N/A',
                Icons.update,
                AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.getBodySmall(
                    isDark: isDark,
                    color:
                        (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                            .withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          Text(
            value,
            style: AppTextStyles.titleSmall(
              isDark: isDark,
              weight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChurchInformation(
    AuthProvider authProvider,
    ChurchProvider churchProvider,
    bool isDark,
  ) {
    final userChurchIds = authProvider.userChurchIds;
    final availableChurches = churchProvider.availableChurches;

    final userChurches = availableChurches
        .where((church) => userChurchIds.contains(church.id.toString()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Church',
          style: AppTextStyles.titleMedium(
            isDark: isDark,
            weight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        if (userChurches.isEmpty)
          Container(
            padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(
                color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.church,
                  color:
                      (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                          .withValues(alpha: 0.5),
                  size: 24.sp,
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text(
                    'No churches selected',
                    style: AppTextStyles.bodyMedium(
                      isDark: isDark,
                      color:
                          (isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.onSurface)
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...userChurches.map(
            (church) => Container(
              margin: EdgeInsets.only(bottom: 12.sp),
              padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(12.sp),
                border: Border.all(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.sp,
                    height: 48.sp,
                    decoration: BoxDecoration(
                      color:
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24.sp),
                    ),
                    child: Icon(
                      Icons.church,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          church.name,
                          style: AppTextStyles.bodyMedium(
                            isDark: isDark,
                            weight: FontWeight.w600,
                          ),
                        ),
                        if (church.city != null) ...[
                          SizedBox(height: 4.sp),
                          Text(
                            '${church.city}${church.state != null ? ', ${church.state}' : ''}',
                            style: AppTextStyles.getBodySmall(
                              isDark: isDark,
                              color:
                                  (isDark
                                          ? AppColors.darkOnSurface
                                          : AppColors.onSurface)
                                      .withValues(alpha: 0.7),
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
      ],
    );
  }

  Widget _buildDonationPreferences(BankProvider bankProvider, bool isDark) {
    final preferences = bankProvider.preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Donation Preferences',
          style: AppTextStyles.titleMedium(
            isDark: isDark,
            weight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(
              color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  .withValues(alpha: 0.1),
            ),
          ),
          child: preferences != null
              ? Column(
                  children: [
                    _buildPreferenceRow(
                      isDark,
                      'Frequency',
                      preferences.frequency,
                      Icons.schedule,
                    ),
                    SizedBox(height: 12.sp),
                    _buildPreferenceRow(
                      isDark,
                      'Multiplier',
                      preferences.multiplier,
                      Icons.trending_up,
                    ),
                    SizedBox(height: 12.sp),
                    _buildPreferenceRow(
                      isDark,
                      'Status',
                      preferences.pause ? 'Paused' : 'Active',
                      preferences.pause
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: preferences.pause
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    SizedBox(height: 12.sp),
                    _buildPreferenceRow(
                      isDark,
                      'Cover Fees',
                      preferences.coverProcessingFees ? 'Yes' : 'No',
                      Icons.payment,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color:
                          (isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.onSurface)
                              .withValues(alpha: 0.5),
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Text(
                        'No preferences set',
                        style: AppTextStyles.bodyMedium(
                          isDark: isDark,
                          color:
                              (isDark
                                      ? AppColors.darkOnSurface
                                      : AppColors.onSurface)
                                  .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow(
    bool isDark,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              color ??
              (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  .withValues(alpha: 0.7),
          size: 20.sp,
        ),
        SizedBox(width: 12.sp),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(
              isDark: isDark,
              color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            isDark: isDark,
            weight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRoundupStatus(RoundupProvider roundupProvider, bool isDark) {
    final thisMonthData = roundupProvider.thisMonthRoundup;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month\'s Roundup',
          style: AppTextStyles.titleMedium(
            isDark: isDark,
            weight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.1),
                AppColors.success.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48.sp,
                height: 48.sp,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24.sp),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.success,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Roundup',
                      style: AppTextStyles.bodyMedium(
                        isDark: isDark,
                        weight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      '\$${thisMonthData?['totalAmount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: AppTextStyles.titleMedium(
                        isDark: isDark,
                        weight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      '${thisMonthData?['totalDonations'] ?? 0} donations',
                      style: AppTextStyles.getBodySmall(
                        isDark: isDark,
                        color:
                            (isDark
                                    ? AppColors.darkOnSurface
                                    : AppColors.onSurface)
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDonations(BankProvider bankProvider, bool isDark) {
    final recentDonations = bankProvider.donationHistory.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Donations',
              style: AppTextStyles.titleMedium(
                isDark: isDark,
                weight: FontWeight.bold,
              ),
            ),
            if (bankProvider.donationHistory.isNotEmpty)
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: Text(
                  'View All',
                  style: AppTextStyles.getBodySmall(
                    isDark: isDark,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16.sp),
        if (recentDonations.isEmpty)
          Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(
                color: (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                    .withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color:
                      (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                          .withValues(alpha: 0.5),
                  size: 24.sp,
                ),
                SizedBox(width: 12.sp),
                Expanded(
                  child: Text(
                    'No donation history yet',
                    style: AppTextStyles.bodyMedium(
                      isDark: isDark,
                      color:
                          (isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.onSurface)
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...recentDonations.map(
            (donation) => Container(
              margin: EdgeInsets.only(bottom: 8.sp),
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(
                  color:
                      (isDark ? AppColors.darkOnSurface : AppColors.onSurface)
                          .withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.sp,
                    height: 40.sp,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20.sp),
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: AppColors.success,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donation.churchName ?? 'Unknown Church',
                          style: AppTextStyles.bodyMedium(
                            isDark: isDark,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.sp),
                        Text(
                          DateFormat('MMM dd, yyyy').format(donation.date),
                          style: AppTextStyles.getBodySmall(
                            isDark: isDark,
                            color:
                                (isDark
                                        ? AppColors.darkOnSurface
                                        : AppColors.onSurface)
                                    .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${donation.amount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium(
                      isDark: isDark,
                      weight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
