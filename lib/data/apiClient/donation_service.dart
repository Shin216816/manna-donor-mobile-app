import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/donation_preferences.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/core/api_service.dart';

class DonationService {
  final ApiService _api = ApiService();

  /// Get user's donation preferences
  Future<ApiResponse<DonationPreferences>> getPreferences() async {
    try {
      final response = await _api.get('/mobile/bank/preferences');
      return ApiResponse.fromJson(
        response.data,
        (data) => DonationPreferences.fromJson(data),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get preferences: $e',
      );
    }
  }

  /// Update user's donation preferences
  Future<ApiResponse<DonationPreferences>> updatePreferences(
    DonationPreferences prefs,
  ) async {
    try {
      final response = await _api.put('/mobile/bank/preferences', data: prefs);
      return ApiResponse.fromJson(
        response.data,
        (data) => DonationPreferences.fromJson(data),
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to update preferences: $e',
      );
    }
  }

  /// Create a donation schedule
  Future<ApiResponse<Map<String, dynamic>>> createDonationSchedule({
    required String churchId,
    required double amount,
    required String frequency,
    required String dayOfWeek,
    required String dayOfMonth,
    required String startDate,
    required String endDate,
    required bool isActive,
  }) async {
    try {
      final response = await _api.post(
        '/mobile/bank/donation-schedules',
        data: {
          'church_id': churchId,
          'amount': amount,
          'frequency': frequency,
          'day_of_week': dayOfWeek,
          'day_of_month': dayOfMonth,
          'start_date': startDate,
          'end_date': endDate,
          'is_active': isActive,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to create donation schedule: $e',
      );
    }
  }

  /// Process a donation charge
  Future<ApiResponse<Map<String, dynamic>>> processDonationCharge({
    required String churchId,
    required double amount,
    required String paymentMethodId,
    String? description,
  }) async {
    try {
      final data = {
        'church_id': churchId,
        'amount': amount,
        'payment_method_id': paymentMethodId,
        if (description != null) 'description': description,
      };

      final response = await _api.post('/mobile/bank/charge', data: data);
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to process donation charge: $e',
      );
    }
  }

  /// Charge a donation (alias for processDonationCharge)
  Future<ApiResponse<Map<String, dynamic>>> charge({
    required String churchId,
    required double amount,
    required String paymentMethodId,
    String? description,
  }) async {
    return processDonationCharge(
      churchId: churchId,
      amount: amount,
      paymentMethodId: paymentMethodId,
      description: description,
    );
  }

  /// Calculate roundups
  Future<ApiResponse<Map<String, dynamic>>> calculateRoundups() async {
    try {
      final response = await _api.get('/mobile/bank/calculate-roundups');
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

  /// Get donation history
  Future<ApiResponse<List<DonationHistory>>> getDonationHistory() async {
    try {
      final response = await _api.get('/mobile/bank/donation-history');
      return ApiResponse.fromJson(response.data, (data) {
        if (data is List) {
          return data.map((json) => DonationHistory.fromJson(json)).toList();
        }
        return [];
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to get donation history: $e',
      );
    }
  }
}
