import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/core/utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  bool _isKeyboardVisible = false;

  // Form validation state
  bool _isFormValid = false;
  bool _currentPasswordValid = false;
  bool _newPasswordValid = false;
  bool _confirmPasswordValid = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
  }

  void _initializeAnimations() {
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

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _setupKeyboardListener() {
    KeyboardVisibilityController().onChange.listen((bool visible) {
      if (mounted) {
        setState(() {
          _isKeyboardVisible = visible;
        });
      }
    });
  }

  void _validateCurrentPassword(String value) {
    setState(() {
      _currentPasswordValid = value.isNotEmpty;
      _checkFormValidity();
    });
  }

  void _validateNewPassword(String value) {
    setState(() {
      _newPasswordValid =
          value.length >= 8 &&
          RegExp(
            r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
          ).hasMatch(value);
      _checkFormValidity();
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _confirmPasswordValid =
          value == _newPasswordController.text && value.isNotEmpty;
      _checkFormValidity();
    });
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _newPasswordValid && _confirmPasswordValid;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await authProvider.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (response) {
        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Password changed successfully!',
            backgroundColor: Colors.green,
          );
          // Clear the form
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          // Navigate back to profile page
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              try {
                context.go('/profile');
              } catch (e) {
                // Fallback to pop
                context.pop();
              }
            }
          });
        }
      } else {
        if (mounted) {
          AppUtils.showSnackBar(
            context,
            'Failed to change password. Please try again.',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppUtils.showSnackBar(
          context,
          'An error occurred while changing password: ${e.toString()}',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildSecurityIcon(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 80.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security,
              size: 40.sp,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = _calculatePasswordStrength(password);
    final color = strength == 'weak'
        ? Colors.red
        : strength == 'medium'
        ? Colors.orange
        : Colors.green;
    final text = strength == 'weak'
        ? 'Weak'
        : strength == 'medium'
        ? 'Medium'
        : 'Strong';

    return Container(
      margin: EdgeInsets.only(top: 8.sp),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: strength == 'weak'
                  ? 0.33
                  : strength == 'medium'
                  ? 0.66
                  : 1.0,
              backgroundColor: Colors.grey.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(width: 12.sp),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculatePasswordStrength(String password) {
    if (password.length < 8) return 'weak';
    if (password.length < 12) return 'medium';
    return 'strong';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      appBar: AppHeader(
        title: 'Change Password',
        showThemeToggle: true,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            children: [
              // Subtitle
              Text(
                'Update your account security',
                style: AppTextStyles.getBody(isDark: isDark).copyWith(
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.7),
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.sp),

              // Security Icon Animation
              if (!_isKeyboardVisible) ...[
                AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            _buildSecurityIcon(isDark),
                            SizedBox(height: 24.sp),
                            Text(
                              'Secure Your Account',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 20.sp,
                                color: AppColors.getOnSurfaceColor(isDark),
                              ),
                            ),
                            SizedBox(height: 8.sp),
                            Text(
                              'Choose a strong password to protect your account',
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.getOnSurfaceColor(
                                  isDark,
                                ).withValues(alpha: 0.7),
                                isDark: isDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 32.sp),
              ],

              // Password Change Form
              AnimatedBuilder(
                animation: _slideController,
                builder: (context, child) {
                  return SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Current Password Field
                            ModernInputField(
                              controller: _currentPasswordController,
                              label: 'Current Password',
                              hint: 'Enter your current password',
                              prefixIcon: Icons.lock_outlined,
                              suffixIcon: _obscureCurrentPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              obscureText: _obscureCurrentPassword,
                              textInputAction: TextInputAction.next,
                              onSuffixIconPressed: () {
                                setState(() {
                                  _obscureCurrentPassword =
                                      !_obscureCurrentPassword;
                                });
                              },
                              onChanged: _validateCurrentPassword,
                              isRequired: false,
                              autovalidateMode: true,
                              isDark: isDark,
                            ),

                            SizedBox(height: 20.sp),

                            // New Password Field
                            ModernInputField(
                              controller: _newPasswordController,
                              label: 'New Password',
                              hint: 'Enter your new password',
                              prefixIcon: Icons.lock_outlined,
                              suffixIcon: _obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              obscureText: _obscureNewPassword,
                              textInputAction: TextInputAction.next,
                              onSuffixIconPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                              onChanged: _validateNewPassword,
                              isRequired: true,
                              autovalidateMode: true,
                              isDark: isDark,
                            ),

                            // Password Strength Indicator
                            _buildPasswordStrengthIndicator(
                              _newPasswordController.text,
                            ),

                            SizedBox(height: 20.sp),

                            // Confirm New Password Field
                            ModernInputField(
                              controller: _confirmPasswordController,
                              label: 'Confirm New Password',
                              hint: 'Confirm your new password',
                              prefixIcon: Icons.lock_outlined,
                              suffixIcon: _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onSuffixIconPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              onChanged: _validateConfirmPassword,
                              isRequired: true,
                              autovalidateMode: true,
                              isDark: isDark,
                            ),

                            SizedBox(height: 32.sp),

                            // Change Password Button
                            ModernButton(
                              text: 'Update Password',
                              onPressed: _changePassword,
                              isLoading: _loading,
                              disabled: !_isFormValid,
                              icon: Icons.security,
                              width: double.infinity,
                              height: 40.sp,
                              isDark: isDark,
                            ),

                            SizedBox(height: 16.sp),

                            // Cancel Button
                            ModernButton(
                              text: 'Cancel',
                              onPressed: () => context.go('/profile'),
                              variant: ButtonVariant.outlined,
                              width: double.infinity,
                              height: 40.sp,
                              isDark: isDark,
                            ),

                            SizedBox(height: 24.sp),

                            // Security Tips
                            Container(
                              padding: EdgeInsets.all(16.sp),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkSurfaceVariant
                                            : AppColors.surfaceVariant)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: AppColors.getOutlineColor(
                                    isDark,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16.sp,
                                        color: AppColors.getOnSurfaceColor(
                                          isDark,
                                        ).withValues(alpha: 0.7),
                                      ),
                                      SizedBox(width: 8.sp),
                                      Text(
                                        'Password Tips',
                                        style: AppTextStyles.bodyMedium(
                                          weight: FontWeight.w600,
                                          color: AppColors.getOnSurfaceColor(
                                            isDark,
                                          ),
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Text(
                                    '• Use at least 8 characters\n• Include uppercase and lowercase letters\n• Add numbers and special characters\n• Avoid common words and patterns',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.getOnSurfaceColor(
                                        isDark,
                                      ).withValues(alpha: 0.7),
                                      isDark: isDark,
                                    ).copyWith(height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
