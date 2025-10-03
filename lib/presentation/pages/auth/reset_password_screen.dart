import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/auth_header.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _errorMessage;
  bool _showError = false;
  String? _email;
  String? _phone;

  // Form validation state
  bool _isFormValid = false;
  bool _newPasswordValid = false;
  bool _confirmPasswordValid = false;

  @override
  void initState() {
    super.initState();
    // Get email, phone, and code from route parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        if (extra['email'] != null) {
          _email = extra['email'] as String;
          _emailController.text = _email!;
        }
        if (extra['phone'] != null) {
          _phone = extra['phone'] as String;
          // If no email, use phone in the controller
          if (_email == null) {
            _emailController.text = _phone!;
          }
        }
        if (extra['code'] != null) {
          _codeController.text = extra['code'] as String;
        }
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (errorString.contains('422') || errorString.contains('unprocessable')) {
      return 'Invalid data provided. Please check your information and try again.';
    }
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return 'Invalid request. Please check your information and try again.';
    }
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please try again.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. Please try again.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Service not found. Please try again later.';
    }
    if (errorString.contains('500') || errorString.contains('server')) {
      return 'Server error. Please try again later.';
    }
    if (errorString.contains('password')) {
      return 'Password requirements not met. Please ensure your password is at least 8 characters long.';
    }
    if (errorString.contains('code') || errorString.contains('otp')) {
      return 'Invalid verification code. Please check the code and try again.';
    }
    if (errorString.contains('email')) {
      return 'Invalid email address. Please check your email and try again.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  void _clearError() {
    setState(() {
      _errorMessage = null;
      _showError = false;
    });
  }

  void _validateNewPassword(String value) {
    _clearError();
    setState(() {
      _newPasswordValid = value.length >= 8 &&
          RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$').hasMatch(value);
      _checkFormValidity();
    });
  }

  void _validateConfirmPassword(String value) {
    _clearError();
    setState(() {
      _confirmPasswordValid = value == _newPasswordController.text && value.isNotEmpty;
      _checkFormValidity();
    });
  }

  void _checkFormValidity() {
    setState(() {
      _isFormValid = _newPasswordValid && _confirmPasswordValid;
    });
  }

  Future<void> _submit() async {
    if (_email == null && _phone == null) {
      setState(() {
        _errorMessage = 'Contact information is required';
        _showError = true;
      });
      return;
    }

    if (_codeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Verification code is required';
        _showError = true;
      });
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'New password is required';
        _showError = true;
      });
      return;
    }

    if (_newPasswordController.text.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long';
        _showError = true;
      });
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _showError = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _errorMessage = null;
      _showError = false;
    });

    try {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only send the contact method that was used for the forgot password request
    String? emailToUse;
    String? phoneToUse;
    
    if (_email != null && _phone == null) {
      emailToUse = _email;
      phoneToUse = null;
    } else if (_phone != null && _email == null) {
      phoneToUse = _phone;
      emailToUse = null;
    } else {
      // If both are available, prefer the one that was used for verification
      emailToUse = _email;
      phoneToUse = _phone;
    }
    
    final response = await authProvider.resetPassword(
      email: emailToUse,
      phone: phoneToUse,
      accessCode: _codeController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

      setState(() {
        _loading = false;
        if (response) {
          final contactInfo = _email ?? _phone ?? 'your account';
          _message = 'Password reset successful!';
          _showErrorSnackBar('Password reset successful for $contactInfo!', isError: false);
          // Navigate to login after successful reset
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.go('/login');
            }
          });
        } else {
          _errorMessage = 'Failed to reset password. Please try again.';
          _showError = true;
          _showErrorSnackBar(_errorMessage!);
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = _getUserFriendlyErrorMessage(e);
        _showError = true;
      });
      _showErrorSnackBar(_errorMessage!);
    }
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
            title: 'Reset Password',
            subtitle: '',
            showThemeToggle: true,
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0),
          
          // Content with top border radius and overlap
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Primary color background that fills the gap
                Positioned.fill(
                  child: Container(
                    color: AppColors.primary,
                  ),
                ),
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
                            const SizedBox(height: AppConstants.sectionSpacing * 2),
                            
                            // Welcome Title
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Reset Password',
                                  style: AppTextStyles.getHeader(isDark: isDark).copyWith(
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: AppConstants.smallSpacing),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                                              child: Text(
                                _email != null 
                                    ? 'Enter your new password for $_email'
                                    : 'Enter your new password for $_phone',
                                style: AppTextStyles.getSubtitle(isDark: isDark).copyWith(
                                  color: isDark ? AppColors.darkTextSecondary : Colors.black87,
                                ),
                              ),
                              ),
                            ),
                            
                            const SizedBox(height: AppConstants.sectionSpacing),
                            
                            // Password Illustration with Decorative Dots
                            SizedBox(
                              height: 160,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock_reset,
                                    size: 64,
                                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                                  ),
                                  // Decorative Dots
                                  Positioned(
                                    top: 30,
                                    left: 60,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 20,
                                    right: 60,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 30,
                                    left: 40,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.tealAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 30,
                                    right: 40,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 100,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Input Fields
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  // Contact information field (read-only)
                                  ModernInputField(
                                    controller: _emailController,
                                    label: _email != null ? 'Email' : 'Phone',
                                    hint: _email != null ? 'Your email address' : 'Your phone number',
                                    prefixIcon: _email != null ? Icons.email_outlined : Icons.phone_outlined,
                                    keyboardType: _email != null ? TextInputType.emailAddress : TextInputType.phone,
                                    enabled: false, // Pre-filled and disabled
                                    isRequired: true,
                                    autovalidateMode: true,
                                    showSuccessIcon: true,
                                    isDark: isDark,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Verification code field (read-only)
                                  ModernInputField(
                                    controller: _codeController,
                                    label: 'Verification Code',
                                    hint: '6-digit verification code',
                                    prefixIcon: Icons.security,
                                    keyboardType: TextInputType.number,
                                    enabled: false, // Pre-filled and disabled
                                    isRequired: true,
                                    autovalidateMode: true,
                                    showSuccessIcon: true,
                                    isDark: isDark,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // New password field
                                  ModernInputField(
                                    controller: _newPasswordController,
                                    label: 'New Password',
                                    hint: 'Enter your new password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: true,
                                    textInputAction: TextInputAction.next,
                                    enabled: true,
                                    isRequired: true,
                                    autovalidateMode: true,
                                    showSuccessIcon: true,
                                    isDark: isDark,
                                    onChanged: _validateNewPassword,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Confirm password field
                                  ModernInputField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hint: 'Confirm your new password',
                                    prefixIcon: Icons.lock_outline,
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    enabled: true,
                                    isRequired: true,
                                    autovalidateMode: true,
                                    showSuccessIcon: true,
                                    isDark: isDark,
                                    onChanged: _validateConfirmPassword,
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Error Display
                                  if (_showError && _errorMessage != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.error.withValues(alpha: 0.3),
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: AppTextStyles.getBody(isDark: isDark).copyWith(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _clearError,
                                            icon: Icon(
                                              Icons.close,
                                              color: AppColors.error,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  // Success Message
                                  if (_message != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.success.withValues(alpha: 0.3),
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
                                          EnhancedLoadingWidget(
                                            type: LoadingType.spinner,
                                            message: 'Redirecting to login...',
                                            color: AppColors.success,
                                            size: 40,
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  
                                  ModernButton(
                                    text: 'Reset Password',
                                    onPressed: _submit,
                                    isLoading: _loading,
                                    disabled: !_isFormValid,
                                    width: double.infinity,
                                    height: 40.sp,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  TextButton(
                                    onPressed: () {
                                      context.go('/login');
                                    },
                                    child: Text(
                                      'Back to Login',
                                      style: AppTextStyles.getSubtitle(isDark: isDark).copyWith(
                                        color: isDark ? AppColors.darkTextSecondary : Colors.grey[500],
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