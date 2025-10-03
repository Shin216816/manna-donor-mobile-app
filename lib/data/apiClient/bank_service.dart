import 'package:dio/dio.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/bank_account.dart';
import 'package:manna_donate_app/data/models/donation_preferences.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/core/api_service.dart';

class BankService {
  final ApiService _apiService = ApiService();

  ApiService get apiService => _apiService;

  /// Create Plaid Link Token
  Future<ApiResponse<Map<String, dynamic>>> createLinkToken() async {
    try {
      final userId = await _apiService.getUserId();

  

      if (userId == 0) {
        return ApiResponse(
          success: false,
          message: 'User not authenticated. Please log in again.',
        );
      }

      final response = await _apiService.post(
        '/mobile/bank/link-token',
        data: {
          'client_name': 'Manna Church',
          'country_codes': ['US'],
          'language': 'en',
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Access denied. Please log in again.',
        );
      } else if (e.response?.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Authentication required. Please log in again.',
        );
      }
      return ApiResponse(
        success: false,
        message: 'Failed to create link token: ${e.message}',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create link token: $e',
      );
    }
  }

  /// Exchange Plaid public token for access token
  Future<ApiResponse<Map<String, dynamic>>> exchangePublicToken(
    String publicToken,
  ) async {
    try {
      final response = await _apiService.post(
        '/mobile/bank/exchange-token',
        data: {'public_token': publicToken},
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to link bank account: $e',
      );
    }
  }

  /// Save payment method to Stripe
  Future<ApiResponse<Map<String, dynamic>>> savePaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _apiService.post(
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

  /// Ensure user has a Stripe customer ID
  Future<ApiResponse<Map<String, dynamic>>> ensureStripeCustomer() async {
    try {
      final response = await _apiService.post('/mobile/bank/ensure-stripe-customer');

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to ensure Stripe customer: $e',
      );
    }
  }

  /// Get user's linked bank accounts
  Future<ApiResponse<List<BankAccount>>> getBankAccounts() async {
    try {
      final response = await _apiService.get('/mobile/bank/accounts');

      // Parse accounts from response schema
      return ApiResponse.fromJson(response.data, (data) {
        // The backend returns accounts directly in the data field as a list
        if (data is List) {
          return data.map((json) => BankAccount.fromJson(json)).toList();
        }
        // Fallback: try to get accounts from data['accounts'] if it's a map
        if (data is Map && data['accounts'] != null) {
          final accountsList = data['accounts'] as List;
          return accountsList
              .map((json) => BankAccount.fromJson(json))
              .toList();
        }
        // Return empty list if no accounts found
        return <BankAccount>[];
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch bank accounts: $e',
      );
    }
  }

  /// Get donation preferences
  Future<ApiResponse<DonationPreferences?>> getPreferences() async {
    try {
      final response = await _apiService.get('/mobile/bank/preferences');
      // Parse preferences from response schema
      return ApiResponse.fromJson(response.data, (data) {
        // The backend returns preferences directly in the data field
        if (data != null && data is Map) {
          return DonationPreferences.fromJson(Map<String, dynamic>.from(data));
        }
        // Return null if no preferences exist
        return null;
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch preferences: $e',
      );
    }
  }

  /// Update donation preferences
  Future<ApiResponse<DonationPreferences>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await _apiService.put(
        '/mobile/bank/preferences',
        data: preferences,
      );
      // Parse updated preferences from response schema
      return ApiResponse.fromJson(response.data, (data) {
        // Handle both data['preferences'] and data as direct object
        final preferencesData = (data is Map && data['preferences'] != null)
            ? data['preferences']
            : data;
        if (preferencesData != null) {
          return DonationPreferences.fromJson(preferencesData);
        }
        return DonationPreferences(frequency: 'biweekly', multiplier: '1x');
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to update preferences: $e',
      );
    }
  }

  /// Get donation dashboard
  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    try {
      final response = await _apiService.get('/mobile/bank/dashboard');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch dashboard: $e',
      );
    }
  }

  /// Get donation history
  Future<ApiResponse<List<DonationHistory>>> getDonationHistory() async {
    try {
      final response = await _apiService.get('/mobile/bank/donation-history');
      // Parse donations from response schema: data contains donations array
      return ApiResponse.fromJson(response.data, (data) {
        final dataMap = data as Map<String, dynamic>? ?? {};
        final historyData = dataMap['donations'] as List? ?? [];
        return historyData.map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return DonationHistory.fromJson(item);
            } else if (item is Map) {
              return DonationHistory.fromJson(Map<String, dynamic>.from(item));
            } else {
              return DonationHistory(id: 0, amount: 0.0, status: 'unknown');
            }
          } catch (e) {
            return DonationHistory(id: 0, amount: 0.0, status: 'unknown');
          }
        }).toList();
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch donation history: $e',
      );
    }
  }

  /// Get donation summary
  Future<ApiResponse<Map<String, dynamic>>> getDonationSummary() async {
    try {
      final response = await _apiService.get('/mobile/bank/donation-summary');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch donation summary: $e',
      );
    }
  }

  /// Calculate roundups for a date range
  Future<ApiResponse<Map<String, dynamic>>> calculateRoundups({
    required String startDate,
    required String endDate,
    String multiplier = '1x',
  }) async {
    try {
      final response = await _apiService.post(
        '/mobile/bank/calculate-roundups',
        data: {
          'start_date': startDate,
          'end_date': endDate,
          'multiplier': multiplier,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to calculate roundups: $e',
      );
    }
  }

  /// Execute donation batch
  Future<ApiResponse<Map<String, dynamic>>> executeDonationBatch(
    int batchId,
  ) async {
    try {
      final response = await _apiService.post(
        '/mobile/bank/execute-batch/$batchId',
        data: {},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to execute donation batch: $e',
      );
    }
  }

  /// Get transactions for a date range
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({
    required String startDate,
    required String endDate,
    List<String>? accountIds,
  }) async {
    try {
      final response = await _apiService.post(
        '/mobile/bank/transactions',
        data: {
          'start_date': startDate,
          'end_date': endDate,
          'account_ids': accountIds,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch transactions: $e',
      );
    }
  }

  /// Get payment methods
  Future<ApiResponse<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _apiService.get('/mobile/bank/payment-methods');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch payment methods: $e',
      );
    }
  }

  /// Delete payment method
  Future<ApiResponse<Map<String, dynamic>>> deletePaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _apiService.delete(
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

  /// Set default payment method
  Future<ApiResponse<Map<String, dynamic>>> setDefaultPaymentMethod(
    String paymentMethodId,
  ) async {
    try {
      final response = await _apiService.put(
        '/mobile/bank/payment-methods/$paymentMethodId/default',
        data: {},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to set default payment method: $e',
      );
    }
  }
}
