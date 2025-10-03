import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/analytics_service.dart';
import 'package:manna_donate_app/core/cache_manager.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();
  final CacheManager _cacheManager = CacheManager();

  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _impactData;
  Map<String, dynamic>? _mobileDashboardData;
  bool _loading = false;
  String? _error;

  // Getters
  Map<String, dynamic>? get analyticsData => _analyticsData;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get impactData => _impactData;
  Map<String, dynamic>? get mobileDashboardData => _mobileDashboardData;
  bool get loading => _loading;
  String? get error => _error;

  // Computed properties from mobile-specific endpoints
  double get totalDonated => _impactData?['total_donated']?.toDouble() ?? 0.0;
  double get thisMonthDonated =>
      _impactData?['this_month_donated']?.toDouble() ?? 0.0;
  int get totalBatches => _impactData?['total_batches'] ?? 0;
  double get averagePerBatch =>
      _impactData?['average_per_batch']?.toDouble() ?? 0.0;

  // Impact data from mobile dashboard
  int get mealsProvided => _mobileDashboardData?['meals_provided'] ?? 0;
  int get studentsHelped => _mobileDashboardData?['students_helped'] ?? 0;
  int get medicalVisits => _mobileDashboardData?['medical_visits'] ?? 0;
  int get educationHelped => _mobileDashboardData?['education_helped'] ?? 0;
  int get healthcareVisits => _mobileDashboardData?['healthcare_visits'] ?? 0;

  /// Load mobile-specific impact summary data (cache-first)
  Future<void> loadMobileImpactSummary() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('mobile_impact_summary');
    if (cachedData != null) {
      _impactData = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchMobileImpactSummaryFromAPI();
  }

  /// Fetch mobile impact summary from API (used when cache is invalid or data changes)
  Future<void> _fetchMobileImpactSummaryFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _analyticsService.getMobileImpactSummary();
      if (response.success && response.data != null) {
        _impactData = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('mobile_impact_summary', response.data!);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load mobile impact summary: $e';
    }

    _loading = false;
    notifyListeners();
  }

  /// Load mobile-specific dashboard data (cache-first)
  Future<void> loadMobileDashboard() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('mobile_dashboard');
    if (cachedData != null) {
      _mobileDashboardData = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchMobileDashboardFromAPI();
  }

  /// Fetch mobile dashboard from API (used when cache is invalid or data changes)
  Future<void> _fetchMobileDashboardFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _analyticsService.getMobileDashboard();
      if (response.success && response.data != null) {
        _mobileDashboardData = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('mobile_dashboard', response.data!);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load mobile dashboard: $e';
    }

    _loading = false;
    notifyListeners();
  }

  /// Load legacy analytics data (for backward compatibility) - cache-first
  /// NOTE: This method is deprecated and should not be used
  Future<void> loadAnalytics() async {
    // This method is deprecated - use loadMobileImpactSummary() or loadMobileDashboard() instead
    // No longer making unnecessary API calls
    return;
  }

  /// Fetch analytics from API (used when cache is invalid or data changes)
  /// NOTE: This method is deprecated and should not be used
  Future<void> _fetchAnalyticsFromAPI() async {
    // This method is deprecated - no longer making unnecessary API calls
    return;
  }

  /// Load legacy dashboard data (for backward compatibility) - cache-first
  Future<void> loadDashboard() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_dashboard');
    if (cachedData != null) {
      _dashboardData = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDashboardFromAPI();
  }

  /// Fetch dashboard from API (used when cache is invalid or data changes)
  Future<void> _fetchDashboardFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _analyticsService.getDonationDashboard();
      if (response.success && response.data != null) {
        _dashboardData = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('donation_dashboard', response.data!);
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load dashboard: $e';
    }

    _loading = false;
    notifyListeners();
  }

  /// Load donation dashboard data (cache-first)
  Future<void> loadDonationDashboard() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_dashboard');
    if (cachedData != null) {
      _dashboardData = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDashboardFromAPI();
  }

  /// Load legacy impact summary (for backward compatibility)
  Future<void> loadImpactSummary() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _analyticsService.getDonationSummary();
      if (response.success && response.data != null) {
        _impactData = response.data!;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to load impact summary: $e';
    }

    _loading = false;
    notifyListeners();
  }

  /// Refresh all mobile-specific analytics data
  Future<void> refreshAll() async {
    await Future.wait([loadMobileImpactSummary(), loadMobileDashboard()]);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data in AnalyticsProvider
  void clearAllData() {
    _analyticsData = null;
    _dashboardData = null;
    _impactData = null;
    _mobileDashboardData = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh methods for pull-to-refresh (bypass cache)
  Future<void> refreshMobileImpactSummary() async {
    await _fetchMobileImpactSummaryFromAPI();
  }

  Future<void> refreshMobileDashboard() async {
    await _fetchMobileDashboardFromAPI();
  }

  Future<void> refreshAnalytics() async {
    await _fetchAnalyticsFromAPI();
  }

  Future<void> refreshDashboard() async {
    await _fetchDashboardFromAPI();
  }

  /// Get monthly donation data for charts
  List<double> get monthlyDonations {
    final monthlyData =
        _mobileDashboardData?['monthly_donations'] as List<dynamic>? ?? [];
    return monthlyData.map((e) => (e as num).toDouble()).toList();
  }

  /// Get donation trends
  Map<String, dynamic> get donationTrends {
    return _mobileDashboardData?['donation_trends'] ?? {};
  }

  /// Get church impact data
  Map<String, dynamic> get churchImpact {
    return _mobileDashboardData?['church_impact'] ?? {};
  }
}
