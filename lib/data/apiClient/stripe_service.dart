import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/api_service.dart';

class StripeService {
  final ApiService _api = ApiService();

  /// Get Stripe configuration
  Future<ApiResponse<Map<String, dynamic>>> getStripeConfig() async {
    try {
      final response = await _api.get('/mobile/stripe/config');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get Stripe config: $e',
      );
    }
  }

  /// Create Stripe customer
  Future<ApiResponse<Map<String, dynamic>>> createCustomer({
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/customers',
        data: {'email': email, 'name': name, if (phone != null) 'phone': phone},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create customer: $e',
      );
    }
  }

  /// Get current customer
  Future<ApiResponse<Map<String, dynamic>>> getCurrentCustomer() async {
    try {
      final response = await _api.get('/mobile/stripe/customers/me');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to get customer: $e');
    }
  }

  /// Get customer (alias for getCurrentCustomer)
  Future<ApiResponse<Map<String, dynamic>>> getCustomer() async {
    return getCurrentCustomer();
  }

  /// Update customer
  Future<ApiResponse<Map<String, dynamic>>> updateCustomer({
    required String email,
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      final response = await _api.put(
        '/mobile/stripe/customers/me',
        data: {
          'email': email,
          'name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to update customer: $e',
      );
    }
  }

  /// Create payment intent
  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required String currency,
    required String paymentMethodId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/payment-intents',
        data: {
          'amount': amount,
          'currency': currency,
          'payment_method_id': paymentMethodId,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create payment intent: $e',
      );
    }
  }

  /// Confirm payment intent
  Future<ApiResponse<Map<String, dynamic>>> confirmPaymentIntent({
    required String paymentIntentId,
    String? paymentMethodId,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/payment-intents/confirm',
        data: {
          'payment_intent_id': paymentIntentId,
          if (paymentMethodId != null) 'payment_method': paymentMethodId,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to confirm payment intent: $e',
      );
    }
  }

  /// Get payment intent
  Future<ApiResponse<Map<String, dynamic>>> getPaymentIntent(
    String paymentIntentId,
  ) async {
    try {
      final response = await _api.get(
        '/mobile/stripe/payment-intents/$paymentIntentId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get payment intent: $e',
      );
    }
  }

  /// Get payment intent status
  Future<ApiResponse<Map<String, dynamic>>> getPaymentIntentStatus(
    String paymentIntentId,
  ) async {
    return getPaymentIntent(paymentIntentId);
  }

  /// Cancel payment intent
  Future<ApiResponse<Map<String, dynamic>>> cancelPaymentIntent(
    String paymentIntentId,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/payment-intents/$paymentIntentId/cancel',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to cancel payment intent: $e',
      );
    }
  }

  /// Create setup intent
  Future<ApiResponse<Map<String, dynamic>>> createSetupIntent({
    String? customerId,
    List<String>? paymentMethodTypes,
    String? usage,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/setup-intents',
        data: {
          if (customerId != null) 'customer_id': customerId,
          if (paymentMethodTypes != null)
            'payment_method_types': paymentMethodTypes,
          if (usage != null) 'usage': usage,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create setup intent: $e',
      );
    }
  }

  /// Get setup intent
  Future<ApiResponse<Map<String, dynamic>>> getSetupIntent(
    String setupIntentId,
  ) async {
    try {
      final response = await _api.get(
        '/mobile/stripe/setup-intents/$setupIntentId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get setup intent: $e',
      );
    }
  }

  /// Save payment method
  Future<ApiResponse<Map<String, dynamic>>> savePaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/bank/payment-methods',
        data: {'payment_method_id': paymentMethodId},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to save payment method: $e',
      );
    }
  }

  /// Attach payment method to customer
  Future<ApiResponse<Map<String, dynamic>>> attachPaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/payment-methods/$paymentMethodId/attach',
        data: {'payment_method_id': paymentMethodId},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to attach payment method: $e',
      );
    }
  }

  /// Detach payment method from customer
  Future<ApiResponse<Map<String, dynamic>>> detachPaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/payment-methods/$paymentMethodId/detach',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to detach payment method: $e',
      );
    }
  }

  /// Delete payment method
  Future<ApiResponse<Map<String, dynamic>>> deletePaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _api.delete(
        '/mobile/bank/payment-methods/$paymentMethodId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to delete payment method: $e',
      );
    }
  }

  /// Get payment methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentMethods({
    String? customerId,
    String? type,
  }) async {
    try {
      final response = await _api.get(
        '/mobile/bank/payment-methods',
        queryParameters: {
          if (customerId != null) 'customer': customerId,
          if (type != null) 'type': type,
        },
      );
      return ApiResponse.fromJson(response.data, (data) {
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get payment methods: $e',
      );
    }
  }

  /// Update payment method
  Future<ApiResponse<Map<String, dynamic>>> updatePaymentMethod({
    required String paymentMethodId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _api.put(
        '/mobile/bank/payment-methods/$paymentMethodId',
        data: data,
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to update payment method: $e',
      );
    }
  }

  /// Create charge
  Future<ApiResponse<Map<String, dynamic>>> createCharge({
    required double amount,
    required String currency,
    required String paymentMethodId,
    String? customerId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/charges',
        data: {
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'payment_method': paymentMethodId,
          if (customerId != null) 'customer': customerId,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
          'confirm': true,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create charge: $e',
      );
    }
  }

  /// Get charges
  Future<ApiResponse<List<Map<String, dynamic>>>> getCharges({
    String? customerId,
    int? limit,
    String? startingAfter,
  }) async {
    try {
      final response = await _api.get(
        '/mobile/stripe/charges',
        queryParameters: {
          if (customerId != null) 'customer': customerId,
          if (limit != null) 'limit': limit,
          if (startingAfter != null) 'starting_after': startingAfter,
        },
      );
      return ApiResponse.fromJson(response.data, (data) {
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      });
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to get charges: $e');
    }
  }

  /// Create connect account
  Future<ApiResponse<Map<String, dynamic>>> createConnectAccount({
    required String type,
    required String country,
    required String email,
    Map<String, dynamic>? businessProfile,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/connect/accounts',
        data: {
          'type': type,
          'country': country,
          'email': email,
          if (businessProfile != null) 'business_profile': businessProfile,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create connect account: $e',
      );
    }
  }

  /// Create account link
  Future<ApiResponse<Map<String, dynamic>>> createAccountLink({
    required String accountId,
    required String refreshUrl,
    required String returnUrl,
    String? type,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/connect/accounts/$accountId/links',
        data: {
          'refresh_url': refreshUrl,
          'return_url': returnUrl,
          if (type != null) 'type': type,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create account link: $e',
      );
    }
  }

  /// Get connect account
  Future<ApiResponse<Map<String, dynamic>>> getConnectAccount(
    String accountId,
  ) async {
    try {
      final response = await _api.get(
        '/mobile/stripe/connect/accounts/$accountId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get connect account: $e',
      );
    }
  }

  /// Create refund
  Future<ApiResponse<Map<String, dynamic>>> createRefund({
    required String chargeId,
    double? amount,
    String? reason,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/refunds',
        data: {
          'charge': chargeId,
          if (amount != null) 'amount': (amount * 100).round(),
          if (reason != null) 'reason': reason,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create refund: $e',
      );
    }
  }

  /// Get balance
  Future<ApiResponse<Map<String, dynamic>>> getBalance() async {
    try {
      final response = await _api.get('/mobile/stripe/balance');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to get balance: $e');
    }
  }

  /// Create transfer
  Future<ApiResponse<Map<String, dynamic>>> createTransfer({
    required double amount,
    required String currency,
    required String destination,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/transfers',
        data: {
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'destination': destination,
          if (description != null) 'description': description,
          if (metadata != null) 'metadata': metadata,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create transfer: $e',
      );
    }
  }

  /// Payment
  Future<ApiResponse<Map<String, dynamic>>> testPayment({
    required double amount,
    required String currency,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/stripe/test-payment',
        queryParameters: {
          'amount': (amount * 100).round(),
          'currency': currency,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(success: false, message: 'Failed to test payment: $e');
    }
  }
}
