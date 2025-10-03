import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/models/bank_account.dart';
import 'package:manna_donate_app/data/models/payment_method.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/presentation/widgets/submit_button.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/presentation/widgets/error_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({super.key});

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'all';
  int _paymentMethodsCount = 0;
  String? _expandedCardIndex; // Track which card is expanded
  bool _showAllAccounts =
      false; // Track whether to show all accounts or just first 3

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
    // Defer data loading to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load bank accounts with loading spinner when fetching from server
      await Provider.of<BankProvider>(
        context,
        listen: false,
      ).smartFetchBankAccountsWithLoading();

      // Payment methods should already be loaded from cache during initial fetch
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      if (mounted) {
        setState(() {
          _paymentMethodsCount = bankProvider.paymentMethods.length;
        });
      }
    } catch (e) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh payment methods when screen becomes active (e.g., returning from link bank account)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final bankProvider = Provider.of<BankProvider>(context, listen: false);
        await bankProvider.smartFetchPaymentMethods();
        setState(() {
          _paymentMethodsCount = bankProvider.paymentMethods.length;
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
      appBar: AppHeader(title: 'Bank Accounts'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Consumer<BankProvider>(
          builder: (context, bankProvider, _) {
            final accounts = bankProvider.accounts;
            final filteredAccounts = _getFilteredAccounts(accounts);

            // Update payment methods count when bank provider changes
            _paymentMethodsCount = bankProvider.paymentMethods.length;

            if (bankProvider.loading && accounts.isEmpty) {
              return Center(
                child: LoadingBounce(
                  message: 'Loading bank accounts...',
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 60,
                  isDark: isDark,
                ),
              );
            }

            if (bankProvider.error != null && accounts.isEmpty) {
              return _buildErrorState(bankProvider, isDark);
            }

            return RefreshIndicator(
              onRefresh: () async {
                final bankProvider = Provider.of<BankProvider>(
                  context,
                  listen: false,
                );

                // Fetch fresh data from backend (bypass cache)
                await Future.wait([
                  bankProvider.refreshBankAccounts(),
                  bankProvider.refreshPaymentMethods(),
                  bankProvider.refreshPreferences(),
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
                        _buildHeader(isDark),
                        const SizedBox(height: 24),
                        _buildSummaryStats(accounts, isDark),
                        const SizedBox(height: 24),
                        _buildPaymentMethodsInfo(bankProvider, isDark),
                        const SizedBox(height: 24),
                        _buildAccountsList(filteredAccounts, isDark),
                        const SizedBox(height: 24),
                        _buildAddAccountSection(isDark),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
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
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Your Accounts',
                          style: AppTextStyles.getHeader(
                            isDark: isDark,
                          ).copyWith(fontWeight: FontWeight.w700, fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Link and manage your bank accounts for automatic roundup donations',
                          style: AppTextStyles.getSubtitle(isDark: isDark)
                              .copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(List<BankAccount> accounts, bool isDark) {
    final linkedAccounts = accounts.where((a) => a.isLinked).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                isDark,
                'Linked Accounts',
                linkedAccounts.toString(),
                Icons.link,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                isDark,
                'Payment Methods',
                _paymentMethodsCount.toString(),
                Icons.credit_card,
                AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.08)]
              : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.06)],
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
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.getTitle(
              isDark: isDark,
            ).copyWith(color: color, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.getCaption(isDark: isDark).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

  Widget _buildFilterChips(bool isDark) {
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.filter_list, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Filter Accounts',
                style: AppTextStyles.getBody(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  isDark,
                  'All',
                  'all',
                  _selectedFilter == 'all',
                ),
                const SizedBox(width: 4),
                _buildFilterChip(
                  isDark,
                  'Linked',
                  'linked',
                  _selectedFilter == 'linked',
                ),
                const SizedBox(width: 4),
                _buildFilterChip(
                  isDark,
                  'Unlinked',
                  'unlinked',
                  _selectedFilter == 'unlinked',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    bool isDark,
    String label,
    String value,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.getCaption(isDark: isDark).copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsList(List<BankAccount> accounts, bool isDark) {
    if (accounts.isEmpty) {
      return _buildEmptyState(isDark);
    }

    // Determine how many accounts to show
    const int initialAccountsToShow = 3;
    final bool hasMoreAccounts = accounts.length > initialAccountsToShow;
    final List<BankAccount> initialAccounts = accounts
        .take(initialAccountsToShow)
        .toList();
    final List<BankAccount> additionalAccounts = hasMoreAccounts
        ? accounts.skip(initialAccountsToShow).toList()
        : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Accounts',
              style: AppTextStyles.getTitle(isDark: isDark),
            ),
            if (hasMoreAccounts)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAllAccounts = !_showAllAccounts;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showAllAccounts ? 'Show Less' : 'Show More',
                      style: AppTextStyles.getBodySmall(isDark: isDark)
                          .copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showAllAccounts
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Always show the first 3 accounts
        ...initialAccounts.map((account) => _buildAccountCard(account, isDark)),
        // Show additional accounts when expanded with animation
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _showAllAccounts && additionalAccounts.isNotEmpty
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 8),
              ...additionalAccounts.map(
                (account) => _buildAccountCard(account, isDark),
              ),
            ],
          ),
        ),
        // Show "more accounts" indicator when collapsed
        if (hasMoreAccounts && !_showAllAccounts)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.more_horiz, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${additionalAccounts.length} more accounts',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAccountCard(BankAccount account, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.warning.withValues(alpha: 0.08),
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.03)
                      : AppColors.warning.withValues(alpha: 0.03),
                ]
              : [
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.06)
                      : AppColors.warning.withValues(alpha: 0.06),
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.02)
                      : AppColors.warning.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: account.isLinked
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.warning.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: account.isLinked
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
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
              gradient: LinearGradient(
                colors: [
                  account.isLinked ? AppColors.success : AppColors.warning,
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.8)
                      : AppColors.warning.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: account.isLinked
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              account.isLinked ? Icons.check_circle : Icons.link_off,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.institutionName,
                  style: AppTextStyles.getBody(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  account.displayName,
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '••••${account.mask}',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  account.isLinked ? AppColors.success : AppColors.warning,
                  account.isLinked
                      ? AppColors.success.withValues(alpha: 0.8)
                      : AppColors.warning.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: account.isLinked
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              account.isLinked ? 'LINKED' : 'UNLINKED',
              style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.info.withValues(alpha: 0.08),
                  AppColors.info.withValues(alpha: 0.03),
                ]
              : [
                  AppColors.info.withValues(alpha: 0.06),
                  AppColors.info.withValues(alpha: 0.02),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.account_balance, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'No bank accounts yet',
            style: AppTextStyles.getBody(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Link your first bank account to start making roundup donations',
            style: AppTextStyles.getCaption(isDark: isDark).copyWith(
              fontSize: 14,
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

  Widget _buildAddAccountSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                child: Icon(Icons.add_circle, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Add New Account',
                style: AppTextStyles.getTitle(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.08),
                      ]
                    : [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.06),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Link a New Bank Account',
                  style: AppTextStyles.getBody(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Securely connect your bank account to enable automatic roundup donations',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SubmitButton(
                  text: 'Link Bank Account',
                  onPressed: () => context.go('/link-bank-account'),
                  icon: Icons.link,
                  height: 40,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsInfo(BankProvider bankProvider, bool isDark) {
    final paymentMethods = bankProvider.paymentMethods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.credit_card, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment Methods (${paymentMethods.length})',
                style: AppTextStyles.getTitle(
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/payment-methods'),
              child: Text(
                'View All',
                style: AppTextStyles.getBodySmall(isDark: isDark).copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Payment Method Cards
        if (paymentMethods.isNotEmpty) ...[
          ...paymentMethods.map(
            (method) => _buildPaymentMethodCard(method, isDark),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.fromLTRB(60, 10, 60, 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No payment methods added yet',
                  style: AppTextStyles.getBody(
                    isDark: isDark,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Consider adding a payment method for donations.',
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ACH Encouragement Message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '💡 Help Churches Save More',
                      style: AppTextStyles.getBody(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Consider using ACH (bank transfer) instead of cards for donations. ACH transfers have lower processing fees, meaning churches receive more of your donation!',
                style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method, bool isDark) {
    final isCard = method.type == 'card';
    final isExpanded = _expandedCardIndex == method.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: isExpanded ? 160 : 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCard
                ? _getCardGradient(method.cardBrand, isDark)
                : _getBankGradient(isDark),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with type and default badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isCard ? 'CREDIT CARD' : 'BANK ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (method.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'DEFAULT',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Card number
                  Text(
                    isExpanded
                        ? (isCard
                              ? '•••• •••• •••• ${method.cardLast4 ?? '••••'}'
                              : '•••• ${method.bankLast4 ?? '****'}')
                        : (isCard
                              ? '•••• •••• •••• ${method.cardLast4 ?? '****'}'
                              : '•••• ${method.bankLast4 ?? '****'}'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CARD HOLDER',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method.billingName ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (isCard) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${method.cardExpMonth?.toString().padLeft(2, '0') ?? '**'}/${method.cardExpYear?.toString().substring(2) ?? '**'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BANK',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              method.bankName ?? 'N/A',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (method.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getCardGradient(String? brand, bool isDark) {
    switch (brand?.toLowerCase()) {
      case 'visa':
        return [const Color(0xFF1A1F71), const Color(0xFF00539C)];
      case 'mastercard':
        return [const Color(0xFFEB001B), const Color(0xFFF79E1B)];
      case 'amex':
        return [const Color(0xFF006FCF), const Color(0xFF00A3E0)];
      case 'discover':
        return [const Color(0xFFFF6000), const Color(0xFFFF8C00)];
      default:
        return isDark
            ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
            : [AppColors.primary, AppColors.primaryDark];
    }
  }

  List<Color> _getBankGradient(bool isDark) {
    return isDark
        ? [const Color(0xFF2E7D32), const Color(0xFF1B5E20)]
        : [const Color(0xFF4CAF50), const Color(0xFF388E3C)];
  }

  Widget _buildErrorState(BankProvider bankProvider, bool isDark) {
    return AppErrorWidget(
      error: bankProvider.error,
      onRetry: _loadData,
      retryText: 'Try Again',
    );
  }

  List<BankAccount> _getFilteredAccounts(List<BankAccount> accounts) {
    switch (_selectedFilter) {
      case 'linked':
        return accounts.where((a) => a.isLinked).toList();
      case 'unlinked':
        return accounts.where((a) => !a.isLinked).toList();
      default:
        return accounts;
    }
  }
}
