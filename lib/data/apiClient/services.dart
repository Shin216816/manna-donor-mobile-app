export 'auth_service.dart';
export 'bank_service.dart';
export 'church_service.dart';
export 'donation_service.dart';
export 'stripe_service.dart';
export 'notification_service.dart';
import 'package:manna_donate_app/core/api_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';

class MobileService {
  final ApiService _api = ApiService();

  /// Get roundup settings for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getRoundupSettings() async {
    final response = await _api.get('/mobile/roundup-settings');
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Update roundup settings for mobile app
  Future<ApiResponse<Map<String, dynamic>>> updateRoundupSettings(
    Map<String, dynamic> settings,
  ) async {
    final response = await _api.put('/mobile/roundup-settings', data: settings);
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Get transactions for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({
    int limit = 20,
  }) async {
    final response = await _api.get(
      '/mobile/transactions',
      queryParameters: {'limit': limit},
    );
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Get pending roundups for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getPendingRoundups() async {
    final response = await _api.get('/mobile/pending-roundups');
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Quick toggle roundups (pause/resume)
  Future<ApiResponse<Map<String, dynamic>>> quickToggleRoundups(
    bool pause,
  ) async {
    final response = await _api.post(
      '/mobile/quick-toggle',
      queryParameters: {'pause': pause},
    );
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Get donation history for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getDonationHistory({
    int limit = 20,
  }) async {
    try {
      final response = await _api.get(
        '/mobile/donation-history',
        queryParameters: {'limit': limit},
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch donation history: $e',
      );
    }
  }

  /// Get impact summary for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getImpactSummary() async {
    final response = await _api.get('/mobile/impact-summary');
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }

  /// Get dashboard for mobile app
  Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    final response = await _api.get('/mobile/dashboard');
    return ApiResponse.fromJson(
      response.data,
      (data) => data as Map<String, dynamic>,
    );
  }
}
