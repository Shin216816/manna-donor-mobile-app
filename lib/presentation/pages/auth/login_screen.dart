import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/oauth_config.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/auth_header.dart';

import 'package:manna_donate_app/presentation/widgets/phone_input_field.dart';
import 'package:manna_donate_app/presentation/widgets/modern_input_field.dart';
import 'package:manna_donate_app/core/user_data_clearer.dart';
import 'package:manna_donate_app/presentation/widgets/error_boundary.dart';
import 'package:manna_donate_app/core/navigation_helper.dart';

enum ResetMethod { email, phone }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // State variables
  bool _isLoading = false;

  bool _isFormValid = false;
  bool _emailValid = false;
  bool _phoneValid = false;
  bool _passwordValid = false;

  // Validation error messages
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  bool _showError = false;
  bool _showWarning = false;
  String? _errorMessage;
  String? _warningMessage;

  // Phone/Email toggle
  ResetMethod _selectedMethod = ResetMethod.email; // Default to email login

  // Store the full phone number with country code
  String _fullPhoneNumber = '';

  // Get the current phone number with country code
  String get _currentPhoneWithCountryCode {
    // If we have a full phone number with country code, use it
    if (_fullPhoneNumber.isNotEmpty) {
      return _fullPhoneNumber;
    }
    // Otherwise, construct it from the phone controller text
    if (_phoneController.text.isNotEmpty) {
      return '+1${_phoneController.text}'; // Default to US country code
    }
    return '';
  }

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isBiometricAvailable = false;
  bool _isKeyboardVisible = false;
  bool _showAdvancedOptions = false;

  late AnimationController _animationController;
  late AnimationController _logoController;
  late AnimationController _formController;
  late AnimationController _pulseController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: OAuthConfig.getGoogleClientId(),
    scopes: OAuthConfig.googleScopes,
    signInOption: SignInOption.standard, // Allow account selection
  );

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

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // OAuth user trying to login with email/password - This is guidance, not an error
    if (errorString.contains('google/apple sign-in') ||
        errorString.contains('oauth') ||
        errorString.contains('same method to log in') ||
        errorString.contains('created with google') ||
        errorString.contains('created with apple') ||
        errorString.contains('this account was created with')) {
      return 'You registered with Google/Apple sign-in. Please set a password in your profile page to use email login, or use the "Sign in with Google" or "Sign in with Apple" button below.';
    }

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Server errors
    if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    }

    // Timeout errors
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    // Email errors
    if (errorString.contains('email') ||
        errorString.contains('user not found')) {
      return 'No account found with this email. Please check your email or create a new account.';
    }

    // Password errors
    if (errorString.contains('password')) {
      return 'Password is incorrect. Please try again.';
    }

    // Authentication errors (check this LAST)
    if (errorString.contains('invalid') ||
        errorString.contains('credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    // Default error message
    return 'An error occurred. Please try again.';
  }

  // Field validation methods
  void _handleMethodChange(ResetMethod method) {
    HapticFeedback.selectionClick();
    _clearAllValidationErrors();
    setState(() {
      _selectedMethod = method;
      // Clear the other field when switching
      if (method == ResetMethod.phone) {
        _emailController.clear();
        _emailValid = false;
        _emailError = null;
      } else {
        _phoneController.clear();
        _phoneValid = false;
        _phoneError = null;
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
      margin: EdgeInsets.only(bottom: 20.sp),
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

  void _validateEmail(String value) {
    _clearAllValidationErrors();

    String? emailError;
    bool isValid = true;

    if (value.trim().isEmpty) {
      emailError = 'Email is required';
      isValid = false;
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(value.trim())) {
      emailError = 'Please enter a valid email address';
      isValid = false;
    }

    setState(() {
      _emailValid = isValid;
      _emailError = emailError;
      _checkFormValidity();
    });

    // Auto-save email if remember me is checked
    if (_rememberMe && value.trim().isNotEmpty) {
      _onEmailChanged(value);
    }
  }

  void _validatePhone(String value) {
    _clearAllValidationErrors();

    String? phoneError;
    bool isValid = true;

    // Store the full phone number with country code
    _fullPhoneNumber = value;

    if (value.trim().isEmpty) {
      phoneError = 'Phone number is required';
      isValid = false;
    } else {
      // Basic phone validation - at least 10 digits
      final phoneNumber = value.replaceAll(RegExp(r'[^\d]'), '');
      if (phoneNumber.length < 10) {
        phoneError = 'Phone number must be at least 10 digits';
        isValid = false;
      } else if (phoneNumber.length > 15) {
        phoneError = 'Phone number is too long';
        isValid = false;
      }
    }

    setState(() {
      _phoneValid = isValid;
      _phoneError = phoneError;
      _checkFormValidity();
    });
  }

  void _validatePassword(String value) {
    _clearAllValidationErrors();

    String? passwordError;
    bool isValid = true;

    if (value.isEmpty) {
      passwordError = 'Password is required';
      isValid = false;
    } else if (value.length < 8) {
      passwordError = 'Password must be at least 8 characters long';
      isValid = false;
    } else if (!RegExp(r'[A-Z]').hasMatch(value)) {
      passwordError = 'Password must contain at least one uppercase letter';
      isValid = false;
    } else if (!RegExp(r'[a-z]').hasMatch(value)) {
      passwordError = 'Password must contain at least one lowercase letter';
      isValid = false;
    } else if (!RegExp(r'[0-9]').hasMatch(value)) {
      passwordError = 'Password must contain at least one number';
      isValid = false;
    } else if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]).{8,}$',
    ).hasMatch(value)) {
      passwordError =
          'Password must be 8+ characters with upper, lower, digit, and special character';
      isValid = false;
    }

    setState(() {
      _passwordValid = isValid;
      _passwordError = passwordError;
      _checkFormValidity();
    });
  }

  bool _isPasswordStrong(String password) {
    if (password.isEmpty) return false;
    if (password.length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    if (!RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]').hasMatch(password))
      return false;
    return true;
  }

  void _checkFormValidity() {
    setState(() {
      if (_selectedMethod == ResetMethod.phone) {
        _isFormValid = _phoneValid && _passwordValid;
      } else {
        _isFormValid = _emailValid && _passwordValid;
      }
    });
  }

  // Calculate form completion percentage
  double _getFormCompletionPercentage() {
    int totalFields = 2; // email/phone, password
    int completedFields = 0;

    if (_selectedMethod == ResetMethod.phone ? _phoneValid : _emailValid)
      completedFields++;
    if (_passwordValid) completedFields++;

    return completedFields / totalFields;
  }

  // Password strength calculation
  String _getPasswordStrength(String password) {
    if (password.isEmpty) return '';

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*()_\-+=\[\]{};:"\\|,.<>\/?]').hasMatch(password))
      score++;

    if (score < 3) return 'weak';
    if (score < 5) return 'fair';
    if (score < 6) return 'good';
    return 'strong';
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'weak':
        return AppColors.error;
      case 'fair':
        return AppColors.warning;
      case 'good':
        return AppColors.info;
      case 'strong':
        return AppColors.success;
      default:
        return AppColors.getOnSurfaceColor(
          Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
        ).withValues(alpha: 0.3);
    }
  }

  int _getPasswordStrengthLevel(String strength) {
    switch (strength) {
      case 'weak':
        return 1;
      case 'fair':
        return 2;
      case 'good':
        return 3;
      case 'strong':
        return 4;
      default:
        return 0;
    }
  }

  void _clearError() {
    setState(() {
      _showError = false;
      _showWarning = false;
      _errorMessage = null;
      _warningMessage = null;
      // Don't clear field-specific errors here - they should persist until fixed
    });
  }

  /// Clear all validation errors including field-specific ones
  void _clearAllValidationErrors() {
    setState(() {
      _showError = false;
      _showWarning = false;
      _errorMessage = null;
      _warningMessage = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
    });
  }

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
    _initializeAnimations();
    _checkBiometricAvailability();
    _setupKeyboardListener();
    _loadCredentials(); // This will load the correct rememberMe state from storage

    // Add listeners for auto-save
    _emailController.addListener(() {
      if (_rememberMe &&
          _selectedMethod == ResetMethod.email &&
          _emailController.text.trim().isNotEmpty) {
        _saveCredentialsIfRememberMe();
      }
    });

    _phoneController.addListener(() {
      if (_rememberMe &&
          _selectedMethod == ResetMethod.phone &&
          _phoneController.text.trim().isNotEmpty) {
        _saveCredentialsIfRememberMe();
      }
    });

    // Ensure credentials are loaded after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCredentialsLoaded();
    });
  }

  // Ensure credentials are properly loaded after credentials are loaded
  void _ensureCredentialsLoaded() {
    if (_rememberMe) {
      if (_selectedMethod == ResetMethod.phone &&
          _phoneController.text.isEmpty) {
        // Try to load credentials from storage again
        _loadCredentials();
      } else if (_selectedMethod == ResetMethod.email &&
          _emailController.text.isEmpty) {
        // Try to load credentials from storage again
        _loadCredentials();
      } else if (_selectedMethod == ResetMethod.phone &&
          _phoneController.text.isNotEmpty) {
        // If phone is already loaded, validate it using the full phone number
        if (_fullPhoneNumber.isNotEmpty) {
          _validatePhone(_fullPhoneNumber);
        } else {
          // Fallback to the phone controller text if full phone number is not available
          _validatePhone(_phoneController.text);
        }
      } else if (_selectedMethod == ResetMethod.email &&
          _emailController.text.isNotEmpty) {
        // If email is already loaded, validate it
        _validateEmail(_emailController.text);
      }
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    // Stagger animations to reduce performance impact
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      _pulseController.repeat(reverse: true);
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      _formController.forward();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      _animationController.forward();
    });
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      // Check if running on simulator/emulator
      final isSimulator = await _isRunningOnSimulator();

      if (isSimulator) {
        // Disable biometric on simulator to prevent issues
        if (mounted) {
          setState(() {
            _isBiometricAvailable = false;
          });
        }
        return;
      }

      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable && isDeviceSupported;
        });
      }
    } catch (e) {
      // Biometric check failed silently
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
        });
      }
    }
  }

  Future<bool> _isRunningOnSimulator() async {
    try {
      // This is a simple check - you might want to use device_info_plus for more accuracy
      final result = await _localAuth.getAvailableBiometrics();
      // If no biometrics available, likely simulator
      return result.isEmpty;
    } catch (e) {
      // If error occurs, likely simulator
      return true;
    }
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

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final phone = prefs.getString('phone');
    final password = prefs.getString('password');
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    final usePhoneLogin = prefs.getBool('usePhoneLogin') ?? false;

    // Always load the rememberMe state
    _rememberMe = rememberMe;
    _selectedMethod = usePhoneLogin ? ResetMethod.phone : ResetMethod.email;

    // If remember me is checked, auto-fill the appropriate field
    if (_rememberMe) {
      if (_selectedMethod == ResetMethod.phone &&
          phone != null &&
          phone.isNotEmpty) {
        // For phone login, we need to extract the phone number part from the full phone number
        // The full phone number format is like "+1234567890"
        if (phone.startsWith('+')) {
          // Extract the phone number part (remove country code)
          final phoneNumber = phone.substring(1); // Remove the + sign
          // Find the country code length (usually 1-3 digits)
          String countryCode = '';
          String phonePart = '';

          // Try to identify the country code
          if (phoneNumber.startsWith('1')) {
            countryCode = '+1';
            phonePart = phoneNumber.substring(1);
          } else if (phoneNumber.startsWith('44')) {
            countryCode = '+44';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('91')) {
            countryCode = '+91';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('86')) {
            countryCode = '+86';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('81')) {
            countryCode = '+81';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('49')) {
            countryCode = '+49';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('33')) {
            countryCode = '+33';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('39')) {
            countryCode = '+39';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('34')) {
            countryCode = '+34';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('61')) {
            countryCode = '+61';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('52')) {
            countryCode = '+52';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('55')) {
            countryCode = '+55';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('7')) {
            countryCode = '+7';
            phonePart = phoneNumber.substring(1);
          } else if (phoneNumber.startsWith('82')) {
            countryCode = '+82';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('65')) {
            countryCode = '+65';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('971')) {
            countryCode = '+971';
            phonePart = phoneNumber.substring(3);
          } else if (phoneNumber.startsWith('966')) {
            countryCode = '+966';
            phonePart = phoneNumber.substring(3);
          } else if (phoneNumber.startsWith('27')) {
            countryCode = '+27';
            phonePart = phoneNumber.substring(2);
          } else if (phoneNumber.startsWith('234')) {
            countryCode = '+234';
            phonePart = phoneNumber.substring(3);
          } else if (phoneNumber.startsWith('254')) {
            countryCode = '+254';
            phonePart = phoneNumber.substring(3);
          } else {
            // Default to US if we can't identify
            countryCode = '+1';
            phonePart = phoneNumber;
          }

          _phoneController.text = phonePart;
          _fullPhoneNumber = phone; // Store the full phone number
          _validatePhone(phone);
        } else {
          // If it's not in the expected format, just use it as is
          _phoneController.text = phone;
          _fullPhoneNumber = phone;
          _validatePhone(phone);
        }
      } else if (_selectedMethod == ResetMethod.email &&
          email != null &&
          email.isNotEmpty) {
        _emailController.text = email;
        _validateEmail(email);
      }

      // Ensure the UI updates
      if (mounted) {
        setState(() {});
      }
    }

    // Load password if it exists
    if (password != null) {
      _passwordController.text = password;
      _validatePassword(password);

      // Show a subtle hint that credentials are loaded
      if (mounted) {
        _showErrorSnackBar('Saved login information loaded', isError: false);
      }
    }
  }

  // Save remember me state immediately when checkbox changes
  Future<void> _saveRememberMeState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', value);
  }

  // Save credentials when remember me is checked
  Future<void> _saveCredentialsIfRememberMe() async {
    if (_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      if (_selectedMethod == ResetMethod.phone &&
          _currentPhoneWithCountryCode.isNotEmpty) {
        await prefs.setString('phone', _currentPhoneWithCountryCode);
      } else if (_selectedMethod == ResetMethod.email &&
          _emailController.text.trim().isNotEmpty) {
        await prefs.setString('email', _emailController.text.trim());
      }
      await prefs.setBool(
        'usePhoneLogin',
        _selectedMethod == ResetMethod.phone,
      );
    }
  }

  // Clear saved data when remember me is unchecked
  Future<void> _clearSavedDataIfNotRememberMe() async {
    if (!_rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('phone');
      await prefs.remove('password');
      await prefs.remove('rememberMe');
      await prefs.remove('usePhoneLogin');
    }
  }

  Future<void> _handleLogin() async {
    // Check form validation before proceeding
    if (!_isFormValid) {
      HapticFeedback.lightImpact();
      _showValidationErrors();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    // Haptic feedback for login attempt
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _warningMessage = null;
      _showError = false;
      _showWarning = false;
    });

    // Login started

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Clear any previous errors
      authProvider.clearError();

      // Ensure phone number has country code
      String phoneToSend = '';
      if (_selectedMethod == ResetMethod.phone) {
        phoneToSend = _currentPhoneWithCountryCode;
      }

      final success = await authProvider.login(
        email: _selectedMethod == ResetMethod.phone
            ? ''
            : _emailController.text.trim(),
        phone: phoneToSend,
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Save credentials if remember me is checked
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          if (_selectedMethod == ResetMethod.phone) {
            await prefs.setString('phone', _currentPhoneWithCountryCode);
          } else {
            await prefs.setString('email', _emailController.text.trim());
          }
          await prefs.setString('password', _passwordController.text);
          await prefs.setBool('rememberMe', _rememberMe);
          await prefs.setBool(
            'usePhoneLogin',
            _selectedMethod == ResetMethod.phone,
          );
        } else {
          await _clearSavedDataIfNotRememberMe();
        }

        // Show success message immediately
        _showErrorSnackBar('Login successful!', isError: false);

        // Add haptic feedback for success
        HapticFeedback.heavyImpact();

        // Add a small delay to show the loading state
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate to home
        if (mounted) {
          await _navigateToHome();
        }
      } else {
        // Use the error message from the auth provider
        _errorMessage =
            authProvider.error ??
            'Invalid email or password. Please try again.';

        // Check if this is an OAuth warning
        if (_isOAuthWarning(_errorMessage!)) {
          _warningMessage = _errorMessage;
          _errorMessage = null;
          _showWarning = true;
          _showError = false;
        } else {
          _showError = true;
          _showWarning = false;
        }
      }
    } catch (e) {
      if (mounted) {
        _errorMessage = _getUserFriendlyErrorMessage(e);

        // Check if this is an OAuth warning
        if (_isOAuthWarning(_errorMessage!)) {
          _warningMessage = _errorMessage;
          _errorMessage = null;
          _showWarning = true;
          _showError = false;
          _showErrorSnackBar(_warningMessage!);
        } else {
          _showError = true;
          _showWarning = false;
          _showErrorSnackBar(_errorMessage!);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Login completed
      }
    }
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('rememberMe');
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      await NavigationHelper.navigateToHome(context);
    }
  }

  void _navigateToHomeWithFallback() {
    if (mounted) {
      context.go('/home');
    }
  }

  // Removed _fetchInitialDataInBackground method - no longer needed
  // Users always go directly to home after login

  Future<void> _handleBiometricLogin() async {
    HapticFeedback.mediumImpact();
    try {
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No biometric authentication available'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        // Here you would typically retrieve stored credentials and login
        // For now, we'll just show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication successful'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.mediumImpact();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _warningMessage = null;
        _showError = false;
        _showWarning = false;
      });

      // Clear all previously saved user data before Google sign-in
      await UserDataClearer.clearAllUserData();

      // Sign out first to ensure account selection
      await _googleSignIn.signOut();

      // Get Google Sign-In account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // Get authentication details
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Verify we have a valid ID token
        if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
          throw Exception('Failed to get valid ID token from Google');
        }

        // Send ID token to backend for verification
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.googleSignIn(
          idToken: googleAuth.idToken!,
        );

        if (success && mounted) {
          // Navigate to home
          await _navigateToHome();
        } else {
          _errorMessage = 'Google sign-in failed. Please try again.';
          _showError = true;
        }
      } else {
        // User cancelled Google sign-in
        _errorMessage = 'Google sign-in was cancelled.';
        _showError = true;
      }
    } catch (e) {
      if (mounted) {
        // Handle specific Google sign-in errors
        if (e.toString().contains('network_error') ||
            e.toString().contains('network')) {
          _errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('sign_in_canceled') ||
            e.toString().contains('canceled')) {
          _errorMessage = 'Google sign-in was cancelled.';
        } else if (e.toString().contains('sign_in_failed') ||
            e.toString().contains('failed')) {
          _errorMessage = 'Google sign-in failed. Please try again.';
        } else if (e.toString().contains('invalid_account')) {
          _errorMessage =
              'Invalid Google account. Please try with a different account.';
        } else {
          _errorMessage = _getUserFriendlyErrorMessage(e);
        }
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

  Future<void> _handleAppleSignIn() async {
    HapticFeedback.mediumImpact();
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showError = false;
      });

      // Check if running on simulator
      final isSimulator = await _isRunningOnSimulator();
      if (isSimulator) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Apple Sign-In is not available on simulator. Please use a real device.';
          _showError = true;
        });
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.appleSignIn(
        identityToken: credential.identityToken ?? '',
        authorizationCode: credential.authorizationCode ?? '',
      );

      if (success && mounted) {
        // Navigate to home
        await _navigateToHome();
      } else {
        _errorMessage = 'Apple sign-in failed. Please try again.';
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

  // Auto-save email when remember me is checked and user types
  Future<void> _onEmailChanged(String value) async {
    if (_rememberMe && value.trim().isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', value.trim());
    }
  }

  // Check if message is OAuth-related (warning, not error)
  bool _isOAuthWarning(String message) {
    final messageString = message.toLowerCase();
    return messageString.contains('google/apple sign-in') ||
        messageString.contains('oauth') ||
        messageString.contains('same method to log in') ||
        messageString.contains('created with google') ||
        messageString.contains('created with apple') ||
        messageString.contains('this account was created with');
  }

  // Show OAuth-specific warning UI
  Widget _buildOAuthWarningWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OAuth Account Detected',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This account was created with Google/Apple sign-in. Please use the OAuth buttons below to log in, or set a password in your profile page to use email login.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoController.dispose();
    _formController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Error boundary wrapper
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // Handle any unexpected errors gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: _buildMainContent(isDark),
    );
  }

  Widget _buildMainContent(bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDark),
      body: Column(
        children: <Widget>[
          // Header Section
          AuthHeader(
            title: 'Welcome Back',
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
                        padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
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
                                          top: 20,
                                          left: 45,
                                          child: _buildDot(Colors.orange, 10),
                                        ),
                                        Positioned(
                                          top: 15,
                                          right: 45,
                                          child: _buildDot(Colors.redAccent, 8),
                                        ),
                                        Positioned(
                                          bottom: 20,
                                          left: 30,
                                          child: _buildDot(
                                            Colors.tealAccent,
                                            6,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 20,
                                          right: 30,
                                          child: _buildDot(
                                            Colors.blueAccent,
                                            7,
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 75,
                                          child: _buildDot(
                                            Colors.deepPurple,
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(width: 30.sp),

                            // Login Form
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Error Display
                                      if (_showError && _errorMessage != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 0.sp),
                                          padding: EdgeInsets.fromLTRB(
                                            16,
                                            0,
                                            16,
                                            0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                              SizedBox(width: 12.sp),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style:
                                                      AppTextStyles.getBody(
                                                        isDark: isDark,
                                                      ).copyWith(
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
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // OAuth Warning Widget
                                      if (_showWarning &&
                                          _warningMessage != null)
                                        _buildOAuthWarningWidget(),
                                      SizedBox(height: 20.sp),

                                      // Enhanced Login Method Toggle
                                      _buildMethodTabs()
                                          .animate()
                                          .fadeIn(duration: 350.ms)
                                          .slideY(begin: 0.2, end: 0),

                                      // Email/Phone Field
                                      if (_selectedMethod ==
                                          ResetMethod.email) ...[
                                        // Enhanced Email Input with ModernInputField
                                        ModernInputField(
                                              controller: _emailController,
                                              label: 'Email',
                                              hint: 'Enter your email address',
                                              prefixIcon: Icons.email_outlined,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              textInputAction:
                                                  TextInputAction.next,
                                              isRequired: true,
                                              autovalidateMode: true,
                                              showSuccessIcon: _emailValid,
                                              isDark: isDark,
                                              onChanged: _validateEmail,
                                              errorText: _emailError,
                                            )
                                            .animate()
                                            .fadeIn(duration: 300.ms)
                                            .slideX(begin: -0.1, end: 0),
                                      ] else if (_selectedMethod ==
                                          ResetMethod.phone) ...[
                                        // Enhanced Phone Input with Perfect Alignment
                                        PhoneInputField(
                                              controller: _phoneController,
                                              label: "Phone Number",
                                              hint: 'Enter your phone number',
                                              enabled: true,
                                              textInputAction:
                                                  TextInputAction.next,
                                              onChanged: (value) {
                                                _validatePhone(value);
                                              },
                                              validator: null,
                                              isDark: isDark,
                                            )
                                            .animate()
                                            .fadeIn(duration: 300.ms)
                                            .slideX(begin: -0.1, end: 0),

                                        // Phone validation error
                                        if (_phoneError != null)
                                          Container(
                                                margin: EdgeInsets.only(
                                                  top: 8.sp,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.error_outline,
                                                      color: AppColors.error,
                                                      size: 16.sp,
                                                    ),
                                                    SizedBox(width: 8.sp),
                                                    Expanded(
                                                      child: Text(
                                                        _phoneError!,
                                                        style:
                                                            AppTextStyles.bodySmall(
                                                              color: AppColors
                                                                  .error,
                                                              isDark: isDark,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                              .animate()
                                              .fadeIn(duration: 200.ms)
                                              .slideY(begin: -0.2, end: 0),
                                      ],

                                      SizedBox(height: 20.sp),

                                      // Enhanced Password Field with ModernInputField
                                      ModernInputField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            hint: 'Enter your password',
                                            prefixIcon: Icons.lock_outlined,
                                            obscureText: _obscurePassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            isRequired: true,
                                            autovalidateMode: true,
                                            showSuccessIcon: _passwordValid,
                                            isDark: isDark,
                                            onChanged: _validatePassword,
                                            errorText: _passwordError,
                                            onSuffixIconPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          )
                                          .animate()
                                          .fadeIn(duration: 300.ms)
                                          .slideX(begin: -0.1, end: 0),
                                      SizedBox(height: 16.sp),

                                      // Remember Me & Forgot Password
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Builder(
                                                builder: (context) {
                                                  return Checkbox(
                                                    value: _rememberMe,
                                                    onChanged: (value) async {
                                                      setState(() {
                                                        _rememberMe =
                                                            value ?? false;
                                                      });

                                                      // Save remember me state immediately
                                                      await _saveRememberMeState(
                                                        value ?? false,
                                                      );

                                                      // If checking remember me, save current credentials
                                                      if (value == true) {
                                                        await _saveCredentialsIfRememberMe();
                                                      } else {
                                                        // If unchecking, clear saved data
                                                        await _clearSavedDataIfNotRememberMe();
                                                      }
                                                    },
                                                    activeColor:
                                                        AppColors.primary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                'Remember me',
                                                style: AppTextStyles.bodyMedium(
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () => context.push(
                                              '/forgot-password',
                                            ),
                                            child: Text(
                                              'Forgot Password?',
                                              style: AppTextStyles.link(
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 10.sp),

                                      // Enhanced Login Button
                                      ModernButton(
                                            text: 'Sign In',
                                            onPressed: _isFormValid
                                                ? _handleLogin
                                                : null,
                                            isLoading: _isLoading,
                                            disabled: !_isFormValid,
                                            icon: Icons.login,
                                            width: double.infinity,
                                            size: ButtonSize.small,
                                            variant: _isFormValid
                                                ? ButtonVariant.primary
                                                : ButtonVariant.secondary,
                                          )
                                          .animate()
                                          .fadeIn(duration: 400.ms)
                                          .slideY(begin: 0.2, end: 0)
                                          .then()
                                          .shimmer(
                                            duration: _isFormValid
                                                ? 2000.ms
                                                : 0.ms,
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),

                                      SizedBox(height: 24.sp),

                                      // Advanced Options Toggle
                                      if (_isBiometricAvailable) ...[
                                        GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            setState(() {
                                              _showAdvancedOptions =
                                                  !_showAdvancedOptions;
                                            });
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.sp,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _showAdvancedOptions
                                                      ? 'Hide Advanced Options'
                                                      : 'Show Advanced Options',
                                                  style:
                                                      AppTextStyles.getBody(
                                                        isDark: isDark,
                                                      ).copyWith(
                                                        fontSize: 12.sp,
                                                        color:
                                                            AppColors.primary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                                SizedBox(width: 4.sp),
                                                Icon(
                                                  _showAdvancedOptions
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons
                                                            .keyboard_arrow_down,
                                                  color: AppColors.primary,
                                                  size: 16.sp,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 16.sp),
                                      ],

                                      // Advanced Options Section
                                      if (_showAdvancedOptions &&
                                          _isBiometricAvailable) ...[
                                        Container(
                                          padding: EdgeInsets.all(16.sp),
                                          decoration: BoxDecoration(
                                            color: AppColors.getSurfaceColor(
                                              isDark,
                                            ).withValues(alpha: 0.5),
                                            borderRadius: BorderRadius.circular(
                                              12.sp,
                                            ),
                                            border: Border.all(
                                              color: AppColors.getOutlineColor(
                                                isDark,
                                              ).withValues(alpha: 0.1),
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                'Advanced Authentication',
                                                style:
                                                    AppTextStyles.getBody(
                                                      isDark: isDark,
                                                    ).copyWith(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.getOnSurfaceColor(
                                                            isDark,
                                                          ),
                                                    ),
                                              ),
                                              SizedBox(height: 12.sp),
                                              Text(
                                                'Use biometric authentication for faster and more secure login.',
                                                style:
                                                    AppTextStyles.getBody(
                                                      isDark: isDark,
                                                    ).copyWith(
                                                      fontSize: 12.sp,
                                                      color:
                                                          AppColors.getOnSurfaceColor(
                                                            isDark,
                                                          ).withValues(
                                                            alpha: 0.7,
                                                          ),
                                                    ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 16.sp),
                                      ],

                                      // Enhanced Biometric Login
                                      if (_isBiometricAvailable) ...[
                                        Container(
                                              width: double.infinity,
                                              height: 40.sp,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      12.sp,
                                                    ),
                                                border: Border.all(
                                                  color:
                                                      AppColors.getOutlineColor(
                                                        isDark,
                                                      ).withValues(alpha: 0.2),
                                                  width: 1,
                                                ),
                                                color:
                                                    AppColors.getSurfaceColor(
                                                      isDark,
                                                    ),
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.sp,
                                                      ),
                                                  onTap: _handleBiometricLogin,
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.sp,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.fingerprint,
                                                          color:
                                                              AppColors.getOnSurfaceColor(
                                                                isDark,
                                                              ),
                                                          size: 18.sp,
                                                        ),
                                                        SizedBox(width: 10.sp),
                                                        Text(
                                                          'Sign in with Biometric',
                                                          style:
                                                              AppTextStyles.getBody(
                                                                isDark: isDark,
                                                              ).copyWith(
                                                                color:
                                                                    AppColors.getOnSurfaceColor(
                                                                      isDark,
                                                                    ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 15.sp,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(duration: 400.ms)
                                            .slideY(begin: 0.2, end: 0),

                                        SizedBox(height: 24.sp),
                                      ],

                                      // Divider
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: AppColors.getDividerColor(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16.sp,
                                            ),
                                            child: Text(
                                              'or continue with',
                                              style: AppTextStyles.bodyMedium(
                                                color:
                                                    AppColors.getOnSurfaceColor(
                                                      isDark,
                                                    ).withValues(alpha: 0.7),
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: AppColors.getDividerColor(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 24.sp),

                                      // Enhanced Social Login Buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Google Sign In Button
                                          Container(
                                            width: 120.sp,
                                            height: 40.sp,
                                            decoration: BoxDecoration(
                                              color: AppColors.getSurfaceColor(
                                                isDark,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.sp),
                                              border: Border.all(
                                                color:
                                                    AppColors.getOutlineColor(
                                                      isDark,
                                                    ).withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      12.sp,
                                                    ),
                                                onTap: _handleGoogleSignIn,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.sp,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/logo/google.png',
                                                        width: 20.sp,
                                                        height: 20.sp,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      SizedBox(width: 8.sp),
                                                      Text(
                                                        'Google',
                                                        style:
                                                            AppTextStyles.getBody(
                                                              isDark: isDark,
                                                            ).copyWith(
                                                              color:
                                                                  AppColors.getOnSurfaceColor(
                                                                    isDark,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14.sp,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16.sp),
                                          // Apple Sign In Button
                                          Container(
                                            width: 120.sp,
                                            height: 40.sp,
                                            decoration: BoxDecoration(
                                              color: AppColors.getSurfaceColor(
                                                isDark,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12.sp),
                                              border: Border.all(
                                                color:
                                                    AppColors.getOutlineColor(
                                                      isDark,
                                                    ).withValues(alpha: 0.2),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      12.sp,
                                                    ),
                                                onTap: _handleAppleSignIn,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16.sp,
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Image.asset(
                                                        'assets/logo/apple.png',
                                                        width: 20.sp,
                                                        height: 20.sp,
                                                        fit: BoxFit.contain,
                                                      ),
                                                      SizedBox(width: 8.sp),
                                                      Text(
                                                        'Apple',
                                                        style:
                                                            AppTextStyles.getBody(
                                                              isDark: isDark,
                                                            ).copyWith(
                                                              color:
                                                                  AppColors.getOnSurfaceColor(
                                                                    isDark,
                                                                  ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14.sp,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),

                                      SizedBox(height: 32.sp),

                                      // Sign Up Link
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: AppTextStyles.bodyMedium(
                                              isDark: isDark,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.push('/register'),
                                            child: Text(
                                              'Sign Up',
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

  /// Show validation errors summary
  void _showValidationErrors() {
    List<String> errors = [];

    if (_selectedMethod == ResetMethod.phone) {
      if (_phoneError != null) errors.add(_phoneError!);
    } else {
      if (_emailError != null) errors.add(_emailError!);
    }

    if (_passwordError != null) errors.add(_passwordError!);

    if (errors.isNotEmpty) {
      setState(() {
        _errorMessage =
            'Please fix the following errors:\n${errors.join('\n')}';
        _showError = true;
        _showWarning = false;
      });

      // Scroll to the first error field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // You could implement scroll to error field here
        }
      });
    }
  }
}
