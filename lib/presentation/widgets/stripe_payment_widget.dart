import 'package:flutter/material.dart';
import 'package:manna_donate_app/presentation/widgets/enhanced_loading_widget.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:manna_donate_app/data/apiClient/stripe_service.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/core/theme/app_constants.dart';
import 'enhanced_card_input.dart';
import 'app_header.dart';

class StripePaymentWidget extends StatefulWidget {
  final double amount;
  final int churchId;
  final String description;
  final Function(bool success, String? error) onPaymentComplete;

  const StripePaymentWidget({
    super.key,
    required this.amount,
    required this.churchId,
    required this.description,
    required this.onPaymentComplete,
  });

  @override
  State<StripePaymentWidget> createState() => _StripePaymentWidgetState();
}

class _StripePaymentWidgetState extends State<StripePaymentWidget> {
  final StripeService _stripeService = StripeService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPaymentMethodId;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _initializeStripe();
    _loadPaymentMethods();
  }

  Future<void> _initializeStripe() async {
    try {
      final configResponse = await _stripeService.getStripeConfig();
      if (configResponse.success) {
        final config = configResponse.data!;
        final publishableKey = config['publishable_key'] as String;

        // Initialize Stripe with the publishable key
        stripe.Stripe.publishableKey = publishableKey;
        await stripe.Stripe.instance.applySettings();
      } else {
        setState(() {
          _errorMessage =
              'Failed to get Stripe configuration: ${configResponse.message}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize Stripe: $e';
      });
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final response = await _stripeService.getPaymentMethods();
      if (response.success) {
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(response.data!);
        });
      }
    } catch (e) {
      // Silently handle error - user might not have payment methods yet
    }
  }

  Future<void> _processPayment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ensure Stripe is initialized
      await _initializeStripe();

      // Create payment intent
      final paymentIntentResponse = await _stripeService.createPaymentIntent(
        amount: widget.amount,
        currency: 'usd',
        paymentMethodId: _selectedPaymentMethodId ?? '',
        description: widget.description,
      );

      if (!paymentIntentResponse.success) {
        throw Exception(paymentIntentResponse.message);
      }

      final paymentIntent = paymentIntentResponse.data!;
      final clientSecret = paymentIntent['client_secret'] as String;

      // Get user email from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userEmail = authProvider.user?.email ?? '';

      // Confirm payment with Stripe
      stripe.PaymentMethodParams paymentMethodParams;

      if (_selectedPaymentMethodId != null) {
        // Use existing payment method - for existing payment methods, we don't need to specify payment method params
        // The payment intent will use the attached payment method
        paymentMethodParams = stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: stripe.BillingDetails(
              email: userEmail,
            ),
          ),
        );
      } else {
        // Create new payment method
        paymentMethodParams = stripe.PaymentMethodParams.card(
          paymentMethodData: stripe.PaymentMethodData(
            billingDetails: stripe.BillingDetails(
              email: userEmail,
            ),
          ),
        );
      }

      final paymentResult = await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethodParams,
      );

      if (paymentResult.status == stripe.PaymentIntentsStatus.Succeeded) {
        widget.onPaymentComplete(true, null);
        _showSuccessDialog();
      } else if (paymentResult.status == stripe.PaymentIntentsStatus.Canceled) {
        widget.onPaymentComplete(false, 'Payment was canceled');
      } else {
        widget.onPaymentComplete(
          false,
          'Payment failed: ${paymentResult.status}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
      widget.onPaymentComplete(false, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewPaymentMethod() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ensure Stripe is initialized
      await _initializeStripe();

      // Show enhanced card input modal
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Payment Method',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Card input
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: EnhancedCardInput(
                        onCardValidated: (cardData) async {
                          context.pop(cardData);
                        },
                        onValidationError: (error) {
                          setState(() {
                            _errorMessage = error;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (result != null) {
        // Create setup intent and add payment method
        final setupIntentResponse = await _stripeService.createSetupIntent(
          paymentMethodTypes: ['card'],
          usage: 'off_session',
        );

        if (setupIntentResponse.success) {
          final setupIntentData = setupIntentResponse.data!;
          final setupIntent = setupIntentData['setup_intent'];

          if (setupIntent == null) {
            throw Exception('No setup intent received from server');
          }

          final clientSecret = setupIntent['client_secret'] as String;

          // Present PaymentSheet for setup
          await stripe.Stripe.instance.initPaymentSheet(
            paymentSheetParameters: stripe.SetupPaymentSheetParameters(
              setupIntentClientSecret: clientSecret,
              merchantDisplayName: 'Manna Donations',
              style: ThemeMode.system,
            ),
          );

          await stripe.Stripe.instance.presentPaymentSheet();

          // Payment method was successfully added
          await _loadPaymentMethods();
          setState(() {
            _errorMessage = null;
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment method added successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            _errorMessage = setupIntentResponse.message;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add payment method: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removePaymentMethod(String paymentMethodId) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _stripeService.detachPaymentMethod(
        paymentMethodId,
      );
      if (response.success) {
        await _loadPaymentMethods(); // Reload payment methods
        if (_selectedPaymentMethodId == paymentMethodId) {
          setState(() {
            _selectedPaymentMethodId = null;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to remove payment method: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount display
          Container(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Column(
              children: [
                Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: AppConstants.bodySize,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: AppConstants.smallSpacing),
                Text(
                  '\$${widget.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppConstants.titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.sectionSpacing),

          // Payment methods section
          Text(
            'Payment Methods',
            style: TextStyle(
              fontSize: AppConstants.subtitleSize,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: AppConstants.itemSpacing),

          // Existing payment methods
          if (_paymentMethods.isNotEmpty) ...[
            ...(_paymentMethods.map(
              (method) => Container(
                margin: const EdgeInsets.only(bottom: AppConstants.itemSpacing),
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPaymentMethodId == method['id']
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: AppConstants.iconSize,
                      color: _selectedPaymentMethodId == method['id']
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: AppConstants.itemSpacing),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '•••• ${method['card']['last4']}',
                            style: TextStyle(
                              fontSize: AppConstants.bodySize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Expires ${method['card']['exp_month']}/${method['card']['exp_year']}',
                            style: TextStyle(
                              fontSize: AppConstants.hintSize,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (_selectedPaymentMethodId != method['id'])
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedPaymentMethodId = method['id'];
                              });
                            },
                            child: const Text('Select'),
                          ),
                        IconButton(
                          onPressed: () => _removePaymentMethod(method['id']),
                          icon: Icon(
                            Icons.delete,
                            size: AppConstants.iconSize,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
          ],

          // Add new payment method button
          Container(
            margin: const EdgeInsets.only(bottom: AppConstants.itemSpacing),
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _addNewPaymentMethod,
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.borderRadius,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppConstants.sectionSpacing),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(AppConstants.cardPadding),
              margin: const EdgeInsets.only(
                bottom: AppConstants.sectionSpacing,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    size: AppConstants.iconSize,
                    color: Colors.red,
                  ),
                  const SizedBox(width: AppConstants.itemSpacing),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: AppConstants.bodySize,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppConstants.sectionSpacing),

          // Pay button
          SizedBox(
            height: AppConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppConstants.buttonRadius,
                  ),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: EnhancedLoadingWidget(
                        type: LoadingType.spinner,
                        size: 20,
                        showMessage: false,
                      ),
                    )
                  : Text(
                      'Pay \$${widget.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: AppConstants.buttonTextSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example usage in a donation page
class DonationPage extends StatelessWidget {
  const DonationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const AppHeader(title: 'Make a Donation'),
      body: StripePaymentWidget(
        amount: 25.00,
        churchId: 1,
        description: 'Donation to Church',
        onPaymentComplete: (success, error) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment successful!')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Payment failed: $error')));
          }
        },
      ),
    );
  }
}
