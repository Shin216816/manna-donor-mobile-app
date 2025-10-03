import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui'; // Added for ImageFilter

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/models/user.dart';
import 'package:manna_donate_app/data/models/church.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/profile_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/data/repository/analytics_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'package:manna_donate_app/data/apiClient/analytics_service.dart';

import 'package:manna_donate_app/core/logout_service.dart';
import 'package:manna_donate_app/presentation/widgets/verification_dialog.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/core/utils/image_utils.dart';
import 'package:manna_donate_app/core/utils/snackbar_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isEditing = false;
  File? _selectedImage;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Analytics data
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _dashboardData;
  final AnalyticsService _analyticsService = AnalyticsService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations
    _initializeAnimations();

    // Start animations
    _startAnimations();

    // Add listeners to text controllers to update UI when user types
    _emailController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    
    _phoneController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load profile data (cache-first approach)
      _loadProfileData();
    });
  }

  void _initializeAnimations() {
    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _contentSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load profile data (cache-first approach)
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final churchProvider = Provider.of<ChurchProvider>(
        context,
        listen: false,
      );

      await Future.wait([
        authProvider.getProfile(),
        churchProvider.fetchAvailableChurches(),
      ]);

      // Show content immediately with cached data
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Load analytics data in background (cache-first)
      _loadAnalyticsDataInBackground();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Load analytics data in background without blocking UI (cache-first)
  void _loadAnalyticsDataInBackground() {
    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        // Use analytics provider with cache-first approach
        final analyticsProvider = Provider.of<AnalyticsProvider>(
          context,
          listen: false,
        );

        // Load cached analytics data (cache-first approach)
        await analyticsProvider.loadMobileImpactSummary(); // This uses cache-first
        await analyticsProvider.loadDonationDashboard(); // This uses cache-first

        if (mounted) {
          setState(() {
            _analyticsData = analyticsProvider.impactData; // Use impactData instead of analyticsData
            _dashboardData = analyticsProvider.dashboardData;
          });
        }
      } catch (e) {
        // Handle error silently - cached data approach means we don't need to show errors
        // The UI will show loading state until data is available
      }
    });
  }

  /// Retry loading analytics data using cache-first approach
  Future<void> _retryAnalyticsData() async {
    try {
      final analyticsProvider = Provider.of<AnalyticsProvider>(
        context,
        listen: false,
      );

      // Load analytics data using cache-first approach
      await analyticsProvider.loadMobileImpactSummary();
      await analyticsProvider.loadDonationDashboard();

      if (mounted) {
        setState(() {
          _analyticsData = analyticsProvider.impactData;
          _dashboardData = analyticsProvider.dashboardData;
        });
      }
    } catch (e) {
      // Handle error silently - cached data approach
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.getBackgroundColor(isDark),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
              SizedBox(height: 16.sp),
              Text(
                'No user data found',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.getOnSurfaceColor(isDark),
                ),
              ),
              SizedBox(height: 8.sp),
              Text(
                'Please sign in to view your profile',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 24.sp),
              ModernButton(
                text: 'Sign In',
                onPressed: () => context.go('/login'),
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppHeader(title: 'Profile', showThemeToggle: true),
      drawer: AppDrawer(),
      body: Stack(
        children: [
          // Main content - always visible
          AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      final analyticsProvider = Provider.of<AnalyticsProvider>(
                        context,
                        listen: false,
                      );

                      // Load data using cache-first approach (not forcing server fetch)
                      await Future.wait([
                        authProvider.getProfile(),
                        analyticsProvider.loadMobileImpactSummary(), // Uses cache-first
                        analyticsProvider.loadDonationDashboard(), // Uses cache-first
                      ]);
                      
                      // Update local state with data (from cache or server if cache is stale)
                      if (mounted) {
                        setState(() {
                          _analyticsData = analyticsProvider.impactData;
                          _dashboardData = analyticsProvider.dashboardData;
                        });
                      }
                    },
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(AppConstants.pagePadding.sp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(user, isDark),
                          SizedBox(height: 16.sp),
                          _buildAccountStats(user, isDark),
                          SizedBox(height: 16.sp),
                          _buildPersonalInfo(user, isDark),
                          SizedBox(height: 16.sp),
                          _buildAccountActions(user, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Small loading indicator at top if data is still loading
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
                        'Updating profile data...',
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

  Widget _buildProfileHeader(User user, bool isDark) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
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
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Column(
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        ImageUtils.buildProfileImage(
                          radius: 35.sp,
                          imageUrl: user.profilePictureUrl,
                          selectedImage: _selectedImage,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          fallbackIcon: Icon(
                            Icons.person,
                            size: 35.sp,
                            color: Colors.white,
                          ),
                          onTap: _handleProfileImageTap,
                          showErrorHandling: true,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16.sp,
                              ),
                              onPressed: _handleProfileImageTap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.sp),
                  Text(
                    user.name,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    user.email,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.sp,
                      vertical: 4.sp,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16.sp),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      user.isActive ? 'Active Member' : 'Inactive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.sp),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProfileStat(
                        'Member Since',
                        _formatDate(user.createdAt),
                        isDark,
                      ),
                      _buildProfileStat(
                        'Last Login',
                        _formatDate(user.lastLogin),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 2.sp),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStats(User user, bool isDark) {
    // Check if analytics data is loaded
    final isAnalyticsLoaded = _analyticsData != null;
    
    // Extract real data from backend - total donated comes from impact data
    final totalDonated = _analyticsData?['total_donated']?.toString() ?? '0.00';

    // Get church information
    final churchProvider = Provider.of<ChurchProvider>(context, listen: false);
    String churchInfo = 'No Church';

    if (user.churchIds.isNotEmpty) {
      final primaryChurchId = user.primaryChurchId ?? user.churchIds.first;
      final church = churchProvider.availableChurches.firstWhere(
        (church) => church.id == primaryChurchId,
        orElse: () => Church(
          id: 0,
          name: 'Unknown Church',
          address: 'Unknown Address',
          phone: '',
          website: '',
          kycStatus: 'pending',
          isActive: false,
          isVerified: false,
        ),
      );

      if (church != null) {
        // Truncate church name if it's too long
        final churchName = church.name;
        if (churchName.length > 20) {
          churchInfo = '${churchName.substring(0, 17)}...';
        } else {
          churchInfo = churchName;
        }
      } else {
        churchInfo = 'Church ID: $primaryChurchId';
      }
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, 20.0 * (1.0 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(16.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Statistics',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getOnSurfaceColor(isDark),
                      ),
                    ),
                    SizedBox(height: 12.sp),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Donated',
                            isAnalyticsLoaded 
                                ? '\$${_formatCurrency(double.tryParse(totalDonated) ?? 0.0)}'
                                : 'Loading...',
                            Icons.volunteer_activism,
                            isAnalyticsLoaded ? Colors.green : Colors.grey,
                            isDark,
                          ),
                        ),
                        SizedBox(width: 10.sp),
                        Expanded(
                          child: _buildStatCard(
                            'My Church',
                            churchInfo,
                            Icons.church,
                            Colors.blue,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    // Show loading indicator if analytics data is not loaded
                    if (!isAnalyticsLoaded) ...[
                      SizedBox(height: 8.sp),
                      Row(
                        children: [
                          SizedBox(
                            width: 12.sp,
                            height: 12.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Expanded(
                            child: Text(
                              'Loading donation data...',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _retryAnalyticsData,
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2);
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_pulseAnimation.value - 1.0) * 0.1,
          child: Container(
            height: 85.sp, // Fixed height for consistency
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.sp),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space evenly
              children: [
                // Header row with consistent height
                SizedBox(
                  height: 20.sp, // Fixed height for title row
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 16.sp),
                      SizedBox(width: 6.sp),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.getOnSurfaceColor(
                              isDark,
                            ).withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          softWrap: true,
                          maxLines: 1, // Ensure single line for consistency
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Value section with consistent height
                SizedBox(
                  height: 35.sp, // Fixed height for value section
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getOnSurfaceColor(isDark),
                      ),
                      maxLines: 2, // Allow up to 2 lines for value
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonalInfo(User user, bool isDark) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _contentSlideAnimation.value),
          child: Opacity(
            opacity: _contentFadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(14.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personal Information',
                          style: AppTextStyles.title.copyWith(
                            fontSize: 16.sp,
                            color: AppColors.getOnSurfaceColor(isDark),
                          ),
                        ),
                        if (!_isEditing)
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: IconButton(
                                  onPressed: () => _startEditing(user),
                                  icon: Icon(
                                    Icons.edit,
                                    color: AppColors.primary,
                                    size: 18.sp,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                    SizedBox(height: 12.sp),
                    if (!_isEditing) ...[
                      _buildInfoRow('Full Name', user.name, isDark),
                      _buildInfoRow('Email', user.email, isDark),
                      _buildInfoRow(
                        'Phone',
                        user.phone ?? 'Not provided',
                        isDark,
                      ),
                      _buildInfoRow(
                        'Member Since',
                        _formatDate(user.createdAt),
                        isDark,
                      ),
                      _buildInfoRow(
                        'Last Login',
                        _formatDate(user.lastLogin),
                        isDark,
                      ),
                      SizedBox(height: 16.sp),
                      _buildVerificationSection(user, isDark),
                    ] else ...[
                      // Show name field (always editable)
                      ModernInputField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        isRequired: true,
                        autovalidateMode: true,
                        isDark: isDark,
                      ),
                      SizedBox(height: 16.sp),
                      
                      // Email field logic
                      if (user.isEmailVerified && !user.isPhoneVerified) ...[
                        // Show verified email as text when it's the only verified method
                        _buildVerifiedContactDisplay(
                          'Email Address',
                          user.email,
                          Icons.email_outlined,
                          isDark,
                        ),
                      ] else ...[
                        // Show email input field
                        ModernInputField(
                          controller: _emailController,
                          label: 'Email',
                          hint: _isEmailFieldDisabled(user) ? 'Email cannot be changed (verified)' : 'Enter your email address',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          isRequired: true,
                          autovalidateMode: true,
                          isDark: isDark,
                          enabled: !_isEmailFieldDisabled(user),
                        ),
                        if (_isEmailFieldDisabled(user)) ...[
                          SizedBox(height: 8.sp),
                          Text(
                            'Email is verified and cannot be changed',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                      SizedBox(height: 16.sp),
                      
                      // Phone field logic
                      if (user.isPhoneVerified && !user.isEmailVerified) ...[
                        // Show verified phone as text when it's the only verified method
                        _buildVerifiedContactDisplay(
                          'Phone Number',
                          user.phone ?? '',
                          Icons.phone_outlined,
                          isDark,
                        ),
                      ] else ...[
                        // Show phone input field
                        ModernInputField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: _isPhoneFieldDisabled(user) ? 'Phone cannot be changed (verified)' : 'Enter your phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          autovalidateMode: true,
                          isDark: isDark,
                          enabled: !_isPhoneFieldDisabled(user),
                        ),
                        if (_isPhoneFieldDisabled(user)) ...[
                          SizedBox(height: 8.sp),
                          Text(
                            'Phone is verified and cannot be changed',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                      
                      // Show verification status message
                      SizedBox(height: 16.sp),
                      Container(
                        padding: EdgeInsets.all(12.sp),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.sp),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.sp),
                            Expanded(
                              child: Text(
                                _getVerificationMessage(user),
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.sp),
                      Row(
                        children: [
                          Expanded(
                            child: ModernButton(
                              text: 'Save Changes',
                              onPressed: _hasChanges(user) && _areChangesValid(user) ? _saveProfile : null,
                              isLoading: _isLoading,
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          Expanded(
                            child: ModernButton(
                              text: 'Cancel',
                              onPressed: _cancelEditing,
                              variant: ButtonVariant.outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startEditing(User user) {
    setState(() {
      _isEditing = true;
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
    });
  }

  void _cancelEditing() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    setState(() {
      _isEditing = false;
      // Revert to original user data
      if (user != null) {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
      }
    });
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (user == null) {
      SnackBarUtils.showError(context, 'User data not found');
      return;
    }

    // Validate changes according to verification rules
    if (!_areChangesValid(user)) {
      String errorMessage = 'Invalid changes detected. ';
      
      if (user.isEmailVerified && user.isPhoneVerified) {
        errorMessage += 'You cannot change both email and phone when both are verified. Please change only one field.';
      } else if (user.isEmailVerified && !user.isPhoneVerified) {
        errorMessage += 'Email is verified and cannot be changed. Please verify your phone first.';
      } else if (user.isPhoneVerified && !user.isEmailVerified) {
        errorMessage += 'Phone is verified and cannot be changed. Please verify your email first.';
      }
      
      SnackBarUtils.showError(context, errorMessage);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse name into first, middle, and last name
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.last : '';
      final middleName = nameParts.length > 2
          ? nameParts.sublist(1, nameParts.length - 1).join(' ')
          : '';

      // Determine which fields to send based on verification status
      String? emailToSend = null;
      String? phoneToSend = null;
      
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      final originalEmail = user.email;
      final originalPhone = user.phone;
      
      // Only send email update if it's allowed and has changed
      if (_shouldSendEmailUpdate(user) && newEmail.isNotEmpty && newEmail != originalEmail) {
        emailToSend = newEmail;
      }
      
      // Only send phone update if it's allowed and has changed
      if (_shouldSendPhoneUpdate(user) && newPhone.isNotEmpty && newPhone != originalPhone) {
        phoneToSend = newPhone;
      }

      final success = await authProvider.updateProfile(
        firstName: firstName.isNotEmpty ? firstName : null,
        middleName: middleName.isNotEmpty ? middleName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        email: emailToSend,
        phone: phoneToSend,
      );

      if (success && mounted) {
        // Refresh user data to get the updated information
        await authProvider.getProfile();

        setState(() {
          _isEditing = false;
          _isLoading = false;
        });

        SnackBarUtils.showSuccess(context, 'Profile updated successfully');
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });

        SnackBarUtils.showError(
          context,
          authProvider.error ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        SnackBarUtils.showError(context, 'Failed to update profile: ${e.toString()}');
      }
    }
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16.sp),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.getOnSurfaceColor(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedContactDisplay(String label, String value, IconData icon, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTextStyles.inputLabel(
            color: isDark
                ? Colors.white
                : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.8),
            isDark: isDark,
          ),
        ),
        SizedBox(height: 8.sp),
        // Verified contact display
        Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32.sp,
                height: 32.sp,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Icon(
                  icon,
                  color: AppColors.success,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTextStyles.getBody(isDark: isDark).copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.sp),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.verified,
                color: AppColors.success,
                size: 20.sp,
              ),
            ],
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          'This field is verified and cannot be changed',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  bool _isEmailFieldDisabled(User user) {
    // If user has only email verified, the field is shown as text, not input
    // So this method is only called when both are verified or when email is not the only verified method
    
    // If user has both verified, they can change one but not both
    if (user.isEmailVerified && user.isPhoneVerified) {
      final originalEmail = user.email;
      final originalPhone = user.phone;
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      
      // If both email and phone are being changed, disable email field
      if (newEmail != originalEmail && newPhone != originalPhone) {
        return true;
      }
    }
    
    return false;
  }

  bool _isPhoneFieldDisabled(User user) {
    // If user has only phone verified, the field is shown as text, not input
    // So this method is only called when both are verified or when phone is not the only verified method
    
    // If user has both verified, they can change one but not both
    if (user.isEmailVerified && user.isPhoneVerified) {
      final originalEmail = user.email;
      final originalPhone = user.phone;
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();
      
      // If both email and phone are being changed, disable phone field
      if (newEmail != originalEmail && newPhone != originalPhone) {
        return true;
      }
    }
    
    return false;
  }

  String _getVerificationMessage(User user) {
    if (user.isEmailVerified && user.isPhoneVerified) {
      return 'Both email and phone are verified. You can change one but not both.';
    } else if (user.isEmailVerified) {
      return 'Email is verified and displayed as read-only. Please verify your phone to enable changes.';
    } else if (user.isPhoneVerified) {
      return 'Phone is verified and displayed as read-only. Please verify your email to enable changes.';
    } else {
      return 'Neither email nor phone is verified. Please verify at least one to enable changes.';
    }
  }

  Widget _buildVerificationSection(User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.sp),
            Text(
              'Account Verification',
              style: AppTextStyles.title.copyWith(
                fontSize: 16.sp,
                color: AppColors.getOnSurfaceColor(isDark),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.sp),
        Container(
          decoration: BoxDecoration(
            color: AppColors.getSurfaceColor(isDark),
            borderRadius: BorderRadius.circular(16.sp),
            border: Border.all(
              color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                _buildProfessionalVerificationTile(
                  'Email Address',
                  user.email,
                  user.isEmailVerified,
                  Icons.email_outlined,
                  user.isEmailVerified
                      ? null
                      : () => _showVerificationDialog(user, 'email'),
                  isDark,
                ),
                SizedBox(height: 12.sp),
                _buildProfessionalVerificationTile(
                  'Phone Number',
                  user.phone ?? 'Not provided',
                  user.isPhoneVerified,
                  Icons.phone_outlined,
                  user.isPhoneVerified
                      ? null
                      : () => _showVerificationDialog(user, 'phone'),
                  isDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalVerificationTile(
    String label,
    String value,
    bool isVerified,
    IconData icon,
    VoidCallback? onTap,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (_pulseAnimation.value - 1.0) * 0.05,
          child: Container(
            decoration: BoxDecoration(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.05)
                  : AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(
                color: isVerified
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12.sp),
                splashColor: onTap != null
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                highlightColor: onTap != null
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                child: Padding(
                  padding: EdgeInsets.all(16.sp),
                  child: Row(
                    children: [
                      // Icon with status
                      Container(
                        padding: EdgeInsets.all(10.sp),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10.sp),
                        ),
                        child: Icon(
                          icon,
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.sp),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: AppColors.getOnSurfaceColor(
                                        isDark,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8.sp),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.sp,
                                    vertical: 2.sp,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isVerified
                                        ? AppColors.success.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.warning.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(10.sp),
                                  ),
                                  child: Text(
                                    isVerified ? 'Verified' : 'Unverified',
                                    style: TextStyle(
                                      color: isVerified
                                          ? AppColors.success
                                          : AppColors.warning,
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              value,
                              style: TextStyle(
                                color: AppColors.getOnSurfaceColor(
                                  isDark,
                                ).withValues(alpha: 0.7),
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Action button
                      Container(
                        padding: EdgeInsets.all(8.sp),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.sp),
                        ),
                        child: Icon(
                          isVerified
                              ? Icons.check_circle
                              : Icons.arrow_forward_ios,
                          color: isVerified
                              ? AppColors.success
                              : AppColors.primary,
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showVerificationDialog(User user, String type) {
    final contact = type == 'email' ? user.email : (user.phone ?? '');

    if (contact.isEmpty) {
      SnackBarUtils.showError(
        context,
        'No ${type} address found. Please update your profile first.',
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VerificationDialog(
        type: type,
        contact: contact,
        onSuccess: () {
          // Refresh user data after successful verification
          Provider.of<AuthProvider>(context, listen: false).getProfile();
        },
      ),
    );
  }

  Widget _buildAccountActions(User user, bool isDark) {
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0.0, _contentSlideAnimation.value),
          child: Opacity(
            opacity: _contentFadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceColor(isDark),
                borderRadius: BorderRadius.circular(14.sp),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Actions',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16.sp,
                        color: AppColors.getOnSurfaceColor(isDark),
                      ),
                    ),
                    SizedBox(height: 12.sp),
                    _buildActionTile(
                      'Change Password',
                      Icons.lock,
                      Colors.blue,
                      () => context.go('/change-password'),
                      isDark,
                    ),
                    _buildActionTile(
                      'Payment Methods',
                      Icons.payment,
                      Colors.indigo,
                      () => context.go('/payment-methods'),
                      isDark,
                    ),
                    _buildActionTile(
                      'Settings',
                      Icons.settings,
                      Colors.green,
                      () => context.go('/settings'),
                      isDark,
                    ),
                    _buildActionTile(
                      'Help & Support',
                      Icons.help,
                      Colors.teal,
                      () => context.go('/help'),
                      isDark,
                    ),
                    Divider(
                      color: AppColors.getDividerColor(isDark),
                      height: 24.sp,
                    ),
                    _buildActionTile(
                      'Sign Out',
                      Icons.logout,
                      Colors.red,
                      () => _showSignOutDialog(),
                      isDark,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + (_pulseAnimation.value - 1.0) * 0.05,
          child: Container(
            margin: EdgeInsets.only(bottom: 6.sp),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceColor(isDark),
              borderRadius: BorderRadius.circular(10.sp),
              border: Border.all(
                color: AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.sp,
                vertical: 4.sp,
              ),
              leading: Container(
                padding: EdgeInsets.all(6.sp),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.sp),
                ),
                child: Icon(icon, color: color, size: 16.sp),
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: AppColors.getOnSurfaceColor(isDark),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.5),
                size: 16.sp,
              ),
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 40,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Sign Out',
                    style: AppTextStyles.getTitle(
                      isDark: isDark,
                    ).copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'Are you sure you want to sign out? You will need to log in again to access your account.',
                    style: AppTextStyles.getBody(isDark: isDark).copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Buttons
                  Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: TextButton(
                            onPressed: () => context.pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkTextSecondary.withValues(
                                          alpha: 0.3,
                                        )
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: AppTextStyles.getBody(isDark: isDark)
                                  .copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Sign Out button
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: () {
                              context.pop();
                              LogoutService.executeLogout(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sign Out',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No Date';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Profile Image Management - NEW SYSTEM
  Future<void> _handleProfileImageTap() async {
    try {
      // Show simple image source selection
      final String? choice = await _showSimpleImagePicker();

      if (choice == null) return; // User cancelled

      if (choice == 'remove') {
        await _removeProfileImage();
        return;
      }

      // Pick image based on choice
      final XFile? pickedImage = await _pickImageFromSource(choice);

      if (pickedImage != null) {
        // Upload the image
        await _uploadProfileImage(File(pickedImage.path));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  Future<String?> _showSimpleImagePicker() async {
    // Get user data before showing dialog to avoid Provider context issues
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final user = profileProvider.user;
    final hasProfileImage = user?.profilePictureUrl != null;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          title: Text(
            'Profile Image',
            style: TextStyle(color: AppColors.getOnSurfaceColor(isDark)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.7),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: AppColors.getOnSurfaceColor(isDark)),
                ),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.7),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: AppColors.getOnSurfaceColor(isDark)),
                ),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              if (hasProfileImage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.of(context).pop('remove'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<XFile?> _pickImageFromSource(String source) async {
    try {
      // Check if running on simulator
      final isSimulator = await _isRunningOnSimulator();
      if (isSimulator && source == 'camera') {
        // Show warning for camera on simulator
        SnackBarUtils.showWarning(
          context,
          'Camera is not available on simulator. Please use a real device.',
        );
        return null;
      }

      final ImagePicker picker = ImagePicker();

      if (source == 'camera') {
        final image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024.0,
          maxHeight: 1024.0,
          imageQuality: 100, // Keep original quality for PNG
        );

        return image;
      } else if (source == 'gallery') {
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024.0,
          maxHeight: 1024.0,
          imageQuality: 100, // Keep original quality for PNG
        );

        return image;
      }

      return null;
    } catch (e) {
      SnackBarUtils.showError(context, 'Failed to pick image: ${e.toString()}');
      return null;
    }
  }

  Future<bool> _isRunningOnSimulator() async {
    try {
      // Simple check - if camera fails, likely simulator
      final ImagePicker picker = ImagePicker();
      final result = await picker.pickImage(source: ImageSource.camera);
      return false; // If we get here, camera works
    } catch (e) {
      return true; // If error, likely simulator
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final success = await profileProvider.uploadProfileImage(imageFile);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          SnackBarUtils.showSuccess(
            context,
            'Profile image updated successfully!',
          );
          // Refresh both profile and auth data to update the UI
          await Future.wait([
            profileProvider.refreshProfileData(),
            Provider.of<AuthProvider>(context, listen: false).getProfile(),
          ]);
        } else {
          SnackBarUtils.showError(
            context,
            profileProvider.error ?? 'Failed to update profile image',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          'Error uploading image: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final success = await profileProvider.removeProfileImage();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          SnackBarUtils.showSuccess(
            context,
            'Profile image removed successfully',
          );
          // Refresh both profile and auth data to update the UI
          await Future.wait([
            profileProvider.refreshProfileData(),
            Provider.of<AuthProvider>(context, listen: false).getProfile(),
          ]);
        } else {
          SnackBarUtils.showError(
            context,
            profileProvider.error ?? 'Failed to remove profile image',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(
          context,
          'Error removing image: ${e.toString()}',
        );
      }
    }
  }

  /// Check if any changes have been made to the profile
  bool _hasChanges(User user) {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    
    return newName != user.name ||
           (_shouldSendEmailUpdate(user) && newEmail != user.email) ||
           (_shouldSendPhoneUpdate(user) && newPhone != (user.phone ?? ''));
  }

  bool _areChangesValid(User user) {
    final originalEmail = user.email;
    final originalPhone = user.phone;
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();
    
    // If user has only email verified, email should not be changed
    if (user.isEmailVerified && !user.isPhoneVerified) {
      if (newEmail != originalEmail) {
        return false;
      }
    }
    
    // If user has only phone verified, phone should not be changed
    if (user.isPhoneVerified && !user.isEmailVerified) {
      if (newPhone != originalPhone) {
        return false;
      }
    }
    
    // Check if user is trying to change both verified fields when both are verified
    if (user.isEmailVerified && user.isPhoneVerified) {
      if (newEmail != originalEmail && newPhone != originalPhone) {
        return false;
      }
    }
    
    return true;
  }

  bool _shouldSendEmailUpdate(User user) {
    // If email is the only verified method, don't send update
    if (user.isEmailVerified && !user.isPhoneVerified) {
      return false;
    }
    return true;
  }

  bool _shouldSendPhoneUpdate(User user) {
    // If phone is the only verified method, don't send update
    if (user.isPhoneVerified && !user.isEmailVerified) {
      return false;
    }
    return true;
  }
}
