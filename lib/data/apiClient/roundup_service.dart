import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/api_service.dart';

class RoundupService {
  final ApiService _apiService = ApiService();

  /// Get enhanced roundup status with accumulated roundups and transfer dates
  Future<ApiResponse<Map<String, dynamic>>> getEnhancedRoundupStatus() async {
    try {
      final response = await _apiService.get('/mobile/enhanced-roundup-status');
      final result = ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch enhanced roundup status: $e',
      );
    }
  }

  /// Get roundup status and pending amounts
  Future<ApiResponse<Map<String, dynamic>>> getRoundupStatus() async {
    try {
      final response = await _apiService.get('/mobile/pending-roundups');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch roundup status: $e',
      );
    }
  }

  /// Get roundup settings
  Future<ApiResponse<Map<String, dynamic>>> getRoundupSettings() async {
    try {
      final response = await _apiService.get('/mobile/roundup-settings');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch roundup settings: $e',
      );
    }
  }

  /// Update roundup settings
  Future<ApiResponse<Map<String, dynamic>>> updateRoundupSettings({
    required bool isActive,
    required String multiplier,
    required String frequency,
    List<int>? churchIds,
  }) async {
    try {
      final response = await _apiService.put(
        '/mobile/roundup-settings',
        data: {
          'pause': !isActive,
          'multiplier': multiplier,
          'frequency': frequency,
          if (churchIds != null) 'church_ids': churchIds,
        },
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to update roundup settings: $e',
      );
    }
  }

  /// Get pending roundups
  Future<ApiResponse<List<Map<String, dynamic>>>> getPendingRoundups() async {
    try {
      final response = await _apiService.get('/mobile/pending-roundups');
      return ApiResponse.fromJson(response.data, (data) {
        final list = data['pending_roundups'] as List? ?? [];
        return list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch pending roundups: $e',
      );
    }
  }

  /// Get roundup transactions
  Future<ApiResponse<List<Map<String, dynamic>>>> getRoundupTransactions({
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/mobile/transactions',
        queryParameters: {'limit': limit},
      );
      return ApiResponse.fromJson(response.data, (data) {
        final list = data['transactions'] as List? ?? [];
        return list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch roundup transactions: $e',
      );
    }
  }

  /// Get this month's roundup transactions specifically
  Future<ApiResponse<List<Map<String, dynamic>>>>
  getThisMonthRoundupTransactions() async {
    try {
      // Get this month's transactions specifically
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final response = await _apiService.get(
        '/mobile/transactions',
        queryParameters: {
          'start_date': startOfMonth.toIso8601String().split('T')[0],
          'end_date': endOfMonth.toIso8601String().split('T')[0],
        },
      );
      return ApiResponse.fromJson(response.data, (data) {
        final list = data['transactions'] as List? ?? [];
        return list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch this month\'s roundup transactions: $e',
      );
    }
  }

  /// Quick toggle roundups on/off
  Future<ApiResponse<Map<String, dynamic>>> quickToggleRoundups({
    required bool pause,
  }) async {
    try {
      final response = await _apiService.post(
        '/mobile/quick-toggle?pause=$pause',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to toggle roundups: $e',
      );
    }
  }

  /// Get donation history
  Future<ApiResponse<Map<String, dynamic>>> getDonationHistory() async {
    try {
      final response = await _apiService.get('/mobile/donation-history');
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
}
