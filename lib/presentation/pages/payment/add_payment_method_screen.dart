import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/data/apiClient/stripe_service.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/modern_button.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  bool _loading = false;
  bool _isSettingUpPayment = false;
  String? _error;
  String? _errorType; // 'network', 'stripe', 'validation', 'unknown'
  String? _currentStep;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    setState(() {
      _loading = true;
      _error = null;
      _currentStep = 'Initializing payment system...';
    });

    try {
      final stripeService = StripeService();
      final configResponse = await stripeService.getStripeConfig();

      if (!configResponse.success || configResponse.data == null) {
        throw Exception(
          'Failed to get Stripe configuration: ${configResponse.message}',
        );
      }

      final publishableKey = configResponse.data!['publishable_key'];
      if (publishableKey == null || publishableKey.isEmpty) {
        throw Exception(
          'Invalid Stripe configuration: missing publishable key',
        );
      }

      // Initialize Stripe with the publishable key
      stripe.Stripe.publishableKey = publishableKey;
      await stripe.Stripe.instance.applySettings();

      setState(() {
        _loading = false;
        _currentStep = null;
      });
    } catch (e) {
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _errorType = _categorizeError(e);
        _loading = false;
      });
    }
  }

  Future<void> _setupPaymentMethod() async {
    setState(() {
      _isSettingUpPayment = true;
      _currentStep = 'Setting up payment method...';
      _error = null;
    });

    try {
      final stripeService = StripeService();

      // Step 1: Create SetupIntent from backend
      final setupIntentResponse = await stripeService.createSetupIntent(
        paymentMethodTypes: ['card'],
        usage: 'off_session',
      );

      if (!setupIntentResponse.success || setupIntentResponse.data == null) {
        throw Exception(setupIntentResponse.message);
      }

      final setupIntentData = setupIntentResponse.data!;
      final setupIntent = setupIntentData['setup_intent'];

      if (setupIntent == null) {
        throw Exception('No setup intent received from server');
      }

      final clientSecret = setupIntent['client_secret'];

      if (clientSecret == null) {
        throw Exception('No client secret received from setup intent');
      }

      // Step 2: Present PaymentSheet for setup
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Manna Donations',
          style: ThemeMode.system,
        ),
      );

      try {
        await stripe.Stripe.instance.presentPaymentSheet();
      } catch (stripeError) {
        // Handle Stripe-specific errors
        if (stripeError.toString().contains('canceled')) {
          throw Exception('Payment setup was cancelled');
        } else if (stripeError.toString().contains('failed')) {
          throw Exception('Payment setup failed. Please try again.');
        } else {
          throw stripeError;
        }
      }

      // Step 3: Get the payment method from the setup intent
      setState(() {
        _currentStep = 'Finalizing payment method...';
      });

      // Retrieve the setup intent to get the payment method
      final setupIntentId = setupIntent['id'];
      if (setupIntentId == null) {
        throw Exception('Setup intent ID not found');
      }

      // Get the setup intent to retrieve the payment method
      final retrievedSetupIntentResponse = await stripeService.getSetupIntent(setupIntentId);
      if (!retrievedSetupIntentResponse.success || retrievedSetupIntentResponse.data == null) {
        throw Exception('Failed to retrieve setup intent: ${retrievedSetupIntentResponse.message}');
      }

      final retrievedSetupIntent = retrievedSetupIntentResponse.data!['setup_intent'];
      final paymentMethodId = retrievedSetupIntent['payment_method'];
      
      if (paymentMethodId == null) {
        throw Exception('Payment method not found in setup intent');
      }

      // Step 4: Attach the payment method to the customer
      setState(() {
        _currentStep = 'Attaching payment method...';
      });

      final attachResponse = await stripeService.attachPaymentMethod(paymentMethodId);
      if (!attachResponse.success) {
        throw Exception('Failed to attach payment method: ${attachResponse.message}');
      }

      // Step 5: Payment method was successfully added
      setState(() {
        _isSettingUpPayment = false;
        _currentStep = 'Payment method added successfully!';
        _retryCount = 0; // Reset retry count on success
      });

      // Show success and navigate back
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _error = _getUserFriendlyErrorMessage(e);
        _errorType = _categorizeError(e);
        _isSettingUpPayment = false;
        _retryCount++;
      });
    }
  }

  /// Categorize errors for better handling
  String _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return 'network';
    } else if (errorString.contains('stripe') ||
        errorString.contains('payment') ||
        errorString.contains('card') ||
        errorString.contains('setup_intent')) {
      return 'stripe';
    } else if (errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('missing')) {
      return 'validation';
    } else {
      return 'unknown';
    }
  }

  /// Get user-friendly error messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'Network connection failed. Please check your internet connection and try again.';
    }

    // Stripe configuration errors
    if (errorString.contains('stripe configuration') ||
        errorString.contains('publishable key')) {
      return 'Payment system configuration error. Please try again later or contact support.';
    }

    // Setup intent errors
    if (errorString.contains('setup_intent') ||
        errorString.contains('client_secret')) {
      return 'Payment setup failed. Please try again or contact support if the issue persists.';
    }

    // Card validation errors
    if (errorString.contains('card') ||
        errorString.contains('payment method')) {
      return 'Payment method setup failed. Please check your card details and try again.';
    }

    // Generic error
    return 'An unexpected error occurred. Please try again or contact support if the issue persists.';
  }

  /// Retry the failed operation
  Future<void> _retryOperation() async {
    if (_retryCount >= _maxRetries) {
      setState(() {
        _error = 'Maximum retry attempts reached. Please contact support.';
        _errorType = 'unknown';
      });
      _showMaxRetriesDialog();
      return;
    }

    setState(() {
      _error = null;
      _errorType = null;
    });

    if (_loading) {
      await _initializeStripe();
    } else if (_isSettingUpPayment) {
      await _setupPaymentMethod();
    }
  }

  /// Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Simple network check - try to fetch a small resource
      final response = await Future.any([
        Future.delayed(const Duration(seconds: 3)),
        Future.value(true), // Placeholder for actual network check
      ]);
      return response == true;
    } catch (e) {
      return false;
    }
  }

  /// Clear error and reset retry count
  void _clearError() {
    setState(() {
      _error = null;
      _errorType = null;
      _retryCount = 0;
    });
  }

  /// Show success dialog and navigate back
  void _showSuccessDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Payment Method Added!',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            Text(
              'Your payment method has been successfully added and is ready for donations.',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Ensure payment methods are refreshed before navigation
              final bankProvider = Provider.of<BankProvider>(
                context,
                listen: false,
              );
              await bankProvider.refreshPaymentMethods();

              if (mounted) {
                Navigator.of(context).pop(); // Dismiss the dialog
                context.pop(true); // Return success result to previous screen using GoRouter
              }
            },
            child: Text(
              'Continue',
              style: AppTextStyles.getBody(
                isDark: isDark,
                color: AppColors.getOnSurfaceColor(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get error color based on error type
  Color _getErrorColor(bool isDark) {
    switch (_errorType) {
      case 'network':
        return AppColors.warning;
      case 'stripe':
        return AppColors.error;
      case 'validation':
        return AppColors.info;
      case 'unknown':
      default:
        return AppColors.error;
    }
  }

  /// Get error icon based on error type
  IconData _getErrorIcon() {
    switch (_errorType) {
      case 'network':
        return Icons.wifi_off;
      case 'stripe':
        return Icons.payment;
      case 'validation':
        return Icons.info_outline;
      case 'unknown':
      default:
        return Icons.error_outline;
    }
  }

  /// Get error title based on error type
  String _getErrorTitle() {
    switch (_errorType) {
      case 'network':
        return 'Connection Error';
      case 'stripe':
        return 'Payment Error';
      case 'validation':
        return 'Validation Error';
      case 'unknown':
      default:
        return 'Error';
    }
  }

  /// Get action button text based on error type
  String _getActionButtonText() {
    switch (_errorType) {
      case 'network':
        return 'Check Connection';
      case 'stripe':
        return 'Contact Support';
      case 'validation':
        return 'Try Again';
      case 'unknown':
      default:
        return 'Get Help';
    }
  }

  /// Get action button action based on error type
  VoidCallback? _getActionButtonAction() {
    switch (_errorType) {
      case 'network':
        return () {
          // Show network status or refresh
          _retryOperation();
        };
      case 'stripe':
        return () {
          // Navigate to support or help
          _showSupportDialog();
        };
      case 'validation':
        return () {
          // Clear error and let user try again
          _clearError();
        };
      case 'unknown':
      default:
        return () {
          // Show help options
          _showHelpDialog();
        };
    }
  }

  /// Get action button icon based on error type
  IconData _getActionButtonIcon() {
    switch (_errorType) {
      case 'network':
        return Icons.wifi;
      case 'stripe':
        return Icons.support_agent;
      case 'validation':
        return Icons.refresh;
      case 'unknown':
      default:
        return Icons.help_outline;
    }
  }

  /// Show support dialog for Stripe errors
  void _showSupportDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Need Help?',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.support_agent, color: AppColors.primary, size: 48),
            SizedBox(height: 16),
            Text(
              'If you\'re experiencing payment issues, our support team is here to help.',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Close')),
          ElevatedButton(
            onPressed: () {
              context.pop();
              // Navigate to support or contact page
              // context.go('/support');
            },
            child: Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  /// Show max retries reached dialog
  void _showMaxRetriesDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Maximum Retries Reached',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            SizedBox(height: 16),
            Text(
              'We\'ve tried to complete your payment setup multiple times but encountered persistent issues.',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Please contact our support team for assistance.',
              style: AppTextStyles.getBody(isDark: isDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.pop(); // Dismiss dialog
              context.pop(false); // Return to previous screen with failure result
            },
            child: Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _showSupportDialog();
            },
            child: Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  /// Show help dialog for unknown errors
  void _showHelpDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Troubleshooting',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline, color: AppColors.info, size: 48),
            SizedBox(height: 16),
            Text(
              'Try these steps:\n\n1. Check your internet connection\n2. Verify your card details\n3. Ensure your card supports online payments\n4. Try a different card if available',
              style: AppTextStyles.getBody(isDark: isDark),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Close')),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _retryOperation();
            },
            child: Text('Try Again'),
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
      appBar: AppHeader(
        title: 'Add Payment Method',
        showThemeToggle: true,
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    kToolbarHeight -
                    48.sp,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Subtitle
                    Text(
                      'Securely add your credit or debit card',
                      style: AppTextStyles.getBody(isDark: isDark).copyWith(
                        color: AppColors.getOnSurfaceColor(
                          isDark,
                        ).withAlpha(179),
                        fontSize: 16.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.sp),

                    // Error Message
                    if (_error != null)
                      Container(
                            padding: EdgeInsets.all(16.sp),
                            margin: EdgeInsets.only(bottom: 16.sp),
                            decoration: BoxDecoration(
                              color: _getErrorColor(isDark).withAlpha(25),
                              borderRadius: BorderRadius.circular(12.sp),
                              border: Border.all(
                                color: _getErrorColor(isDark).withAlpha(77),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getErrorIcon(),
                                      color: _getErrorColor(isDark),
                                      size: 20.sp,
                                    ),
                                    SizedBox(width: 12.sp),
                                    Expanded(
                                      child: Text(
                                        _getErrorTitle(),
                                        style: AppTextStyles.bodyMedium(
                                          color: _getErrorColor(isDark),
                                          weight: FontWeight.w600,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _clearError,
                                      icon: Icon(
                                        Icons.close,
                                        color: _getErrorColor(isDark),
                                        size: 18.sp,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.sp),
                                Text(
                                  _error!,
                                  style: AppTextStyles.bodySmall(
                                    color: _getErrorColor(
                                      isDark,
                                    ).withAlpha(204),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(height: 12.sp),
                                Row(
                                  children: [
                                    if (_retryCount < _maxRetries &&
                                        _errorType != 'validation')
                                      Expanded(
                                        child: ModernButton(
                                          text: 'Retry',
                                          onPressed: _retryOperation,
                                          icon: Icons.refresh,
                                          width: double.infinity,
                                          height: 32.sp,
                                          isDark: isDark,
                                          variant: ButtonVariant.outlined,
                                        ),
                                      ),
                                    if (_retryCount < _maxRetries &&
                                        _errorType != 'validation')
                                      SizedBox(width: 12.sp),
                                    Expanded(
                                      child: ModernButton(
                                        text: _getActionButtonText(),
                                        onPressed: _getActionButtonAction(),
                                        icon: _getActionButtonIcon(),
                                        width: double.infinity,
                                        height: 32.sp,
                                        isDark: isDark,
                                        variant: ButtonVariant.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideX(begin: -0.2, end: 0),

                    // Main Content
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                                  padding: EdgeInsets.all(24.sp),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              AppColors.darkPrimary,
                                              AppColors.darkPrimaryDark,
                                            ]
                                          : [
                                              AppColors.primary,
                                              AppColors.primaryDark,
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20.sp),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    size: 48.sp,
                                    color: Colors.white,
                                  ),
                                )
                                .animate()
                                .scale(duration: 600.ms)
                                .then()
                                .shake(duration: 200.ms),
                            SizedBox(height: 24.sp),
                            Text(
                              'Add Payment Method',
                              style: AppTextStyles.headlineMedium(
                                color: AppColors.getOnSurfaceColor(isDark),
                                isDark: isDark,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                            SizedBox(height: 12.sp),
                            Text(
                              'Securely add your payment method using Stripe\'s secure payment interface.',
                              style: AppTextStyles.bodyMedium(
                                color: AppColors.getOnSurfaceColor(
                                  isDark,
                                ).withAlpha(179),
                                isDark: isDark,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                            SizedBox(height: 16.sp),
                            Container(
                              padding: EdgeInsets.all(16.sp),
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(25),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: AppColors.success.withAlpha(77),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance,
                                        color: AppColors.success,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.sp),
                                      Expanded(
                                        child: Text(
                                          '💡 Help Churches Save More',
                                          style: AppTextStyles.bodyMedium(
                                            color: AppColors.getOnSurfaceColor(
                                              isDark,
                                            ),
                                            weight: FontWeight.w600,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Text(
                                    'Consider linking your bank account (ACH) instead of a card. ACH transfers have lower processing fees, meaning churches receive more of your donation!',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.getOnSurfaceColor(
                                        isDark,
                                      ).withAlpha(204),
                                      isDark: isDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                            SizedBox(height: 32.sp),
                            if (_loading || _isSettingUpPayment)
                              Column(
                                children: [
                                  LoadingPulse(
                                    message: _currentStep ?? 'Processing...',
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                    size: 50,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 16.sp),
                                  if (_isSettingUpPayment)
                                    Text(
                                      'Please complete the payment setup in the popup window',
                                      style: AppTextStyles.bodySmall(
                                        color: AppColors.getOnSurfaceColor(
                                          isDark,
                                        ).withAlpha(179),
                                        isDark: isDark,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ).animate().fadeIn(duration: 300.ms)
                            else
                              ModernButton(
                                    text: 'Add Payment Method',
                                    onPressed: _setupPaymentMethod,
                                    icon: Icons.credit_card,
                                    width: double.infinity,
                                    height: 40.sp,
                                    isDark: isDark,
                                  )
                                  .animate()
                                  .fadeIn(delay: 600.ms, duration: 600.ms)
                                  .slideY(begin: 0.3, end: 0),
                            SizedBox(height: 24.sp),
                            Container(
                              padding: EdgeInsets.all(16.sp),
                              decoration: BoxDecoration(
                                color: AppColors.getSurfaceColor(isDark),
                                borderRadius: BorderRadius.circular(12.sp),
                                border: Border.all(
                                  color: AppColors.getOnSurfaceColor(
                                    isDark,
                                  ).withAlpha(25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.security,
                                        color: AppColors.success,
                                        size: 20.sp,
                                      ),
                                      SizedBox(width: 12.sp),
                                      Expanded(
                                        child: Text(
                                          'Secure Payment Processing',
                                          style: AppTextStyles.bodyMedium(
                                            color: AppColors.getOnSurfaceColor(
                                              isDark,
                                            ),
                                            weight: FontWeight.w600,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.sp),
                                  Text(
                                    'Your payment information is encrypted and processed securely by Stripe. We never store your card details.',
                                    style: AppTextStyles.bodySmall(
                                      color: AppColors.getOnSurfaceColor(
                                        isDark,
                                      ).withAlpha(179),
                                      isDark: isDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
