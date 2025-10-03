import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class DataCacheManager {
  static final DataCacheManager _instance = DataCacheManager._internal();
  factory DataCacheManager() => _instance;
  DataCacheManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();

  // Cache duration constants
  static const Duration _shortCache = Duration(minutes: 5);
  static const Duration _mediumCache = Duration(minutes: 15);
  static const Duration _longCache = Duration(hours: 1);
  static const Duration _veryLongCache = Duration(hours: 6);

  // Cache keys
  static const String _bankAccountsKey = 'cached_bank_accounts';
  static const String _preferencesKey = 'cached_preferences';
  static const String _dashboardKey = 'cached_dashboard';
  static const String _donationHistoryKey = 'cached_donation_history';
  static const String _donationSummaryKey = 'cached_donation_summary';
  static const String _paymentMethodsKey = 'cached_payment_methods';
  static const String _roundupStatusKey = 'cached_roundup_status';
  static const String _enhancedRoundupStatusKey = 'cached_enhanced_roundup_status';
  static const String _churchMessagesKey = 'cached_church_messages';

  /// Cache data with timestamp
  Future<void> cacheData(String key, dynamic data, Duration cacheDuration) async {
    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(cacheDuration).millisecondsSinceEpoch,
      };
      
      await _storage.write(
        key: key,
        value: jsonEncode(cacheEntry),
      );
      
      _logger.i('Cached data for key: $key, expires in: ${cacheDuration.inMinutes} minutes');
    } catch (e) {
      _logger.e('Failed to cache data for key: $key, error: $e');
    }
  }

  /// Get cached data if not expired
  Future<dynamic> getCachedData(String key) async {
    try {
      final cachedString = await _storage.read(key: key);
      if (cachedString == null) return null;

      final cacheEntry = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiresAt = cacheEntry['expiresAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now > expiresAt) {
        // Cache expired, remove it
        await _storage.delete(key: key);
        _logger.i('Cache expired for key: $key');
        return null;
      }

      _logger.i('Retrieved cached data for key: $key');
      return cacheEntry['data'];
    } catch (e) {
      _logger.e('Failed to get cached data for key: $key, error: $e');
      return null;
    }
  }

  /// Check if data is cached and not expired
  Future<bool> hasValidCache(String key) async {
    try {
      final cachedString = await _storage.read(key: key);
      if (cachedString == null) return false;

      final cacheEntry = jsonDecode(cachedString) as Map<String, dynamic>;
      final expiresAt = cacheEntry['expiresAt'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      return now <= expiresAt;
    } catch (e) {
      return false;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      await _storage.delete(key: key);
      _logger.i('Cleared cache for key: $key');
    } catch (e) {
      _logger.e('Failed to clear cache for key: $key, error: $e');
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      await _storage.deleteAll();
      _logger.i('Cleared all caches');
    } catch (e) {
      _logger.e('Failed to clear all caches, error: $e');
    }
  }

  /// Get cache age in minutes
  Future<int?> getCacheAge(String key) async {
    try {
      final cachedString = await _storage.read(key: key);
      if (cachedString == null) return null;

      final cacheEntry = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return ((now - timestamp) / 60000).round(); // Convert to minutes
    } catch (e) {
      return null;
    }
  }

  // Specific cache methods for different data types
  Future<void> cacheBankAccounts(List<dynamic> accounts) async {
    await cacheData(_bankAccountsKey, accounts, _mediumCache);
  }

  Future<List<dynamic>?> getCachedBankAccounts() async {
    return await getCachedData(_bankAccountsKey);
  }

  Future<void> cachePreferences(dynamic preferences) async {
    await cacheData(_preferencesKey, preferences, _longCache);
  }

  Future<dynamic> getCachedPreferences() async {
    return await getCachedData(_preferencesKey);
  }

  Future<void> cacheDashboard(dynamic dashboard) async {
    await cacheData(_dashboardKey, dashboard, _shortCache);
  }

  Future<dynamic> getCachedDashboard() async {
    return await getCachedData(_dashboardKey);
  }

  Future<void> cacheDonationHistory(List<dynamic> history) async {
    await cacheData(_donationHistoryKey, history, _mediumCache);
  }

  Future<List<dynamic>?> getCachedDonationHistory() async {
    return await getCachedData(_donationHistoryKey);
  }

  Future<void> cacheDonationSummary(dynamic summary) async {
    await cacheData(_donationSummaryKey, summary, _shortCache);
  }

  Future<dynamic> getCachedDonationSummary() async {
    return await getCachedData(_donationSummaryKey);
  }

  Future<void> cachePaymentMethods(List<dynamic> methods) async {
    await cacheData(_paymentMethodsKey, methods, _longCache);
  }

  Future<List<dynamic>?> getCachedPaymentMethods() async {
    return await getCachedData(_paymentMethodsKey);
  }

  Future<void> cacheRoundupStatus(dynamic status) async {
    await cacheData(_roundupStatusKey, status, _shortCache);
  }

  Future<dynamic> getCachedRoundupStatus() async {
    return await getCachedData(_roundupStatusKey);
  }

  Future<void> cacheEnhancedRoundupStatus(dynamic status) async {
    await cacheData(_enhancedRoundupStatusKey, status, _shortCache);
  }

  Future<dynamic> getCachedEnhancedRoundupStatus() async {
    return await getCachedData(_enhancedRoundupStatusKey);
  }

  Future<void> cacheChurchMessages(List<dynamic> messages) async {
    await cacheData(_churchMessagesKey, messages, _mediumCache);
  }

  Future<List<dynamic>?> getCachedChurchMessages() async {
    return await getCachedData(_churchMessagesKey);
  }

  /// Clear all bank-related caches
  Future<void> clearBankCaches() async {
    await Future.wait([
      clearCache(_bankAccountsKey),
      clearCache(_preferencesKey),
      clearCache(_dashboardKey),
      clearCache(_donationHistoryKey),
      clearCache(_donationSummaryKey),
      clearCache(_paymentMethodsKey),
    ]);
  }

  /// Clear all roundup-related caches
  Future<void> clearRoundupCaches() async {
    await Future.wait([
      clearCache(_roundupStatusKey),
      clearCache(_enhancedRoundupStatusKey),
    ]);
  }

  /// Clear all donation-related caches
  Future<void> clearDonationCaches() async {
    await Future.wait([
      clearCache(_donationHistoryKey),
      clearCache(_donationSummaryKey),
    ]);
  }
}
