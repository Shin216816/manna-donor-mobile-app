import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/auth_header.dart';
import 'package:manna_donate_app/presentation/widgets/phone_input_field.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';

enum ResetMethod { email, phone }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _fullPhoneNumber;
  bool _loading = false;
  String? _message;
  String? _error;
  bool _isFormValid = false;
  ResetMethod _selectedMethod = ResetMethod.email;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _tabController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _tabAnimation;

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

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

    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _tabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _tabController, curve: Curves.easeInOut));

    _startAnimations();
    _validateForm();
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
    _tabController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      if (_selectedMethod == ResetMethod.email) {
        _isFormValid =
            _emailController.text.trim().isNotEmpty &&
            RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(_emailController.text.trim());
      } else {
        _isFormValid =
            _phoneController.text.trim().isNotEmpty &&
            RegExp(
              r'^\+?[\d\s\-\(\)]{10,}$',
            ).hasMatch(_phoneController.text.trim());
      }
    });
  }

  void _handleMethodChange(ResetMethod method) {
    setState(() {
      _selectedMethod = method;
      _error = null;
      _message = null;
    });
    _validateForm();
    _tabController.forward().then((_) => _tabController.reverse());
  }

  void _handleSubmit(String value) {
    _submit();
  }

  void _handleButtonPress() {
    _submit();
  }

  Future<void> _submit() async {
    final value = _selectedMethod == ResetMethod.email
        ? _emailController.text.trim()
        : _fullPhoneNumber ?? _phoneController.text.trim();

    if (value.isEmpty) {
      setState(() {
        _error = _selectedMethod == ResetMethod.email
            ? 'Please enter your email address'
            : 'Please enter your phone number';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final response = await authProvider.forgotPassword(
      email: _selectedMethod == ResetMethod.email ? value : null,
      phone: _selectedMethod == ResetMethod.phone ? value : null,
    );

    setState(() {
      _loading = false;
      if (response) {
        _message = _selectedMethod == ResetMethod.email
            ? 'Check your email for reset instructions.'
            : 'Check your phone for reset instructions.';
        // Navigate to OTP verification screen
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            context.go(
              '/verify-otp',
              extra: {
                'email': _selectedMethod == ResetMethod.email ? value : null,
                'phone': _selectedMethod == ResetMethod.phone ? value : null,
                'verificationMethod': _selectedMethod == ResetMethod.phone
                    ? 'phone'
                    : 'email',
                'isRegistration': false,
              },
            );
          }
        });
      } else {
        _error = 'Failed to send reset instructions. Please try again.';
      }
    });
  }

  Widget _buildMethodTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.sp),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _handleMethodChange(ResetMethod.email),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 8.sp),
                decoration: BoxDecoration(
                  color: _selectedMethod == ResetMethod.email
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.sp),
                    bottomLeft: Radius.circular(12.sp),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 18.sp,
                      color: _selectedMethod == ResetMethod.email
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Email',
                      style: AppTextStyles.getSubtitle(isDark: false).copyWith(
                        color: _selectedMethod == ResetMethod.email
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedMethod == ResetMethod.email
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _handleMethodChange(ResetMethod.phone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(vertical: 8.sp),
                decoration: BoxDecoration(
                  color: _selectedMethod == ResetMethod.phone
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12.sp),
                    bottomRight: Radius.circular(12.sp),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 18.sp,
                      color: _selectedMethod == ResetMethod.phone
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Phone',
                      style: AppTextStyles.getSubtitle(isDark: false).copyWith(
                        color: _selectedMethod == ResetMethod.phone
                            ? Colors.white
                            : Colors.grey[600],
                        fontWeight: _selectedMethod == ResetMethod.phone
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: <Widget>[
          // Header Section
          AuthHeader(
            title: 'Forgot Password',
            subtitle: '',
            showThemeToggle: true,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),

          // Content with top border radius and overlap
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Primary color background that fills the gap
                Positioned.fill(child: Container(color: AppColors.primary)),
                // Content container positioned to overlap header
                Positioned(
                  top: -40.sp,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.getBackgroundColor(isDark),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(24.sp),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: AppConstants.sectionSpacing * 2,
                            ),

                            // Welcome Title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Forgot Password?',
                                  style: AppTextStyles.getHeader(isDark: isDark)
                                      .copyWith(
                                        color: isDark
                                            ? AppColors.darkPrimary
                                            : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.smallSpacing),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Don\'t worry, we\'ll help you reset it',
                                  style:
                                      AppTextStyles.getSubtitle(
                                        isDark: isDark,
                                      ).copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : Colors.black87,
                                      ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.sectionSpacing),

                            // Method Selection Tabs
                            _buildMethodTabs(),

                            const SizedBox(height: AppConstants.sectionSpacing),

                            // Illustration with Decorative Dots
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SizedBox(
                                  height: 160,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color:
                                              (isDark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      AnimatedBuilder(
                                        animation: _pulseAnimation,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _pulseAnimation.value,
                                            child: Icon(
                                              _selectedMethod ==
                                                      ResetMethod.email
                                                  ? Icons.email
                                                  : Icons.phone,
                                              size: 64,
                                              color: isDark
                                                  ? AppColors.darkPrimary
                                                  : AppColors.primary,
                                            ),
                                          );
                                        },
                                      ),
                                      // Decorative Dots
                                      Positioned(
                                        top: 30,
                                        left: 60,
                                        child: _buildDot(Colors.orange, 14),
                                      ),
                                      Positioned(
                                        top: 20,
                                        right: 60,
                                        child: _buildDot(Colors.redAccent, 12),
                                      ),
                                      Positioned(
                                        bottom: 30,
                                        left: 40,
                                        child: _buildDot(Colors.tealAccent, 8),
                                      ),
                                      Positioned(
                                        bottom: 30,
                                        right: 40,
                                        child: _buildDot(Colors.blueAccent, 10),
                                      ),
                                      Positioned(
                                        top: 10,
                                        left: 100,
                                        child: _buildDot(Colors.deepPurple, 6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Input Fields
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 100),
                                    child: _selectedMethod == ResetMethod.email
                                        ? ModernInputField(
                                            key: const ValueKey('email'),
                                            controller: _emailController,
                                            label: 'Email',
                                            hint: 'Enter your email address',
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            enabled: true,
                                            prefixIcon: Icons.email_outlined,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: (value) =>
                                                _handleSubmit(value),
                                            onChanged: (value) {
                                              _validateForm();
                                            },
                                          )
                                        : PhoneInputField(
                                            key: const ValueKey('phone'),
                                            controller: _phoneController,
                                            label: 'Phone Number',
                                            hint: 'Enter your phone number',
                                            enabled: true,
                                            textInputAction:
                                                TextInputAction.done,
                                            onSubmitted: () =>
                                                _handleSubmit(''),
                                            onChanged: (value) {
                                              _fullPhoneNumber = value;
                                              _validateForm();
                                            },
                                            isDark: isDark,
                                          ),
                                  ),

                                  if (_message != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.success.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _message!,
                                            style: AppTextStyles.success(),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Redirecting to verification...',
                                            style:
                                                AppTextStyles.getCaption(
                                                  isDark: isDark,
                                                ).copyWith(
                                                  color: isDark
                                                      ? AppColors
                                                            .darkTextSecondary
                                                      : Colors.grey,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (_error != null)
                                    Container(
                                      margin: const EdgeInsets.only(
                                        top: 8,
                                        left: 4,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.error.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: AppTextStyles.error(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  const SizedBox(height: 24),

                                  ModernButton(
                                    text: 'Send Reset Instructions',
                                    onPressed: _handleButtonPress,
                                    isLoading: _loading,
                                    disabled: !_isFormValid,
                                    icon: Icons.send,
                                    width: double.infinity,
                                    size: ButtonSize.medium,
                                  ),

                                  const SizedBox(height: 16),

                                  TextButton(
                                    onPressed: () {
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Back to login',
                                      style:
                                          AppTextStyles.getSubtitle(
                                            isDark: isDark,
                                          ).copyWith(
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppConstants.sectionSpacing),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
