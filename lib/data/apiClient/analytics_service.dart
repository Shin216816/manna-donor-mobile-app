import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/api_service.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();

  ApiService get apiService => _apiService;

  /// Get user analytics data
  Future<ApiResponse<Map<String, dynamic>>> getUserAnalytics() async {
    try {
      final response = await _apiService.get('/mobile/analytics/user');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch user analytics: $e',
      );
    }
  }

  /// Get donation dashboard data
  Future<ApiResponse<Map<String, dynamic>>> getDonationDashboard() async {
    try {
      final response = await _apiService.get('/mobile/bank/dashboard');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch donation dashboard: $e',
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

  /// Get mobile impact summary (mobile-specific endpoint)
  Future<ApiResponse<Map<String, dynamic>>> getMobileImpactSummary() async {
    try {
      final response = await _apiService.get('/mobile/impact-summary');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch mobile impact summary: $e',
      );
    }
  }

  /// Get mobile dashboard (mobile-specific endpoint)
  Future<ApiResponse<Map<String, dynamic>>> getMobileDashboard() async {
    try {
      final response = await _apiService.get('/mobile/dashboard');
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch mobile dashboard: $e',
      );
    }
  }
}
