import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Cache expiration times (in minutes)
  static const Map<String, int> _cacheExpiration = {
    'bank_accounts': 15,
    'preferences': 10,
    'dashboard': 5,
    'donation_history': 10,
    'donation_summary': 5,
    'payment_methods': 15,
    'transactions': 5,
    'roundup_status': 10,
    'roundup_settings': 15,
    'pending_roundups': 5,
    'roundup_history': 10,
    'user_profile': 15,
    'user_preferences': 10,
    'profile_image': 30,
    'church_messages': 10,
    'available_churches': 30,
    'unread_count': 5,
    'enhanced_roundup_status': 10,
    'roundup_transactions': 5,
    'this_month_roundup_transactions': 5,
  };

  // Cache keys
  static const String _userIdKey = 'user_id';
  static const String _lastFetchKey = 'last_fetch_time';

  /// Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get cache key with user ID
  Future<String> _getCacheKey(String dataType) async {
    await _initPrefs();
    final userId = _prefs?.getString(_userIdKey) ?? '0';
    return '${dataType}_$userId';
  }

  /// Cache data with expiration
  Future<void> cacheData(String dataType, dynamic data) async {
    try {
      final key = await _getCacheKey(dataType);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheData = {
        'data': data,
        'timestamp': timestamp,
        'expiration': _cacheExpiration[dataType] ?? 10,
      };
      
      await _secureStorage.write(
        key: key,
        value: jsonEncode(cacheData),
      );
    } catch (e) {
      // Handle cache error silently
    }
  }

  /// Get cached data if valid
  Future<dynamic> getCachedData(String dataType) async {
    try {
      final key = await _getCacheKey(dataType);
      final cachedString = await _secureStorage.read(key: key);
      
      if (cachedString == null) return null;
      
      final cached = jsonDecode(cachedString);
      final timestamp = cached['timestamp'] as int;
      final expirationMinutes = cached['expiration'] as int;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationTime = timestamp + (expirationMinutes * 60 * 1000);
      
      if (now > expirationTime) {
        // Cache expired, remove it
        await _secureStorage.delete(key: key);
        return null;
      }
      
      return cached['data'];
    } catch (e) {
      return null;
    }
  }

  /// Check if cache is valid
  Future<bool> isCacheValid(String dataType) async {
    final data = await getCachedData(dataType);
    return data != null;
  }

  /// Invalidate specific cache
  Future<void> invalidateCache(String dataType) async {
    try {
      final key = await _getCacheKey(dataType);
      await _secureStorage.delete(key: key);
    } catch (e) {
      // Handle invalidation error silently
    }
  }



  /// Clear all cache for current user
  Future<void> clearAllCache() async {
    try {
      await _initPrefs();
      final userId = _prefs?.getString(_userIdKey) ?? '0';
      final keys = await _secureStorage.readAll();
      
      for (final key in keys.keys) {
        if (key.contains('_$userId')) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      // Handle clear error silently
    }
  }

  /// Set user ID for cache management
  Future<void> setUserId(String userId) async {
    await _initPrefs();
    await _prefs?.setString(_userIdKey, userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    await _initPrefs();
    return _prefs?.getString(_userIdKey);
  }

  /// Set last fetch time
  Future<void> setLastFetchTime() async {
    await _initPrefs();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs?.setInt(_lastFetchKey, now);
  }

  /// Get last fetch time
  Future<int?> getLastFetchTime() async {
    await _initPrefs();
    return _prefs?.getInt(_lastFetchKey);
  }

  /// Check if initial data fetch is needed
  Future<bool> needsInitialFetch() async {
    final lastFetch = await getLastFetchTime();
    if (lastFetch == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastFetch = now - lastFetch;
    const maxAge = 30 * 60 * 1000; // 30 minutes
    
    return timeSinceLastFetch > maxAge;
  }

  /// Invalidate cache when data is modified
  Future<void> invalidateOnDataChange(String dataType) async {
    // Invalidate the specific data type
    await invalidateCache(dataType);
    
    // Also invalidate related data types that might be affected
    final relatedDataTypes = _getRelatedDataTypes(dataType);
    for (final relatedType in relatedDataTypes) {
      await invalidateCache(relatedType);
    }
  }

  /// Get related data types that should be invalidated together
  List<String> _getRelatedDataTypes(String dataType) {
    switch (dataType) {
      case 'bank_accounts':
        return ['dashboard', 'donation_summary', 'transactions'];
      case 'preferences':
        return ['dashboard', 'donation_summary'];
      case 'payment_methods':
        return ['dashboard', 'donation_summary'];
      case 'roundup_status':
        return ['roundup_transactions', 'pending_roundups'];
      case 'roundup_settings':
        return ['roundup_status', 'roundup_transactions'];
      case 'user_profile':
        return ['user_preferences'];
      case 'donation_history':
        return ['donation_summary', 'dashboard'];
      default:
        return [];
    }
  }

  /// Smart cache get - returns cached data if available, null if needs fetch
  Future<dynamic> smartGetCachedData(String dataType) async {
    final cachedData = await getCachedData(dataType);
    if (cachedData != null) {
      return cachedData;
    }
    return null; // Indicates need to fetch from API
  }

  /// Check if data needs to be fetched (no cache or expired)
  Future<bool> needsFetch(String dataType) async {
    final cachedData = await getCachedData(dataType);
    return cachedData == null;
  }

  /// Get cache age in minutes
  Future<int?> getCacheAge(String dataType) async {
    try {
      final key = await _getCacheKey(dataType);
      final cachedString = await _secureStorage.read(key: key);
      
      if (cachedString == null) return null;
      
      final cached = jsonDecode(cachedString);
      final timestamp = cached['timestamp'] as int;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      return ((now - timestamp) / (60 * 1000)).round();
    } catch (e) {
      return null;
    }
  }

  /// Clear all caches for current user
  Future<void> clearAllCaches() async {
    try {
      await _initPrefs();
      final userId = _prefs?.getString(_userIdKey) ?? '0';
      
      // Get all keys for current user
      final allKeys = await _secureStorage.readAll();
      final userKeys = allKeys.keys.where((key) => key.startsWith('${userId}_'));
      
      // Delete all user-specific caches
      for (final key in userKeys) {
        await _secureStorage.delete(key: key);
      }
    } catch (e) {
      // Handle cache error silently
    }
  }

  /// Invalidate multiple caches at once
  Future<void> invalidateMultipleCaches(List<String> dataTypes) async {
    try {
      for (final dataType in dataTypes) {
        await invalidateCache(dataType);
      }
    } catch (e) {
      // Handle cache error silently
    }
  }
}
