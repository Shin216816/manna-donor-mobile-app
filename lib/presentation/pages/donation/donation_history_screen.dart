import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedFilter = 'all';
  String _selectedSort = 'date_desc';
  bool _showScrollToTop = false;
  bool _isLoading = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController.repeat(reverse: true);

    _scrollController.addListener(_onScroll);
    // Defer data loading to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonationHistory();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonationHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);

      // Load data in background without blocking UI
      _loadDataInBackground(bankProvider);

      // Show content immediately
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Error will be handled by the provider
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load data in background without blocking UI
  void _loadDataInBackground(BankProvider bankProvider) {
    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        await bankProvider.smartFetchDonationHistory();
      } catch (e) {
        // Error will be handled by the provider
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 300) {
      if (!_showScrollToTop) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _showScrollToTop = true);
          }
        });
      }
    } else {
      if (_showScrollToTop) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _showScrollToTop = false);
          }
        });
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  List<DonationHistory> _getFilteredDonations(List<DonationHistory> donations) {
    List<DonationHistory> filtered = List.from(donations);

    if (_selectedFilter != 'all') {
      filtered = filtered.where((donation) {
        return donation.status.toLowerCase() == _selectedFilter;
      }).toList();
    }

    // Date filtering removed as requested

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((donation) {
        final amount = donation.amount.toString();
        final status = donation.status.toLowerCase();

        return amount.contains(searchTerm) || status.contains(searchTerm);
      }).toList();
    }

    switch (_selectedSort) {
      case 'date_desc':
        filtered.sort((a, b) {
          final dateA = a.createdAt ?? a.executedAt ?? DateTime(1900);
          final dateB = b.createdAt ?? b.executedAt ?? DateTime(1900);
          return dateB.compareTo(dateA);
        });
        break;
      case 'date_asc':
        filtered.sort((a, b) {
          final dateA = a.createdAt ?? a.executedAt ?? DateTime(1900);
          final dateB = b.createdAt ?? b.executedAt ?? DateTime(1900);
          return dateA.compareTo(dateB);
        });
        break;
      case 'amount_desc':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_asc':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppHeader(title: 'Donation History'),
      drawer: AppDrawer(),
      body: SafeArea(
        child: Consumer3<BankProvider, ChurchProvider, AuthProvider>(
          builder: (context, bankProvider, churchProvider, authProvider, _) {
            final donations = bankProvider.donationHistory;
            final filteredDonations = _getFilteredDonations(donations);

            if (bankProvider.error != null && donations.isEmpty) {
              return _buildErrorState(bankProvider, isDark);
            }

            return Stack(
              children: [
                // Main content
                NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    _onScroll();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(bottom: 100.sp),
                    child: Column(
                      children: [
                        // Header section
                        _buildHeaderSection(isDark),

                        // Statistics cards
                        _buildStatisticsCards(filteredDonations, isDark),
                        SizedBox(height: 12.sp),

                        // Donations list
                        if (filteredDonations.isEmpty)
                          _buildEmptyState(isDark)
                        else
                          _buildDonationsList(filteredDonations, isDark),
                      ],
                    ),
                  ),
                ),

                // Scroll to top button
                if (_showScrollToTop)
                  Positioned(
                    bottom: 20.sp,
                    right: 20.sp,
                    child:
                        FloatingActionButton(
                              onPressed: _scrollToTop,
                              backgroundColor: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                            ),
                  ),
                // Small loading indicator at top if data is still loading
                if (_isLoading || bankProvider.loading)
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
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surface,
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
                              'Updating donation history...',
                              style: AppTextStyles.getBodySmall(isDark: isDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BankProvider provider, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120.sp,
                  height: 120.sp,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.red.withValues(alpha: 0.2),
                              Colors.red.withValues(alpha: 0.1),
                            ]
                          : [
                              Colors.red.withValues(alpha: 0.2),
                              Colors.red.withValues(alpha: 0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(60.sp),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 60.sp,
                    color: Colors.red,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                ),
            SizedBox(height: 32.sp),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.headlineSmall(
                color: AppColors.getOnSurfaceColor(isDark),
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
            SizedBox(height: 12.sp),
            Text(
              'We couldn\'t load your donation history',
              style: AppTextStyles.bodyLarge(
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.7),
                isDark: isDark,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
            SizedBox(height: 32.sp),
            Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16.sp),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loadDonationHistory,
                      borderRadius: BorderRadius.circular(16.sp),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.sp,
                          vertical: 16.sp,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.sp),
                            Text(
                              'Try Again',
                              style: AppTextStyles.titleMedium(
                                color: Colors.white,
                                isDark: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Enhanced search bar with glassmorphism effect
          Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1F2937).withValues(alpha: 0.8),
                            const Color(0xFF111827).withValues(alpha: 0.9),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.sp),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.9),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1.5,
                  ),
                ),
                child: ModernInputField(
                  controller: _searchController,
                  label: '',
                  hint: 'Search by amount, status or church...',
                  prefixIcon: Icons.search,
                  isDark: isDark,
                  onChanged: (value) => setState(() {}),
                ),
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: -0.3, end: 0)
              .then(delay: 100.ms)
              .shimmer(duration: 1000.ms),

          SizedBox(height: 16.sp),

          // Enhanced filter chips with modern design
          SizedBox(
            height: 30.sp,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 4.sp),
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 400),
                childAnimationBuilder: (widget) => SlideAnimation(
                  horizontalOffset: 30.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  _buildEnhancedFilterChip(
                    'All',
                    'all',
                    Icons.list_alt,
                    isDark,
                  ),
                  SizedBox(width: 12.sp),
                  _buildEnhancedFilterChip(
                    'Success',
                    'completed',
                    Icons.check_circle,
                    isDark,
                  ),
                  SizedBox(width: 12.sp),
                  _buildEnhancedFilterChip(
                    'Pending',
                    'pending',
                    Icons.schedule,
                    isDark,
                  ),
                  SizedBox(width: 12.sp),
                  _buildEnhancedFilterChip(
                    'Failed',
                    'failed',
                    Icons.error,
                    isDark,
                  ),
                  SizedBox(width: 16.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFilterChip(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.darkPrimary,
                          AppColors.darkPrimary.withValues(alpha: 0.8),
                        ]
                      : [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF374151).withValues(alpha: 0.6),
                          const Color(0xFF1F2937).withValues(alpha: 0.8),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.8),
                          const Color(0xFFF9FAFB).withValues(alpha: 0.9),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.6)
                : isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(3.sp),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark ? AppColors.darkPrimary : AppColors.primary)
                          .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkPrimary : AppColors.primary),
                size: 12.sp,
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              label,
              style:
                  AppTextStyles.bodySmall(
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.7),
                    isDark: isDark,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11.sp,
                  ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
    );
  }

  Widget _buildStatisticsCards(List<DonationHistory> donations, bool isDark) {
    final totalAmount = donations.fold<double>(
      0.0,
      (sum, donation) => sum + donation.amount,
    );
    final successCount = donations
        .where((d) => d.status.toLowerCase() == 'completed')
        .length;
    final pendingCount = donations
        .where((d) => d.status.toLowerCase() == 'pending')
        .length;
    final failedCount = donations
        .where((d) => d.status.toLowerCase() == 'failed')
        .length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp),
      child: Column(
        children: [
          // Main summary card
          Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.sp),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                        : [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.sp),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark ? AppColors.darkPrimary : AppColors.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          child: Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 16.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Donations',
                                style: AppTextStyles.bodyMedium(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  isDark: false,
                                ),
                              ),
                              SizedBox(height: 4.sp),
                              Text(
                                '\$${totalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.headlineMedium(
                                  color: Colors.white,
                                  isDark: false,
                                ).copyWith(fontWeight: FontWeight.bold),
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
                          child: _buildStatItem(
                            'Success',
                            successCount.toString(),
                            Icons.check_circle,
                            Colors.green,
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: _buildStatItem(
                            'Pending',
                            pendingCount.toString(),
                            Icons.schedule,
                            Colors.orange,
                            isDark,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: _buildStatItem(
                            'Failed',
                            failedCount.toString(),
                            Icons.error,
                            Colors.red,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),

          SizedBox(height: 16.sp),

          // Sort dropdown
          Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.sp,
                  vertical: 12.sp,
                ),
                decoration: BoxDecoration(
                  color: AppColors.getSurfaceColor(isDark),
                  borderRadius: BorderRadius.circular(16.sp),
                  border: Border.all(
                    color: AppColors.getOutlineColor(
                      isDark,
                    ).withValues(alpha: 0.2),
                  ),
                ),
                child: Container(
                  height: 40.sp,
                  child: DropdownButtonFormField<String>(
                    value: _selectedSort,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.sp,
                        vertical: 8.sp,
                      ),
                      filled: true,
                      fillColor: AppColors.getSurfaceColor(isDark),
                      prefixIcon: Icon(
                        Icons.sort,
                        color: AppColors.getOnSurfaceColor(
                          isDark,
                        ).withValues(alpha: 0.7),
                        size: 16.sp,
                      ),
                    ),
                    style: AppTextStyles.bodyMedium(
                      color: AppColors.getOnSurfaceColor(isDark),
                      isDark: isDark,
                    ).copyWith(fontSize: 12.sp),
                    dropdownColor: AppColors.getSurfaceColor(isDark),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.getOnSurfaceColor(
                        isDark,
                      ).withValues(alpha: 0.7),
                      size: 16.sp,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'date_desc',
                        child: Text(
                          'Newest First',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.getOnSurfaceColor(isDark),
                            isDark: isDark,
                          ).copyWith(fontSize: 12.sp),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'date_asc',
                        child: Text(
                          'Oldest First',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.getOnSurfaceColor(isDark),
                            isDark: isDark,
                          ).copyWith(fontSize: 12.sp),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'amount_desc',
                        child: Text(
                          'Highest Amount',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.getOnSurfaceColor(isDark),
                            isDark: isDark,
                          ).copyWith(fontSize: 12.sp),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'amount_asc',
                        child: Text(
                          'Lowest Amount',
                          style: AppTextStyles.bodyMedium(
                            color: AppColors.getOnSurfaceColor(isDark),
                            isDark: isDark,
                          ).copyWith(fontSize: 12.sp),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedSort = value!),
                  ),
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.sp),
          Text(
            value,
            style: AppTextStyles.titleMedium(
              color: color,
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.sp),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              color: color.withValues(alpha: 0.8),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationsList(List<DonationHistory> donations, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      child: AnimationLimiter(
        child: Column(
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 600),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 30.0,
              child: FadeInAnimation(
                child: ScaleAnimation(scale: 0.95, child: widget),
              ),
            ),
            children: List.generate(
              donations.length,
              (index) =>
                  _buildEnhancedDonationCard(donations[index], isDark, index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedDonationCard(
    DonationHistory donation,
    bool isDark,
    int index,
  ) {
    final statusColor = _getStatusColor(donation.status);
    final statusIcon = _getStatusIcon(donation.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1F2937).withValues(alpha: 0.8),
                  const Color(0xFF111827).withValues(alpha: 0.95),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  const Color(0xFFF9FAFB).withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.sp),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : statusColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.8),
            blurRadius: 2,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDonationDetails(donation, isDark),
          borderRadius: BorderRadius.circular(20.sp),
          splashColor: statusColor.withValues(alpha: 0.1),
          highlightColor: statusColor.withValues(alpha: 0.05),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                Row(
                  children: [
                    // Enhanced status icon with more visual appeal
                    Hero(
                      tag: 'donation_${donation.id}',
                      child: Container(
                        width: 48.sp,
                        height: 48.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor,
                              statusColor.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14.sp),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: EdgeInsets.all(2.sp),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18.sp),
                          ),
                          child: Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    // Enhanced content section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Amount with currency animation effect
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '\$',
                                  style:
                                      AppTextStyles.headlineSmall(
                                        color: statusColor,
                                        isDark: isDark,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 20.sp,
                                      ),
                                ),
                                TextSpan(
                                  text: donation.amount.toStringAsFixed(2),
                                  style:
                                      AppTextStyles.headlineSmall(
                                        color: AppColors.getOnSurfaceColor(
                                          isDark,
                                        ),
                                        isDark: isDark,
                                      ).copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20.sp,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8.sp),
                          // Enhanced status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.sp,
                              vertical: 4.sp,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  statusColor.withValues(alpha: 0.15),
                                  statusColor.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16.sp),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5.sp,
                                  height: 5.sp,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.sp),
                                Text(
                                  donation.statusDisplay.toUpperCase(),
                                  style:
                                      AppTextStyles.bodySmall(
                                        color: statusColor,
                                        isDark: isDark,
                                      ).copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11.sp,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Enhanced date section
                    Container(
                      padding: EdgeInsets.all(12.sp),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.sp),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM dd').format(
                              donation.createdAt ??
                                  donation.executedAt ??
                                  DateTime.now(),
                            ),
                            style:
                                AppTextStyles.bodyMedium(
                                  color: AppColors.getOnSurfaceColor(isDark),
                                  isDark: isDark,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                          ),
                          SizedBox(height: 2.sp),
                          Text(
                            DateFormat('yyyy').format(
                              donation.createdAt ??
                                  donation.executedAt ??
                                  DateTime.now(),
                            ),
                            style: AppTextStyles.bodySmall(
                              color: AppColors.getOnSurfaceColor(
                                isDark,
                              ).withValues(alpha: 0.6),
                              isDark: isDark,
                            ).copyWith(fontSize: 12.sp),
                          ),
                          SizedBox(height: 6.sp),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.sp,
                              vertical: 3.sp,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                            child: Text(
                              DateFormat('HH:mm').format(
                                donation.createdAt ??
                                    donation.executedAt ??
                                    DateTime.now(),
                              ),
                              style:
                                  AppTextStyles.bodySmall(
                                    color: statusColor,
                                    isDark: isDark,
                                  ).copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10.sp,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Enhanced church information section
                if (donation.churchName != null) ...[
                  SizedBox(height: 16.sp),
                  Container(
                    padding: EdgeInsets.all(16.sp),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16.sp),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.sp),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          child: Icon(
                            Icons.church,
                            size: 18.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Church',
                                style:
                                    AppTextStyles.bodySmall(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                      isDark: isDark,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11.sp,
                                    ),
                              ),
                              SizedBox(height: 2.sp),
                              Text(
                                donation.churchName!,
                                style:
                                    AppTextStyles.bodyMedium(
                                      color: AppColors.getOnSurfaceColor(
                                        isDark,
                                      ),
                                      isDark: isDark,
                                    ).copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12.sp,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCard(DonationHistory donation, bool isDark, int index) {
    // Keep the old method for backward compatibility
    return _buildEnhancedDonationCard(donation, isDark, index);
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120.sp,
                  height: 120.sp,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.darkPrimary.withValues(alpha: 0.2),
                              AppColors.darkPrimaryDark.withValues(alpha: 0.1),
                            ]
                          : [
                              AppColors.primary.withValues(alpha: 0.2),
                              AppColors.primaryDark.withValues(alpha: 0.1),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(60.sp),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 60.sp,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                ),
            SizedBox(height: 32.sp),
            Text(
              'No donations yet',
              style: AppTextStyles.headlineMedium(
                color: AppColors.getOnSurfaceColor(isDark),
                isDark: isDark,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
            SizedBox(height: 12.sp),
            Text(
              'Start your giving journey today',
              style: AppTextStyles.bodyLarge(
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.7),
                isDark: isDark,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
            SizedBox(height: 32.sp),
            Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                          : [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16.sp),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  void _showDonationDetails(DonationHistory donation, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child:
            Container(
                  padding: EdgeInsets.all(24.sp),
                  decoration: BoxDecoration(
                    color: AppColors.getSurfaceColor(isDark),
                    borderRadius: BorderRadius.circular(24.sp),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80.sp,
                        height: 80.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getStatusColor(
                                donation.status,
                              ).withValues(alpha: 0.2),
                              _getStatusColor(
                                donation.status,
                              ).withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.sp),
                        ),
                        child: Icon(
                          _getStatusIcon(donation.status),
                          color: _getStatusColor(donation.status),
                          size: 40.sp,
                        ),
                      ),
                      SizedBox(height: 24.sp),
                      Text(
                        '\$${donation.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.headlineLarge(
                          color: AppColors.getOnSurfaceColor(isDark),
                          isDark: isDark,
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8.sp),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.sp,
                          vertical: 8.sp,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            donation.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.sp),
                          border: Border.all(
                            color: _getStatusColor(
                              donation.status,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          donation.statusDisplay.toUpperCase(),
                          style: AppTextStyles.bodyMedium(
                            color: _getStatusColor(donation.status),
                            isDark: isDark,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 24.sp),
                      _buildDetailRow(
                        'Date',
                        DateFormat('MMM dd, yyyy').format(
                          donation.createdAt ??
                              donation.executedAt ??
                              DateTime.now(),
                        ),
                        Icons.calendar_today,
                        isDark,
                      ),
                      _buildDetailRow(
                        'Time',
                        DateFormat('HH:mm').format(
                          donation.createdAt ??
                              donation.executedAt ??
                              DateTime.now(),
                        ),
                        Icons.access_time,
                        isDark,
                      ),
                      if (donation.churchName != null)
                        _buildDetailRow(
                          'Church',
                          donation.churchName!,
                          Icons.church,
                          isDark,
                        ),
                      _buildDetailRow(
                        'Transaction ID',
                        donation.id.toString(),
                        Icons.receipt,
                        isDark,
                      ),
                      SizedBox(height: 24.sp),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.sp),
                            ),
                          ),
                          child: Text('Close'),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.sp),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
          ),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall(
                    color: AppColors.getOnSurfaceColor(
                      isDark,
                    ).withValues(alpha: 0.6),
                    isDark: isDark,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.getOnSurfaceColor(isDark),
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'failed':
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
