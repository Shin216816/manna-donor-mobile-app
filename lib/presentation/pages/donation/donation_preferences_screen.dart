import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';


import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/repository/donation_provider.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/core/utils.dart';
import 'package:manna_donate_app/data/models/church.dart';
import 'package:manna_donate_app/presentation/widgets/submit_button.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

class DonationPreferencesScreen extends StatefulWidget {
  const DonationPreferencesScreen({super.key});

  @override
  State<DonationPreferencesScreen> createState() =>
      _DonationPreferencesScreenState();
}

class _DonationPreferencesScreenState extends State<DonationPreferencesScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  String _frequency = 'biweekly';
  String _multiplier = '1x';
  int? _selectedChurchId = 0; // Initialize to 0 to represent "no selection"
  bool _pause = false;
  bool _coverProcessingFees = false;
  bool _isLoading = false;
  String? _error;
  List<Church> _churches = [];

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late FocusNode _focusNode;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode = FocusNode();

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

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    _startAnimations();
    
    // Add focus listener to sync church selection when screen gains focus
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncChurchSelectionOnDemand();
        });
      }
    });
    
    // Defer data loading to after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _startAnimations() {
    _slideController.forward();
    _fadeController.forward();
    // Remove pulse animation to reduce performance impact
    _scaleController.forward();
    _bounceController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sync church selection when dependencies change (e.g., when returning from church selection)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncChurchSelectionOnDemand();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App became visible, sync church selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _syncChurchSelectionOnDemand();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load data in background without blocking UI
      _loadDataInBackground(bankProvider, churchProvider, roundupProvider, authProvider);

      // Show content immediately
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load preferences: $e';
        _isLoading = false;
      });
    }
  }

  /// Load data in background without blocking UI
  void _loadDataInBackground(
    BankProvider bankProvider,
    ChurchProvider churchProvider,
    RoundupProvider roundupProvider,
    AuthProvider authProvider,
  ) {
    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        // Load preferences first (most important)
        await bankProvider.smartFetchPreferences();
        
        // Load existing preferences immediately
        final preferences = bankProvider.preferences;
        if (preferences != null && mounted) {
          setState(() {
            _frequency = preferences.frequency;
            _multiplier = preferences.multiplier;
            _pause = preferences.pause;
            _coverProcessingFees = preferences.coverProcessingFees;
          });
        }

        // Sync church selection with current user state
        await _syncChurchSelection(authProvider, churchProvider);

        // Load other data in parallel (cache-first)
        await Future.wait([
          churchProvider.fetchAvailableChurches(),
          roundupProvider.smartFetchRoundupTransactions(),
          roundupProvider.smartFetchEnhancedRoundupStatus(),
          roundupProvider.smartFetchDonationHistory(),
        ]);

        // Load churches
        final churches = churchProvider.availableChurches;
        if (mounted) {
          setState(() {
            _churches = churches;
          });
  
          if (churches.isEmpty) {
                    // No churches loaded from churchProvider.availableChurches
      } else {
        // Loaded ${churches.length} churches
      }
        }

        // If user has a selected church but it's not in the churches list, try to get it
        if (_selectedChurchId != null && _selectedChurchId != 0) {
          final userChurchExists = churches.any(
            (church) => church.id == _selectedChurchId,
          );
          if (!userChurchExists) {
            await _loadUserChurchInfo();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load preferences: $e';
          });
        }
      }
    });
  }

  /// Sync church selection on demand (when screen becomes visible)
  void _syncChurchSelectionOnDemand() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final churchProvider = Provider.of<ChurchProvider>(context, listen: false);
      
      // Check if user has churches in profile
      final userChurchIds = authProvider.userChurchIds;
      if (userChurchIds.isNotEmpty) {
        final firstChurchId = int.parse(userChurchIds.first);
        if (_selectedChurchId != firstChurchId) {
          setState(() {
            _selectedChurchId = firstChurchId;
          });
        }
        
        // Also sync the ChurchProvider's selected church
        churchProvider.syncSelectedChurchFromProfile(userChurchIds);
      }
    } catch (e) {
      // Silent fail for on-demand sync
    }
  }

  /// Sync church selection with current user state and preferences
  Future<void> _syncChurchSelection(
    AuthProvider authProvider,
    ChurchProvider churchProvider,
  ) async {
    try {
      // First check if user has any church IDs from their profile
      final userChurchIds = authProvider.userChurchIds;
      
      if (userChurchIds.isNotEmpty) {
        // User has churches in their profile, use the first one as selected
        final firstChurchId = int.parse(userChurchIds.first);
        setState(() {
          _selectedChurchId = firstChurchId;
        });
        
        // Also sync the ChurchProvider's selected church
        churchProvider.syncSelectedChurchFromProfile(userChurchIds);
      } else {
        // User has no churches in profile, check preferences
        final bankProvider = Provider.of<BankProvider>(context, listen: false);
        final preferences = bankProvider.preferences;
        if (preferences != null && preferences.churchId != null) {
          setState(() {
            _selectedChurchId = preferences.churchId;
          });
        } else {
          // No church selected anywhere
          setState(() {
            _selectedChurchId = 0;
          });
        }
      }
    } catch (e) {
      // Fallback to preferences if sync fails
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final preferences = bankProvider.preferences;
      if (preferences != null && preferences.churchId != null) {
        setState(() {
          _selectedChurchId = preferences.churchId;
        });
      } else {
        setState(() {
          _selectedChurchId = 0;
        });
      }
    }
  }

  Future<void> _loadUserChurchInfo() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final churchProvider = Provider.of<ChurchProvider>(
        context,
        listen: false,
      );

      if (authProvider.userChurchIds.isNotEmpty) {
        await churchProvider.fetchUserChurchesBySearch(
          authProvider.userChurchIds.map((id) => int.parse(id)).toList(),
        );
        final userChurches = churchProvider.availableChurches;
        setState(() {
          _churches = [..._churches, ...userChurches];
        });
      }
    } catch (e) {}
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate church selection - user must have a church selected
    if (_selectedChurchId == null || _selectedChurchId == 0) {
      setState(() {
        _error = 'Please select a church to continue';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);

      // Ensure church ID is properly set - if no church is selected, set to null
      // This ensures the backend knows the user explicitly didn't select a church
      final churchIdToSave = _selectedChurchId == 0 || _selectedChurchId == null
          ? null
          : _selectedChurchId;

      final response = await bankProvider.updatePreferences(
        frequency: _frequency,
        multiplier: _multiplier,
        churchId: churchIdToSave,
        pause: _pause,
        coverProcessingFees: _coverProcessingFees,
      );
      
      // Also refresh DonationProvider to ensure home screen shows updated pause state
      if (response.success) {
        try {
          final donationProvider = Provider.of<DonationProvider>(context, listen: false);
          await donationProvider.fetchPreferences();
        } catch (e) {
          // If DonationProvider is not available, continue silently
        }
      }

      if (mounted) {
        // Stay on preferences screen and refresh data
        await _loadData();
        
        // Show success message
        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Preferences saved successfully!',
            backgroundColor: AppColors.success,
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save preferences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppHeader(title: 'Donation Preferences'),
      drawer: AppDrawer(),
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: Focus(
        focusNode: _focusNode,
        child: Stack(
          children: [
          // Main content - always visible
          SafeArea(
            child: _error != null
                ? _buildErrorState(isDark)
                : RefreshIndicator(
                    onRefresh: () async {
                      final bankProvider = Provider.of<BankProvider>(context, listen: false);
                      final churchProvider = Provider.of<ChurchProvider>(context, listen: false);
                      final roundupProvider = Provider.of<RoundupProvider>(context, listen: false);
                      
                      // Fetch fresh data from backend (bypass cache)
                      await Future.wait([
                        bankProvider.refreshPreferences(),
                        churchProvider.refreshAvailableChurches(),
                        roundupProvider.refreshRoundupTransactions(),
                        roundupProvider.refreshEnhancedRoundupStatus(),
                        roundupProvider.refreshRoundupSettings(),
                      ]);
                      
                      // Reload data after refresh
                      await _loadData();
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
                      child: Form(
                        key: _formKey,
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
                              _buildRoundupStatus(isDark),
                              const SizedBox(height: 24),
                              _buildRoundupSettings(isDark),
                              const SizedBox(height: 24),
                              _buildChurchSelection(isDark),
                              const SizedBox(height: 24),
                              _buildAdvancedSettings(isDark),
                              const SizedBox(height: 32),
                              _buildSaveButton(isDark),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ),
          // Full screen loading overlay if data is still loading
          if (_isLoading)
            Container(
              color: isDark
                  ? AppColors.darkBackground.withValues(alpha: 0.8)
                  : AppColors.background.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingWave(
                      message: 'Loading preferences...',
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      size: 50,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Please wait while we load your preferences',
                      style: AppTextStyles.getBody(isDark: isDark).copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                    : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
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
                            'Configure Your Donations',
                            style: AppTextStyles.getHeader(isDark: false)
                                .copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set up your roundup preferences and choose your preferred church',
                            style: AppTextStyles.getSubtitle(isDark: false)
                                .copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
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
      ),
    );
  }

  Widget _buildRoundupStatus(bool isDark) {
    final roundupProvider = Provider.of<RoundupProvider>(context);

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.card,
          borderRadius: BorderRadius.circular(20),
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
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.roundupPrimary,
                              AppColors.roundupPrimary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.roundupPrimary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Roundup Status',
                  style: AppTextStyles.getTitle(isDark: isDark),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Overview
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    isDark,
                    'Accumulated',
                    '\$${roundupProvider.accumulatedRoundups.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    AppColors.roundupPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusCard(
                    isDark,
                    'Next Transfer',
                    roundupProvider.nextTransferDate != null
                        ? _formatDate(roundupProvider.nextTransferDate!)
                        : 'Not scheduled',
                    Icons.schedule,
                    AppColors.success,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Additional Status Info
            if (roundupProvider.isTransferReady)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transfer ready! Your roundups will be sent to your church.',
                        style: AppTextStyles.getCaption(isDark: isDark)
                            .copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!roundupProvider.isTransferReady &&
                roundupProvider.accumulatedRoundups > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Continue making purchases to accumulate more roundups.',
                        style: AppTextStyles.getCaption(isDark: isDark)
                            .copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
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

  Widget _buildStatusCard(
    bool isDark,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.95 + 0.05,
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.darkSurface,
                        AppColors.darkSurface.withValues(alpha: 0.8),
                      ]
                    : [
                        AppColors.surface,
                        AppColors.surface.withValues(alpha: 0.8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Widget _buildRoundupSettings(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            (isDark ? AppColors.darkPrimary : AppColors.primary)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              Text(
                'Roundup Settings',
                style: AppTextStyles.getTitle(isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Frequency Selection
          Text(
            'Transfer Frequency',
            style: AppTextStyles.getBody(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildFrequencyChip(
                  isDark,
                  'Weekly',
                  'weekly',
                  _frequency == 'weekly',
                ),
                const SizedBox(width: 4),
                _buildFrequencyChip(
                  isDark,
                  'Bi-weekly',
                  'biweekly',
                  _frequency == 'biweekly',
                ),
                const SizedBox(width: 4),
                _buildFrequencyChip(
                  isDark,
                  'Monthly',
                  'monthly',
                  _frequency == 'monthly',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Multiplier Selection
          Text(
            'Roundup Multiplier',
            style: AppTextStyles.getBody(
              isDark: isDark,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how much to multiply your roundup amounts',
            style: AppTextStyles.getCaption(isDark: isDark),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkInputFill : AppColors.inputFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildMultiplierChip(isDark, 'Default', '1x', _multiplier == '1x'),
                const SizedBox(width: 4),
                _buildMultiplierChip(isDark, '2x', '2x', _multiplier == '2x'),
                const SizedBox(width: 4),
                _buildMultiplierChip(isDark, '3x', '3x', _multiplier == '3x'),
                const SizedBox(width: 4),
                _buildMultiplierChip(isDark, '5x', '5x', _multiplier == '5x'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pause Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pause Roundups',
                      style: AppTextStyles.getBody(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Temporarily stop automatic roundup collections',
                      style: AppTextStyles.getCaption(isDark: isDark),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _pause,
                onChanged: (value) {
                  setState(() {
                    _pause = value;
                  });
                },
                activeColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(
    bool isDark,
    String label,
    String value,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _frequency = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiplierChip(
    bool isDark,
    String label,
    String value,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _multiplier = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
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
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildChurchSelection(bool isDark) {
    return Consumer<ChurchProvider>(
      builder: (context, churchProvider, child) {
        // Get the user's selected church
        Church? selectedChurch;
        if (_selectedChurchId != null && _selectedChurchId != 0) {
          selectedChurch = _churches.firstWhere(
            (church) => church.id == _selectedChurchId,
            orElse: () => churchProvider.selectedChurch ?? Church(
              id: 0,
              name: 'Unknown Church',
              address: '',
              phone: '',
              website: '',
              kycStatus: '',
              isActive: false,
              isVerified: false,
            ),
          );
        }
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.card,
            borderRadius: BorderRadius.circular(20),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.roundupPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.church,
                      color: AppColors.roundupPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Church',
                    style: AppTextStyles.getTitle(isDark: isDark),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (selectedChurch != null && selectedChurch.id != 0)
                _buildChurchInfoCard(isDark, selectedChurch)
              else
                _buildNoChurchSelected(isDark),

              const SizedBox(height: 16),

              // Change Church Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await context.push('/church-selection', extra: {'isFromPreferences': true});
                    if (result == true) {
                      // Church was selected, refresh user data
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final bankProvider = Provider.of<BankProvider>(context, listen: false);
                      await authProvider.getProfile();
                      // Refresh preferences to get updated church ID
                      await bankProvider.refreshPreferences();
                      // Reload preferences data
                      await _loadData();
                    }
                  },
                  icon: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    selectedChurch != null && selectedChurch.id != 0 
                        ? 'Change Church' 
                        : 'Select Church',
                    style: AppTextStyles.getBody(isDark: false).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ACH Encouragement Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
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
                            '💡 Help Your Church Save More',
                            style: AppTextStyles.getBody(isDark: isDark).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consider using ACH (bank transfer) instead of cards for donations. ACH transfers have lower processing fees, meaning your church receives more of your donation!',
                      style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                        color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChurchInfoCard(bool isDark, Church church) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.darkSurface,
                  AppColors.darkSurface.withValues(alpha: 0.8),
                ]
              : [
                  AppColors.surface,
                  AppColors.surface.withValues(alpha: 0.8),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.roundupPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.roundupPrimary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Church Name and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  church.name,
                  style: AppTextStyles.getTitle(isDark: isDark).copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ),
              if (church.isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: AppColors.success,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Church Address
          if (church.address.isNotEmpty)
            _buildInfoRow(
              isDark,
              Icons.location_on,
              'Address',
              church.address,
            ),

          // City and State
          if (church.city != null && church.state != null)
            _buildInfoRow(
              isDark,
              Icons.location_city,
              'Location',
              '${church.city}, ${church.state}',
            ),

          // Phone
          if (church.phone != null && church.phone!.isNotEmpty)
            _buildInfoRow(
              isDark,
              Icons.phone,
              'Phone',
              church.phone!,
            ),

          // Email
          if (church.email != null && church.email!.isNotEmpty)
            _buildInfoRow(
              isDark,
              Icons.email,
              'Email',
              church.email!,
            ),

          // Website
          if (church.website != null && church.website!.isNotEmpty)
            _buildInfoRow(
              isDark,
              Icons.language,
              'Website',
              church.website!,
            ),

          // Church Type
          if (church.type != null && church.type!.isNotEmpty)
            _buildInfoRow(
              isDark,
              Icons.category,
              'Type',
              church.type!,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.roundupPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              color: AppColors.roundupPrimary,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoChurchSelected(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Church Selected',
                  style: AppTextStyles.getBody(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please select a church to receive your donations',
                  style: AppTextStyles.getCaption(isDark: isDark).copyWith(
                    color: AppColors.warning.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(20),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Advanced Settings',
                style: AppTextStyles.getTitle(isDark: isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cover Processing Fees Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cover Processing Fees',
                      style: AppTextStyles.getBody(
                        isDark: isDark,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pay transaction fees so your church receives the full amount',
                      style: AppTextStyles.getCaption(isDark: isDark),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _coverProcessingFees,
                onChanged: (value) {
                  setState(() {
                    _coverProcessingFees = value;
                  });
                },
                activeColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * 0.98 + 0.02,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkPrimary, AppColors.darkPrimaryDark]
                    : [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SubmitButton(
              text: 'Save Preferences',
              onPressed: _isLoading ? null : _savePreferences,
              icon: Icons.save,
              loading: _isLoading,
                                              height: 40.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.getTitle(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unexpected error occurred',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SubmitButton(
              text: 'Try Again',
              onPressed: _loadData,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }
}
