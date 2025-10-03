import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/auth_header.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;
  String? _email;
  String? _phone;
  String? _verificationMethod;
  bool _isRegistration = false;
  int _countdown = 120; // 120 seconds countdown to match backend expiration
  Timer? _timer;
  bool _canResend = false;
  bool _isFormValid = false; // Add form validation state

  @override
  void initState() {
    super.initState();
    // Get email, phone, and verification type from route parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        setState(() {
          _email = extra['email'] as String?;
          _phone = extra['phone'] as String?;
          _verificationMethod =
              extra['verificationMethod'] as String? ?? 'email';
          _isRegistration = extra['isRegistration'] as bool? ?? false;
        });
      }
    });

    // Start countdown timer
    _startCountdown();

    // Add listener for auto-submit when 6 digits are entered
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdown = 120; // 120 seconds to match backend expiration
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatCountdown() {
    final minutes = _countdown ~/ 60;
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    // Check if we have either email or phone
    if (_email == null && _phone == null) {
      setState(() {
        _error = 'Contact information not found. Please go back and try again.';
      });
      return;
    }

    if (_codeController.text.isEmpty) {
      setState(() {
        _error = 'Please enter the verification code';
      });
      return;
    }

    if (_codeController.text.length != 6) {
      setState(() {
        _error = 'Please enter a valid 6-character verification code';
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isRegistration) {
      // Handle registration verification
      String? contactInfo;
      if (_verificationMethod == 'phone' && _phone != null) {
        contactInfo = _phone;
      } else if (_email != null) {
        contactInfo = _email;
      }

      if (contactInfo == null) {
        setState(() {
          _loading = false;
          _error = 'Contact information not found. Please try again.';
        });
        return;
      }

      final success = await authProvider.confirmRegistration(
        email: _verificationMethod == 'phone' ? '' : contactInfo,
        phone: _verificationMethod == 'phone' ? contactInfo : '',
        accessCode: _codeController.text,
      );

      setState(() {
        _loading = false;
        if (success) {
          _message = 'Account verified successfully!';
          context.go('/home');
          // Navigate to home after successful registration verification
        } else {
          _error = 'Invalid verification code. Please try again.';
        }
      });
    } else {
      // Handle password reset verification
      if (_email == null && _phone == null) {
        setState(() {
          _loading = false;
          _error = 'Contact information not found for password reset.';
        });
        return;
      }

      // Determine which contact method to use based on verification method
      String? emailToUse;
      String? phoneToUse;

      // Only send the contact method that was used for the forgot password request
      if (_verificationMethod == 'phone' && _phone != null) {
        phoneToUse = _phone;
        emailToUse = null; // Don't send email when using phone
      } else if (_verificationMethod == 'email' && _email != null) {
        emailToUse = _email;
        phoneToUse = null; // Don't send phone when using email
      } else {
        // Fallback: use whatever is available
        if (_phone != null) {
          phoneToUse = _phone;
          emailToUse = null;
        } else if (_email != null) {
          emailToUse = _email;
          phoneToUse = null;
        }
      }

      final response = await authProvider.verifyOtp(
        email: emailToUse,
        phone: phoneToUse,
        accessCode: _codeController.text,
      );

      setState(() {
        _loading = false;
        if (response) {
          _message = 'Code verified successfully!';
          // Navigate to reset password screen with contact info and code
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go(
                '/reset-password',
                extra: {
                  'email': emailToUse,
                  'phone': phoneToUse,
                  'code': _codeController.text,
                },
              );
            }
          });
        } else {
          _error = 'Invalid verification code. Please try again.';
        }
      });
    }
  }

  Future<void> _resendCode() async {
    // Check if we have either email or phone
    if (_email == null && _phone == null) {
      setState(() {
        _error = 'Contact information not found. Please go back and try again.';
      });
      return;
    }

    if (!_canResend) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isRegistration) {
      // Handle registration code resend
      String? contactInfo;
      if (_verificationMethod == 'phone' && _phone != null) {
        contactInfo = _phone;
      } else if (_email != null) {
        contactInfo = _email;
      }

      if (contactInfo == null) {
        setState(() {
          _loading = false;
          _error = 'Contact information not found. Please try again.';
        });
        return;
      }

      final success = await authProvider.resendRegistrationCode(
        email: _verificationMethod == 'phone' ? '' : contactInfo,
        phone: _verificationMethod == 'phone' ? contactInfo : '',
      );

      setState(() {
        _loading = false;
        if (success) {
          final method = _verificationMethod == 'phone' ? 'SMS' : 'email';
          _message = 'Verification code sent again. Please check your $method.';
          // Clear the verification code input field
          _codeController.clear();
          // Clear any previous error
          _error = null;
          // Restart countdown
          _startCountdown();
        } else {
          _error = 'Failed to resend verification code. Please try again.';
        }
      });
    } else {
      // Handle password reset code resend
      if (_email == null && _phone == null) {
        setState(() {
          _loading = false;
          _error = 'Contact information not found for password reset.';
        });
        return;
      }

      // Determine which contact method to use for resend
      String? emailToUse;
      String? phoneToUse;

      // Only send the contact method that was used for the forgot password request
      if (_verificationMethod == 'phone' && _phone != null) {
        phoneToUse = _phone;
        emailToUse = null; // Don't send email when using phone
      } else if (_verificationMethod == 'email' && _email != null) {
        emailToUse = _email;
        phoneToUse = null; // Don't send phone when using email
      } else {
        // Fallback: use whatever is available
        if (_phone != null) {
          phoneToUse = _phone;
          emailToUse = null;
        } else if (_email != null) {
          emailToUse = _email;
          phoneToUse = null;
        }
      }

      final response = await authProvider.forgotPassword(
        email: emailToUse,
        phone: phoneToUse,
      );

      setState(() {
        _loading = false;
        if (response) {
          final method = _verificationMethod == 'phone' ? 'SMS' : 'email';
          _message = 'Verification code sent again. Please check your $method.';
          // Clear the verification code input field
          _codeController.clear();
          // Clear any previous error
          _error = null;
          // Restart countdown
          _startCountdown();
        } else {
          _error = 'Failed to resend verification code. Please try again.';
        }
      });
    }
  }

  void _onCodeChanged() {
    // Update form validation state - 6 characters (letters and numbers)
    setState(() {
      _isFormValid = _codeController.text.length == 6;
    });

    if (_codeController.text.length == 6) {
      // Auto-submit after a short delay to allow the user to see the last character
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _codeController.text.length == 6) {
          _verifyOtp();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Determine contact info and method
    String contactInfo = '';
    String method = 'email';

    if (_verificationMethod == 'phone' && _phone != null) {
      contactInfo = _phone!;
      method = 'phone';
    } else if (_email != null) {
      contactInfo = _email!;
      method = 'email';
    }

    final title = _isRegistration
        ? 'Verify ${method == 'phone' ? 'Phone' : 'Email'}'
        : 'Verify Code';
    final subtitle = _isRegistration
        ? 'Enter the verification code sent to your $method to activate your account'
        : 'Enter the verification code sent to your $method';

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: <Widget>[
          // Header Section
          AuthHeader(
            title: title,
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
                                  title,
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
                                  subtitle,
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

                            // Email Illustration with Decorative Dots
                            SizedBox(
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
                                  Icon(
                                    Icons.verified_user,
                                    size: 64,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                children: [
                                  if (contactInfo.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            (isDark
                                                    ? AppColors.darkPrimary
                                                    : AppColors.primary)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              (isDark
                                                      ? AppColors.darkPrimary
                                                      : AppColors.primary)
                                                  .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            method == 'phone'
                                                ? Icons.phone_outlined
                                                : Icons.email_outlined,
                                            color: isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Code sent to:',
                                                  style:
                                                      AppTextStyles.getCaption(
                                                        isDark: isDark,
                                                      ).copyWith(
                                                        color: isDark
                                                            ? AppColors
                                                                  .darkTextSecondary
                                                            : Colors.grey[600],
                                                      ),
                                                ),
                                                Text(
                                                  contactInfo,
                                                  style:
                                                      AppTextStyles.getBody(
                                                        isDark: isDark,
                                                      ).copyWith(
                                                        color: isDark
                                                            ? AppColors
                                                                  .darkTextSecondary
                                                            : Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ModernInputField(
                                    controller: _codeController,
                                    label: 'Verification Code',
                                    hint: 'Enter 6-character code',
                                    prefixIcon: Icons.security,
                                    keyboardType: TextInputType.text,
                                    maxLength: 6,
                                    textInputAction: TextInputAction.done,
                                    enabled: true,
                                    isRequired: true,
                                    autovalidateMode: true,
                                    showSuccessIcon: true,
                                    isDark: isDark,
                                    // Allow letters and numbers only
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9]'),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Countdown timer
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkSurface
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDark
                                            ? AppColors.darkBorder
                                            : Colors.grey[300]!,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 18,
                                          color: _countdown > 30
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Resend available in: ${_formatCountdown()}',
                                          style:
                                              AppTextStyles.getBody(
                                                isDark: isDark,
                                              ).copyWith(
                                                color: _countdown > 30
                                                    ? AppColors.success
                                                    : AppColors.warning,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  if (_message != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
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
                                          EnhancedLoadingWidget(
                                            type: LoadingType.spinner,
                                            message: _isRegistration
                                                ? 'Redirecting to home...'
                                                : 'Redirecting to reset password...',
                                            color: AppColors.success,
                                            size: 40,
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (_error != null)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
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
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: AppTextStyles.error(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ModernButton(
                                    text: 'Verify Code',
                                    onPressed: _verifyOtp,
                                    isLoading: _loading,
                                    disabled: !_isFormValid,
                                    width: double.infinity,
                                    height: 40.sp,
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _canResend
                                            ? _resendCode
                                            : null,
                                        child: Text(
                                          'Resend Code',
                                          style:
                                              AppTextStyles.getSubtitle(
                                                isDark: isDark,
                                              ).copyWith(
                                                color: _canResend
                                                    ? (isDark
                                                          ? AppColors
                                                                .darkPrimary
                                                          : AppColors.primary)
                                                    : (isDark
                                                          ? AppColors
                                                                .darkTextSecondary
                                                          : Colors.grey),
                                                fontSize: 14,
                                              ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context.go(
                                            _isRegistration
                                                ? '/register'
                                                : '/forgot-password',
                                          );
                                        },
                                        child: Text(
                                          'Back',
                                          style:
                                              AppTextStyles.getSubtitle(
                                                isDark: isDark,
                                              ).copyWith(
                                                color: isDark
                                                    ? AppColors
                                                          .darkTextSecondary
                                                    : Colors.grey[500],
                                                fontSize: 14,
                                              ),
                                        ),
                                      ),
                                    ],
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
