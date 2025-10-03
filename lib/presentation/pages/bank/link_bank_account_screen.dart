import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';

import 'package:go_router/go_router.dart';
import 'package:plaid_flutter/plaid_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/stripe_provider.dart';
import 'package:manna_donate_app/data/repository/theme_provider.dart';
import 'package:manna_donate_app/core/theme/app_colors.dart';
import 'package:manna_donate_app/core/theme/app_text_styles.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'package:manna_donate_app/presentation/widgets/app_header.dart';
import 'package:manna_donate_app/presentation/widgets/app_drawer.dart';
import 'dart:async';

class LinkBankAccountScreen extends StatefulWidget {
  const LinkBankAccountScreen({super.key});

  @override
  State<LinkBankAccountScreen> createState() => _LinkBankAccountScreenState();
}

class _LinkBankAccountScreenState extends State<LinkBankAccountScreen> {
  bool _isLinkingBank = false;
  bool _isSettingUpPayment = false;
  bool _isComplete = false;
  String? _currentStep;
  Map<String, dynamic>? _linkedAccount;
  String? _error;
  StreamSubscription<LinkSuccess>? _successSub;
  StreamSubscription<LinkExit>? _exitSub;
  StreamSubscription<LinkEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _initializePlaid();
  }

  @override
  void dispose() {
    _successSub?.cancel();
    _exitSub?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  void _initializePlaid() {
    // Set up PlaidLink listeners
    _successSub = PlaidLink.onSuccess.listen(_onPlaidSuccess);
    _exitSub = PlaidLink.onExit.listen(_onPlaidExit);
    _eventSub = PlaidLink.onEvent.listen(_onPlaidEvent);
  }

  void _onPlaidSuccess(LinkSuccess event) {
    _linkBankAccount(event.publicToken);
  }

  void _onPlaidExit(LinkExit event) {
    if (event.error != null) {
      setState(() {
        _error = 'Bank linking cancelled: ${event.error!.displayMessage}';
        _isLinkingBank = false;
      });
    } else {
      setState(() {
        _isLinkingBank = false;
      });
    }
  }

  void _onPlaidEvent(LinkEvent event) {
    // Handle Plaid events if needed
  }

  Future<void> _startBankLinking() async {
    setState(() {
      _isLinkingBank = true;
      _currentStep = 'Linking your bank account...';
      _error = null;
    });

    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final response = await bankProvider.createLinkToken();

      if (response.success && response.data != null) {
        final linkToken = response.data!['link_token'];
        final configuration = LinkTokenConfiguration(token: linkToken);
        await PlaidLink.create(configuration: configuration);
        PlaidLink.open();
      } else {
        setState(() {
          _error = response.message;
          _isLinkingBank = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start bank linking: $e';
        _isLinkingBank = false;
      });
    }
  }

  Future<void> _linkBankAccount(String publicToken) async {
    setState(() {
      _currentStep = 'Connecting your bank account...';
    });

    try {
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      final response = await bankProvider.linkBankAccount(publicToken);

      if (response.success && response.data != null) {
        final accounts = response.data!['accounts'] as List;
        if (accounts.isNotEmpty) {
          // For now, we'll just store the account data as a map
          // In a real implementation, you'd want to create a proper BankAccount object
          _linkedAccount = null; // BankAccount.fromJson(accounts.first);
          setState(() {
            _currentStep =
                'Bank account linked! Now let\'s set up payment method...';
            _isLinkingBank = false;
          });
          _showPaymentSetup();
        }
      } else {
        setState(() {
          _error = response.message;
          _isLinkingBank = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to link bank account: $e';
        _isLinkingBank = false;
      });
    }
  }

  void _showPaymentSetup() {
    setState(() {
      _isSettingUpPayment = true;
      _currentStep = 'Setting up payment method...';
    });

    _showPaymentMethodSheet();
  }

  void _showPaymentMethodSheet() {
    _setupPaymentMethod();
  }

  Future<void> _setupPaymentMethod() async {
    setState(() {
      _currentStep = 'Setting up payment method...';
    });

    try {
      final stripeProvider = Provider.of<StripeProvider>(
        context,
        listen: false,
      );

      // Step 1: Get Stripe configuration from backend
      final configResponse = await stripeProvider.getStripeConfig();
      if (!configResponse.success || configResponse.data == null) {
        setState(() {
          _error =
              'Failed to get Stripe configuration: ${configResponse.message}';
          _isSettingUpPayment = false;
        });
        return;
      }

      final publishableKey = configResponse.data!['publishable_key'];
      if (publishableKey == null || publishableKey.isEmpty) {
        setState(() {
          _error = 'Invalid Stripe configuration: missing publishable key';
          _isSettingUpPayment = false;
        });
        return;
      }

      // Step 2: Initialize Stripe with the publishable key
      stripe.Stripe.publishableKey = publishableKey;
      await stripe.Stripe.instance.applySettings();

      // Step 3: Create SetupIntent from backend
      final setupIntentResponse = await stripeProvider.createSetupIntent();

      if (!setupIntentResponse.success || setupIntentResponse.data == null) {
        setState(() {
          _error = setupIntentResponse.message;
          _isSettingUpPayment = false;
        });
        return;
      }

      final setupIntentData = setupIntentResponse.data!['setup_intent'];
      if (setupIntentData == null) {
        setState(() {
          _error = 'Failed to get setup intent data';
          _isSettingUpPayment = false;
        });
        return;
      }

      final clientSecret = setupIntentData['client_secret'];
      if (clientSecret == null) {
        setState(() {
          _error = 'Failed to get setup intent client secret';
          _isSettingUpPayment = false;
        });
        return;
      }

      // Step 4: Present PaymentSheet for setup
      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'Manna Donations',
          style: ThemeMode.system,
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      // Step 5: Payment method was successfully added
      setState(() {
        _isSettingUpPayment = false;
        _isComplete = true;
        _currentStep = 'Setup complete!';
      });

      // Refresh payment methods data after successful setup
      if (mounted) {
        final bankProvider = Provider.of<BankProvider>(context, listen: false);
        await bankProvider.refreshPaymentMethods();
      }

      // Show success and navigate back
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _error = 'Failed to setup payment method: $e';
        _isSettingUpPayment = false;
      });
    }
  }

  void _showSuccessDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.card,
        title: Text(
          'Bank Account Linked!',
          style: AppTextStyles.getTitle(isDark: isDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 16),
            Text(
              'Your ${_linkedAccount?['institution'] ?? 'bank'} account has been successfully linked and is ready for roundup donations.',
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
                Navigator.of(context).pop(true); // Return success result to previous screen
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

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'Link Bank Account'),
      drawer: AppDrawer(),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          AppConstants.headerHeight + 24,
          24,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Icon(
              Icons.account_balance,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Link Your Bank Account',
              style: AppTextStyles.headlineMedium().copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connect your bank account to enable automatic roundup donations. We use Plaid for secure bank connections and Stripe for payment processing.',
              style: AppTextStyles.bodyMedium().copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress indicator
            if (_currentStep != null) ...[
              LinearProgressIndicator(
                value: _isComplete ? 1.0 : (_isSettingUpPayment ? 0.7 : 0.3),
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _currentStep!,
                style: AppTextStyles.bodyMedium().copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],

            // Linked account info
            if (_linkedAccount != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _linkedAccount!['institution'] ?? 'Unknown Bank',
                            style: AppTextStyles.bodyLarge().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _linkedAccount!['name'] ?? 'Unknown Account',
                            style: AppTextStyles.bodyMedium().copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Error message
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTextStyles.bodyMedium().copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Spacer(),

            // Action buttons
            if (!_isLinkingBank && !_isSettingUpPayment && !_isComplete) ...[
              ElevatedButton(
                onPressed: _startBankLinking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link),
                    const SizedBox(width: 8),
                    Text(
                      'Link Bank Account',
                      style: AppTextStyles.bodyLarge().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Close Plaid if it's open
                  PlaidLink.close();
                  // Navigate back safely
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // If we can't pop, go to home screen
                    context.go('/home');
                  }
                },
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            if (_isLinkingBank || _isSettingUpPayment) ...[
              Center(
                child: EnhancedLoadingWidget(
                  type: LoadingType.spinner,
                  message: _isLinkingBank
                      ? 'Linking bank account...'
                      : 'Setting up payment...',
                  color: AppColors.primary,
                  size: 40,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
