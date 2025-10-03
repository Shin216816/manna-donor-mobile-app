import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/auth_header.dart';
import 'package:manna_donate_app/presentation/widgets/phone_input_field.dart';

import 'package:manna_donate_app/core/user_data_clearer.dart';

enum ResetMethod { email, phone }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();



  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isKeyboardVisible = false;
  String? _errorMessage;
  bool _showError = false;

  // Phone verification enhancements
  ResetMethod _selectedMethod = ResetMethod.email;
  bool _phoneNumberValid = false;
  String _selectedCountryCode = '+1'; // Default to US
  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+91', 'country': 'IN', 'flag': '🇮🇳'},
    {'code': '+86', 'country': 'CN', 'flag': '🇨🇳'},
    {'code': '+81', 'country': 'JP', 'flag': '🇯🇵'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪'},
    {'code': '+33', 'country': 'FR', 'flag': '🇫🇷'},
    {'code': '+39', 'country': 'IT', 'flag': '🇮🇹'},
    {'code': '+34', 'country': 'ES', 'flag': '🇪🇸'},
    {'code': '+61', 'country': 'AU', 'flag': '🇦🇺'},
  ];

  // Enhanced validation state tracking
  bool _isFormValid = false;
  bool _firstNameValid = false;
  bool _lastNameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  // Password strength tracking
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasMinLength = false;
  int _passwordStrength = 0; // 0-4 scale

  // Field focus tracking for better UX
  bool _firstNameFocused = false;
  bool _lastNameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;
  bool _confirmPasswordFocused = false;

  // Enhanced error messages with specific guidance
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;

  late AnimationController _animationController;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Enhanced error handling
  void _showErrorSnackBar(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Phone number validation and formatting
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }

    // Basic phone number format validation
    final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
    if (!phoneRegex.hasMatch(_selectedCountryCode + digitsOnly)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Format based on length
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1')) {
      return '+1 (${digitsOnly.substring(1, 4)}) ${digitsOnly.substring(4, 7)}-${digitsOnly.substring(7)}';
    }

    return phone; // Return as-is if can't format
  }

  // Enhanced field validation methods with detailed feedback
  void _validateFirstName(String? value) {
    if (value == null) return;
    _clearError();

    final trimmedValue = value.trim();
    setState(() {
      if (trimmedValue.isEmpty) {
        _firstNameValid = false;
        _firstNameError = 'First name is required';
      } else if (trimmedValue.length < 2) {
        _firstNameValid = false;
        _firstNameError = 'First name must be at least 2 characters';
      } else if (trimmedValue.length > 50) {
        _firstNameValid = false;
        _firstNameError = 'First name must be less than 50 characters';
      } else if (!RegExp(r'^[a-zA-Z\s\-\.\x27]+$').hasMatch(trimmedValue)) {
        _firstNameValid = false;
        _firstNameError =
            'First name can only contain letters, spaces, hyphens, dots, and apostrophes';
      } else {
        _firstNameValid = true;
        _firstNameError = null;
      }
      _checkFormValidity();
    });
  }

  void _validateLastName(String? value) {
    if (value == null) return;
    _clearError();

    final trimmedValue = value.trim();
    setState(() {
      if (trimmedValue.isEmpty) {
        _lastNameValid = false;
        _lastNameError = 'Last name is required';
      } else if (trimmedValue.length < 2) {
        _lastNameValid = false;
        _lastNameError = 'Last name must be at least 2 characters';
      } else if (trimmedValue.length > 50) {
        _lastNameValid = false;
        _lastNameError = 'Last name must be less than 50 characters';
      } else if (!RegExp(r'^[a-zA-Z\s\-\.\x27]+$').hasMatch(trimmedValue)) {
        _lastNameValid = false;
        _lastNameError =
            'Last name can only contain letters, spaces, hyphens, dots, and apostrophes';
      } else {
        _lastNameValid = true;
        _lastNameError = null;
      }
      _checkFormValidity();
    });
  }

  void _validateEmail(String? value) {
    if (value == null) return;
    _clearError();

    final trimmedValue = value.trim();
    setState(() {
      if (trimmedValue.isEmpty) {
        _emailValid = false;
        _emailError = 'Email address is required';
      } else if (!RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(trimmedValue)) {
        _emailValid = false;
        _emailError =
            'Please enter a valid email address (e.g., user@example.com)';
      } else if (trimmedValue.length > 254) {
        _emailValid = false;
        _emailError = 'Email address is too long';
      } else {
        _emailValid = true;
        _emailError = null;
      }
      _checkFormValidity();
    });
  }

  void _validatePasswordRealTime(String? value) {
    if (value == null) return;
    _clearError();

    setState(() {
      // Check individual requirements
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
      _hasNumber = RegExp(r'[0-9]').hasMatch(value);
      _hasSpecialChar = RegExp(
        r'[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]',
      ).hasMatch(value);
      _hasMinLength = value.length >= 8;

      // Calculate password strength (0-4)
      _passwordStrength = 0;
      if (_hasMinLength) _passwordStrength++;
      if (_hasUppercase) _passwordStrength++;
      if (_hasLowercase) _passwordStrength++;
      if (_hasNumber) _passwordStrength++;
      if (_hasSpecialChar) _passwordStrength++;

      // Determine if password is valid
      _passwordValid =
          _hasMinLength &&
          _hasUppercase &&
          _hasLowercase &&
          _hasNumber &&
          _hasSpecialChar;

      // Set specific error message
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (!_hasMinLength) {
        _passwordError = 'Password must be at least 8 characters long';
      } else if (!_hasUppercase) {
        _passwordError =
            'Password must contain at least one uppercase letter (A-Z)';
      } else if (!_hasLowercase) {
        _passwordError =
            'Password must contain at least one lowercase letter (a-z)';
      } else if (!_hasNumber) {
        _passwordError = 'Password must contain at least one number (0-9)';
      } else if (!_hasSpecialChar) {
        _passwordError =
            'Password must contain at least one special character (!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?)';
      } else {
        _passwordError = null;
      }

      _checkFormValidity();
    });
  }

  void _validateConfirmPasswordRealTime(String? value) {
    if (value == null) return;
    _clearError();

    setState(() {
      if (value.isEmpty) {
        _confirmPasswordValid = false;
        _confirmPasswordError =
            null; // Don't show error for empty field initially
      } else if (value != _passwordController.text) {
        _confirmPasswordValid = false;
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordValid = true;
        _confirmPasswordError = null;
      }
      _checkFormValidity();
    });
  }

  void _onPhoneNumberChanged(String? value) {
    if (value == null) return;
    _clearError();

    final validationResult = _validatePhoneNumber(value);
    setState(() {
      _phoneNumberValid = validationResult == null;
      _phoneError = validationResult;
      _checkFormValidity();
    });
  }



  void _handleMethodChange(ResetMethod method) {
    _clearError(); // Clear any previous errors
    setState(() {
      _selectedMethod = method;
      // Clear the other field when switching
      if (method == ResetMethod.phone) {
        _emailController.clear();
        _emailValid = false;
      } else {
        _phoneController.clear();
        _phoneNumberValid = false;
      }
      _checkFormValidity();
    });
  }

  Widget _buildMethodTabs() {
    return Container(
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

  // Field validation methods
  void _checkFormValidity() {
    setState(() {
      bool basicFieldsValid =
          _firstNameValid &&
          _lastNameValid &&
          _passwordValid &&
          _confirmPasswordValid;

      if (_selectedMethod == ResetMethod.phone) {
        _isFormValid = basicFieldsValid && _phoneNumberValid && _agreeToTerms;
      } else {
        _isFormValid = basicFieldsValid && _emailValid && _agreeToTerms;
      }
    });
  }

  // Calculate form completion percentage
  double _getFormCompletionPercentage() {
    int totalFields =
        5; // firstName, lastName, email/phone, password, confirmPassword
    int completedFields = 0;

    if (_firstNameValid) completedFields++;
    if (_lastNameValid) completedFields++;
    if (_selectedMethod == ResetMethod.phone ? _phoneNumberValid : _emailValid)
      completedFields++;
    if (_passwordValid) completedFields++;
    if (_confirmPasswordValid) completedFields++;

    return completedFields / totalFields;
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Authentication errors
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Authentication failed. Please check your credentials and try again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. Please contact support if this persists.';
    }

    // User already exists error - guide to resend code
    if (errorString.contains('already exists') ||
        errorString.contains('user exists') ||
        errorString.contains('409')) {
      return 'An account with this email/phone already exists. Please use "Resend Code" on the verification screen instead of registering again.';
    }

    // Email errors
    if (errorString.contains('email') && errorString.contains('already')) {
      return 'An account with this email already exists. Please try logging in instead.';
    }

    if (errorString.contains('email') && errorString.contains('invalid')) {
      return 'Please enter a valid email address.';
    }

    // Password errors
    if (errorString.contains('password') && errorString.contains('weak')) {
      return 'Password is too weak. Please choose a stronger password.';
    }

    if (errorString.contains('password') && errorString.contains('mismatch')) {
      return 'Passwords do not match. Please try again.';
    }

    // Server errors
    if (errorString.contains('500') || errorString.contains('server')) {
      return 'Server error occurred. Please try again later.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Default error message
    return 'An unexpected error occurred. Please try again.';
  }

  void _clearError() {
    setState(() {
      _showError = false;
      _errorMessage = null;
    });
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // Password strength indicator widget
  Widget _buildPasswordStrengthIndicator() {
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    String strengthText;
    Color strengthColor;

    switch (_passwordStrength) {
      case 0:
      case 1:
        strengthText = 'Very Weak';
        strengthColor = Colors.red;
        break;
      case 2:
        strengthText = 'Weak';
        strengthColor = Colors.orange;
        break;
      case 3:
        strengthText = 'Fair';
        strengthColor = Colors.yellow.shade700;
        break;
      case 4:
        strengthText = 'Good';
        strengthColor = Colors.lightGreen;
        break;
      case 5:
        strengthText = 'Strong';
        strengthColor = Colors.green;
        break;
      default:
        strengthText = 'Very Weak';
        strengthColor = Colors.red;
    }

    return Container(
      margin: EdgeInsets.only(top: 8.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: strengthColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: AppTextStyles.caption(
                  color: AppColors.getOnSurfaceColor(
                    isDark,
                  ).withValues(alpha: 0.7),
                  isDark: isDark,
                ),
              ),
              Text(
                strengthText,
                style: AppTextStyles.caption(
                  color: strengthColor,
                  isDark: isDark,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          // Strength bar
          Row(
            children: List.generate(5, (index) {
              Color barColor;
              if (index < _passwordStrength) {
                barColor = strengthColor;
              } else {
                barColor = isDark
                    ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.3);
              }

              return Expanded(
                child: Container(
                  height: 4.sp,
                  margin: EdgeInsets.only(right: index < 4 ? 4.sp : 0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(2.sp),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.sp),
          // Requirements checklist
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequirementItem(
                'At least 8 characters',
                _hasMinLength,
                isDark,
              ),
              _buildRequirementItem(
                'One uppercase letter (A-Z)',
                _hasUppercase,
                isDark,
              ),
              _buildRequirementItem(
                'One lowercase letter (a-z)',
                _hasLowercase,
                isDark,
              ),
              _buildRequirementItem('One number (0-9)', _hasNumber, isDark),
              _buildRequirementItem(
                'One special character (!@#\$%^&*)',
                _hasSpecialChar,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.sp),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16.sp,
            color: isMet
                ? Colors.green
                : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.5),
          ),
          SizedBox(width: 8.sp),
          Text(
            text,
            style: AppTextStyles.caption(
              color: isMet
                  ? Colors.green
                  : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.7),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  // Compact form completion indicator widget
  Widget _buildFormCompletionIndicator() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final completionPercentage = _getFormCompletionPercentage();
    final isComplete = completionPercentage == 1.0;

    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.card,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.3)
              : AppColors.getOutlineColor(isDark).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.assignment_outlined,
            size: 16.sp,
            color: isComplete
                ? Colors.green
                : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.6),
          ),
          SizedBox(width: 8.sp),
          Expanded(
            child: Text(
              '${(completionPercentage * 100).toInt()}% complete',
              style: AppTextStyles.caption(
                color: AppColors.getOnSurfaceColor(
                  isDark,
                ).withValues(alpha: 0.7),
                isDark: isDark,
              ),
            ),
          ),
          // Simple progress bar
          Container(
            width: 60.sp,
            height: 4.sp,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.2)
                  : AppColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: completionPercentage,
              child: Container(
                decoration: BoxDecoration(
                  color: isComplete ? Colors.green : AppColors.primary,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldStatusIndicator(
    String fieldName,
    bool isValid,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.circle_outlined,
          size: 16.sp,
          color: isValid
              ? Colors.green
              : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.4),
        ),
        SizedBox(width: 4.sp),
        Text(
          fieldName,
          style: AppTextStyles.caption(
            color: isValid
                ? Colors.green
                : AppColors.getOnSurfaceColor(isDark).withValues(alpha: 0.6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  // Enhanced success message display
  Widget _buildSuccessMessage() {
    if (!_isFormValid) return const SizedBox.shrink();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: EdgeInsets.only(bottom: 20.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              'All fields are valid! You can now create your account.',
              style: AppTextStyles.bodyMedium(
                isDark: isDark,
              ).copyWith(color: Colors.green, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2, end: 0);
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupKeyboardListener();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    // Add focus listeners for better UX
    _firstNameController.addListener(() {
      if (_firstNameController.text.isNotEmpty) {
        _validateFirstName(_firstNameController.text);
      }
    });

    _lastNameController.addListener(() {
      if (_lastNameController.text.isNotEmpty) {
        _validateLastName(_lastNameController.text);
      }
    });

    _emailController.addListener(() {
      if (_emailController.text.isNotEmpty) {
        _validateEmail(_emailController.text);
      }
    });

    _passwordController.addListener(() {
      if (_passwordController.text.isNotEmpty) {
        _validatePasswordRealTime(_passwordController.text);
        // Also validate confirm password when password changes
        if (_confirmPasswordController.text.isNotEmpty) {
          _validateConfirmPasswordRealTime(_confirmPasswordController.text);
        }
      } else {
        // Clear confirm password validation when password is empty
        setState(() {
          _confirmPasswordValid = false;
          _confirmPasswordError = null;
        });
      }
    });

    _confirmPasswordController.addListener(() {
      if (_confirmPasswordController.text.isNotEmpty) {
        _validateConfirmPasswordRealTime(_confirmPasswordController.text);
      } else {
        // Clear validation when confirm password is empty
        setState(() {
          _confirmPasswordValid = false;
          _confirmPasswordError = null;
        });
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    _logoController.forward();
    _pulseController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 200), () {
      _formController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _animationController.forward();
    });
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

  // Password validation function
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
    ).hasMatch(value)) {
      return 'Password must be 8+ characters with upper, lower, digit, and special character';
    }

    return null;
  }

  // Confirm password validation function
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear all previously saved user data before registration
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await UserDataClearer.clearAllUserData();

    // Validate verification method
    if (_selectedMethod == ResetMethod.email &&
        _emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
        _showError = true;
      });
      return;
    }

    if (_selectedMethod == ResetMethod.phone &&
        _phoneController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your phone number';
        _showError = true;
      });
      return;
    }

    // Validate password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _showError = true;
        _confirmPasswordError = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showError = false;
    });

    try {
      // Reuse the authProvider from above instead of creating a new one
      // final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Prepare phone number with country code if using phone verification
      String? phoneNumber;
      if (_selectedMethod == ResetMethod.phone) {
        final digitsOnly = _phoneController.text.replaceAll(
          RegExp(r'[^\d]'),
          '',
        );
        phoneNumber = _selectedCountryCode + digitsOnly;
      }

      final success = await authProvider.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _selectedMethod == ResetMethod.phone
            ? ''
            : _emailController.text.trim(),
        phone: phoneNumber,
        password: _passwordController.text,
      );

      if (success && mounted) {
        final verificationMethod = _selectedMethod == ResetMethod.phone
            ? 'phone'
            : 'email';

        _showErrorSnackBar(
          'Registration successful! Please verify your $verificationMethod.',
          isError: false,
        );

        // Navigate to OTP verification
        context.go(
          '/verify-otp',
          extra: {
            'email': _selectedMethod == ResetMethod.phone
                ? ''
                : _emailController.text.trim(),
            'phone': _selectedMethod == ResetMethod.phone ? phoneNumber : '',
            'isRegistration': true,
            'verificationMethod': verificationMethod,
          },
        );
      } else {
        // Handle case where registration returns false but no exception
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final errorMessage =
            authProvider.error ?? 'Registration failed. Please try again.';

        // Check if this is a "user already exists" error
        if (errorMessage.toLowerCase().contains('already exists') ||
            errorMessage.toLowerCase().contains('user exists') ||
            errorMessage.toLowerCase().contains('409')) {
          _errorMessage =
              'An account with this email/phone already exists. Please use "Resend Code" on the verification screen instead of registering again.';
        } else {
          _errorMessage = errorMessage;
        }
        _showError = true;
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = _getUserFriendlyErrorMessage(e);
        _showError = true;
        _showErrorSnackBar(_errorMessage!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _pulseController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    

    
    super.dispose();
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
            title: 'Create Account',
            subtitle: '',
            showThemeToggle: true,
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0),

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
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
                        child: Column(
                          children: [
                            // Logo Animation
                            if (!_isKeyboardVisible) ...[
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: SizedBox(
                                    height: 120,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 90,
                                          height: 90,
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
                                                Icons.volunteer_activism,
                                                size: 48,
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
                                          child: _buildDot(Colors.orange, 10),
                                        ),
                                        Positioned(
                                          top: 20,
                                          right: 60,
                                          child: _buildDot(Colors.redAccent, 8),
                                        ),
                                        Positioned(
                                          bottom: 30,
                                          left: 40,
                                          child: _buildDot(
                                            Colors.tealAccent,
                                            6,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 30,
                                          right: 40,
                                          child: _buildDot(
                                            Colors.blueAccent,
                                            10,
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          left: 100,
                                          child: _buildDot(
                                            Colors.deepPurple,
                                            6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: 10.sp),

                            // Registration Form
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Form Completion Indicator
                                      //_buildFormCompletionIndicator(),

                                      // Success Message
                                      // _buildSuccessMessage(),

                                      // Enhanced Error Display
                                      if (_showError && _errorMessage != null)
                                        Container(
                                              margin: EdgeInsets.only(
                                                bottom: 20.sp,
                                              ),
                                              padding: EdgeInsets.all(16.sp),
                                              decoration: BoxDecoration(
                                                color: AppColors.error
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.error
                                                      .withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color: AppColors.error,
                                                        size: 20,
                                                      ),
                                                      SizedBox(width: 12.sp),
                                                      Expanded(
                                                        child: Text(
                                                          'Registration Error',
                                                          style:
                                                              AppTextStyles.bodyMedium(
                                                                isDark: isDark,
                                                              ).copyWith(
                                                                color: AppColors
                                                                    .error,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: _clearError,
                                                        icon: Icon(
                                                          Icons.close,
                                                          color:
                                                              AppColors.error,
                                                          size: 20,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8.sp),
                                                  Text(
                                                    _errorMessage!,
                                                    style:
                                                        AppTextStyles.bodyMedium(
                                                          isDark: isDark,
                                                        ).copyWith(
                                                          color:
                                                              AppColors.error,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(duration: 200.ms)
                                            .slideY(begin: -0.2, end: 0),
                                      // Verification Method Toggle
                                      _buildMethodTabs()
                                          .animate()
                                          .fadeIn(duration: 250.ms)
                                          .slideY(begin: 0.2, end: 0),

                                      // Name Fields
                                      SizedBox(height: 20.sp),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: ModernInputField(
                                              controller: _firstNameController,
                                              label: 'First Name',
                                              hint: 'Enter your first name',
                                              prefixIcon: Icons.person_outline,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isRequired: true,
                                              autovalidateMode: true,
                                              showSuccessIcon: true,
                                              isDark: isDark,
                                              onChanged: _validateFirstName,

                                              errorText: _firstNameError,
                                            ),
                                          ),
                                          SizedBox(width: 8.sp),
                                          Expanded(
                                            child: ModernInputField(
                                              controller: _lastNameController,
                                              label: 'Last Name',
                                              hint: 'Enter your last name',
                                              prefixIcon: Icons.person_outline,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isRequired: true,
                                              autovalidateMode: true,
                                              showSuccessIcon: true,
                                              isDark: isDark,
                                              onChanged: _validateLastName,

                                              errorText: _lastNameError,
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 10.sp),

                                      // Email Field (conditional)
                                      if (_selectedMethod == ResetMethod.email)
                                        ModernInputField(
                                          controller: _emailController,
                                          label: 'Email',
                                          hint: 'Enter your email address',
                                          prefixIcon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          isRequired: true,
                                          autovalidateMode: true,
                                          showSuccessIcon: true,
                                          helperText:
                                              'We\'ll send a verification code to your email',
                                          isDark: isDark,
                                          onChanged: _validateEmail,

                                          errorText: _emailError,
                                        ),

                                      // Phone Field (conditional)
                                      if (_selectedMethod ==
                                          ResetMethod.phone) ...[
                                        PhoneInputField(
                                          controller: _phoneController,
                                          label: "Phone Number",
                                          hint: 'Enter your phone number',
                                          enabled: true,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (value) {
                                            _onPhoneNumberChanged(value);
                                          },
                                          validator: null,
                                          isDark: isDark,
                                        ),
                                        // Error text for phone field
                                        if (_phoneError != null)
                                          Container(
                                            margin: EdgeInsets.only(top: 6.sp),
                                            child: Text(
                                              _phoneError!,
                                              style: AppTextStyles.caption(
                                                color: AppColors.error,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        // Helper text for phone verification
                                        Container(
                                          margin: EdgeInsets.only(top: 6.sp),
                                          child: Text(
                                            'We\'ll send a verification code via SMS',
                                            style: AppTextStyles.caption(
                                              color:
                                                  AppColors.getOnSurfaceColor(
                                                    isDark,
                                                  ).withValues(alpha: 0.6),
                                              isDark: isDark,
                                            ),
                                          ),
                                        ),
                                      ],

                                      SizedBox(height: 10.sp),

                                      // Password Field
                                      ModernInputField(
                                        controller: _passwordController,
                                        label: 'Password',
                                        hint: 'Create a strong password',
                                        prefixIcon: Icons.lock_outlined,
                                        suffixIcon: _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.next,
                                        onSuffixIconPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        validator: _validatePassword,
                                        isRequired: true,
                                        autovalidateMode: true,
                                        showSuccessIcon: true,
                                        helperText:
                                            'Please set strong password',
                                        isDark: isDark,
                                        onChanged: _validatePasswordRealTime,

                                        errorText: _passwordError,
                                      ),

                                      SizedBox(height: 5.sp),

                                      // Password Strength Indicator
                                      _buildPasswordStrengthIndicator(),
                                      SizedBox(height: 15.sp),

                                      // Confirm Password Field
                                      ModernInputField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirm Password',
                                        hint: 'Confirm your password',
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
                                        validator: _validateConfirmPassword,
                                        isRequired: true,
                                        autovalidateMode: true,
                                        showSuccessIcon: _confirmPasswordValid,
                                        isDark: isDark,
                                        onChanged: (value) {
                                          _validateConfirmPasswordRealTime(
                                            value,
                                          );
                                        },

                                        errorText: _confirmPasswordError,
                                      ),

                                      SizedBox(height: 10.sp),

                                      // Terms and Conditions
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _agreeToTerms,
                                            onChanged: (value) {
                                              _clearError(); // Clear any previous errors
                                              setState(() {
                                                _agreeToTerms = value ?? false;
                                                _checkFormValidity();
                                              });
                                            },
                                            activeColor: AppColors.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              'I agree to the Terms of Service and Privacy Policy',
                                              style: AppTextStyles.bodyMedium(
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 10.sp),
                                      // Register Button
                                      ModernButton(
                                            text: _isFormValid
                                                ? 'Create Account'
                                                : 'Complete Form to Continue',
                                            onPressed: _handleRegister,
                                            isLoading: _isLoading,
                                            disabled: !_isFormValid,
                                            width: double.infinity,
                                            size: ButtonSize.medium,
                                          )
                                          .animate()
                                          .fadeIn(duration: 250.ms)
                                          .slideY(begin: 0.2, end: 0),

                                      // Sign In Link
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Already have an account? ',
                                            style: AppTextStyles.bodyMedium(
                                              isDark: isDark,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.push('/login'),
                                            child: Text(
                                              'Sign In',
                                              style: AppTextStyles.link(
                                                isDark: isDark,
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
