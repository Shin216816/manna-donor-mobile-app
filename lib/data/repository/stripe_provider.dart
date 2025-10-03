import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/stripe_service.dart';
import 'package:manna_donate_app/data/models/payment_method.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:dio/dio.dart';

class StripeProvider extends ChangeNotifier {
  final StripeService _stripeService = StripeService();

  List<PaymentMethod> _paymentMethods = [];
  Map<String, dynamic>? _customerInfo;
  bool _loading = false;
  String? _error;
  String? _clientSecret;
  String? _paymentIntentId;

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  Map<String, dynamic>? get customerInfo => _customerInfo;
  bool get loading => _loading;
  String? get error => _error;
  String? get clientSecret => _clientSecret;
  String? get paymentIntentId => _paymentIntentId;

  PaymentMethod? get defaultPaymentMethod =>
      _paymentMethods.where((pm) => pm.isDefault).firstOrNull;

  /// Get Stripe configuration for the frontend
  Future<ApiResponse<Map<String, dynamic>>> getStripeConfig() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.getStripeConfig();
      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to get Stripe configuration: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch customer information
  Future<void> fetchCustomerInfo({String? customerId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.getCustomer();
      if (response.success && response.data != null) {
        _customerInfo = response.data!;
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view customer information. Please log in again.';
      } else {
        _error = 'An error occurred: ${e.message}';
      }
    } catch (e) {
      _error = 'An unexpected error occurred.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Create or update customer
  Future<ApiResponse<Map<String, dynamic>>> createOrUpdateCustomer({
    required String email,
    String? name,
    String? phone,
    Map<String, dynamic>? address,
    String? customerId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      ApiResponse<Map<String, dynamic>> response;
      if (customerId != null) {
        // Update existing customer
        response = await _stripeService.updateCustomer(
          email: email,
          name: name ?? '',
          phone: phone,
        );
      } else {
        // Create new customer
        response = await _stripeService.createCustomer(
          email: email,
          name: name ?? '',
          phone: phone,
        );
      }

      if (response.success && response.data != null) {
        _customerInfo = response.data!;
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to create/update customer: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch payment methods for the authenticated user
  Future<void> fetchPaymentMethods({String? type}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.getPaymentMethods(
        type: type ?? 'card',
      );
      if (response.success && response.data != null) {
        _paymentMethods = response.data!
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view payment methods. Please log in again.';
      } else {
        _error = 'An error occurred: ${e.message}';
      }
    } catch (e) {
      _error = 'An unexpected error occurred.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Legacy method for backward compatibility
  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentMethods(
    String customerId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.getPaymentMethods();
      if (response.success && response.data != null) {
        _paymentMethods = response.data!
            .map((json) => PaymentMethod.fromJson(json))
            .toList();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view payment methods. Please log in again.';
      } else {
        _error = 'An error occurred: ${e.message}';
      }
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: _error!,
        data: null,
      );
    } catch (e) {
      _error = 'An unexpected error occurred.';
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        message: _error!,
        data: null,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create payment intent for donation
  Future<ApiResponse<Map<String, dynamic>>> createPaymentIntent({
    required double amount,
    required int churchId,
    required String description,
    String? paymentMethodId,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    _loading = true;
    _error = null;
    _clientSecret = null;
    _paymentIntentId = null;
    notifyListeners();

    try {
      final response = await _stripeService.createPaymentIntent(
        amount: amount,
        currency: 'usd',
        paymentMethodId: paymentMethodId ?? '',
        description: description,
        metadata: metadata,
      );
      if (response.success && response.data != null) {
        _clientSecret = response.data!['client_secret'];
        _paymentIntentId = response.data!['id'];
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to create payment intent: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Confirm payment intent
  Future<ApiResponse<Map<String, dynamic>>> confirmPaymentIntent({
    required String paymentIntentId,
    String? paymentMethodId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.confirmPaymentIntent(
        paymentIntentId: paymentIntentId,
        paymentMethodId: paymentMethodId,
      );
      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to confirm payment intent: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get payment intent status
  Future<ApiResponse<Map<String, dynamic>>> getPaymentIntentStatus(
    String paymentIntentId,
  ) async {
    try {
      final response = await _stripeService.getPaymentIntentStatus(
        paymentIntentId,
      );
      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to get payment intent status: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Cancel payment intent
  Future<ApiResponse<Map<String, dynamic>>> cancelPaymentIntent(
    String paymentIntentId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.cancelPaymentIntent(
        paymentIntentId,
      );
      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to cancel payment intent: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Create setup intent for saving payment methods
  Future<ApiResponse<Map<String, dynamic>>> createSetupIntent({
    String? customerId,
    List<String>? paymentMethodTypes,
    String? usage,
    Map<String, dynamic>? metadata,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.createSetupIntent(
        customerId: customerId,
        paymentMethodTypes: paymentMethodTypes,
        usage: usage,
      );
      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to create setup intent: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Attach payment method to customer
  Future<ApiResponse<Map<String, dynamic>>> attachPaymentMethod({
    required String paymentMethodId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.attachPaymentMethod(
        paymentMethodId,
      );
      if (response.success) {
        // Refresh payment methods
        await fetchPaymentMethods();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to attach payment method: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Detach payment method from customer
  Future<ApiResponse<Map<String, dynamic>>> detachPaymentMethod(
    String paymentMethodId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stripeService.detachPaymentMethod(
        paymentMethodId,
      );
      if (response.success) {
        // Remove from local list
        _paymentMethods.removeWhere((pm) => pm.id == paymentMethodId);
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to detach payment method: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Set default payment method
  Future<ApiResponse<Map<String, dynamic>>> setDefaultPaymentMethod({
    required String paymentMethodId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: This functionality is not directly supported by the current API
      // You would need to implement this on the backend
      final response = ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Set default payment method not supported',
      );

      if (response.success) {
        // Update local payment methods
        _paymentMethods = _paymentMethods
            .map((pm) => pm.copyWith(isDefault: pm.id == paymentMethodId))
            .toList();
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to set default payment method: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Update payment method details
  Future<ApiResponse<Map<String, dynamic>>> updatePaymentMethod({
    required String paymentMethodId,
    Map<String, dynamic>? billingDetails,
    Map<String, dynamic>? card,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: This functionality is not directly supported by the current API
      // You would need to implement this on the backend
      final response = ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Update payment method not supported',
      );

      if (response.success) {
        // Refresh payment methods
        await fetchPaymentMethods();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to update payment method: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get payment method details
  Future<ApiResponse<Map<String, dynamic>>> getPaymentMethodDetails(
    String paymentMethodId,
  ) async {
    try {
      // Note: This functionality is not directly supported by the current API
      // You would need to implement this on the backend
      final response = ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Get payment method details not supported',
      );

      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to get payment method details: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Validate payment method
  Future<ApiResponse<Map<String, dynamic>>> validatePaymentMethod(
    String paymentMethodId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Note: This functionality is not directly supported by the current API
      // You would need to implement this on the backend
      final response = ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Validate payment method not supported',
      );

      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to validate payment method: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get payment method statistics
  Future<ApiResponse<Map<String, dynamic>>> getPaymentMethodStats({
    String? customerId,
    String? paymentMethodId,
  }) async {
    try {
      // Note: This functionality is not directly supported by the current API
      // You would need to implement this on the backend
      final response = ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Get payment method stats not supported',
      );

      if (!response.success) {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to get payment method statistics: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Clear all payment methods
  void clearPaymentMethods() {
    _paymentMethods.clear();
    notifyListeners();
  }

  /// Clear current payment intent data
  void clearPaymentIntent() {
    _clientSecret = null;
    _paymentIntentId = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get payment method by ID
  PaymentMethod? getPaymentMethodById(String id) {
    try {
      return _paymentMethods.firstWhere((pm) => pm.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get valid payment methods (not expired)
  List<PaymentMethod> get validPaymentMethods =>
      _paymentMethods.where((pm) => pm.isValid).toList();

  /// Get expired payment methods
  List<PaymentMethod> get expiredPaymentMethods =>
      _paymentMethods.where((pm) => pm.isExpired).toList();

  /// Get card payment methods
  List<PaymentMethod> get cardPaymentMethods =>
      _paymentMethods.where((pm) => pm.type == 'card').toList();

  /// Get bank account payment methods
  List<PaymentMethod> get bankAccountPaymentMethods =>
      _paymentMethods.where((pm) => pm.type == 'bank_account').toList();

  /// Clear all data
  void clear() {
    _paymentMethods = [];
    _customerInfo = null;
    _clientSecret = null;
    _paymentIntentId = null;
    _error = null;
    notifyListeners();
  }

  /// Create payment method (for backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> createPaymentMethod(
    dynamic controller,
  ) async {
    // This method is deprecated - use SetupIntent flow instead
    return ApiResponse(
      success: false,
      message: 'Please use the SetupIntent flow for payment method creation.',
    );
  }
}
