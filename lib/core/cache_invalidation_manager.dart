import 'package:logger/logger.dart';
import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/data/repository/auth_provider.dart';
import 'package:manna_donate_app/data/repository/church_provider.dart';
import 'package:manna_donate_app/data/repository/roundup_provider.dart';
import 'package:manna_donate_app/data/repository/profile_provider.dart';

import 'package:manna_donate_app/data/repository/notification_provider.dart';
import 'package:manna_donate_app/data/repository/church_message_provider.dart';

class CacheInvalidationManager {
  static final Logger _logger = Logger();
  static final CacheManager _cacheManager = CacheManager();

  // Define cache invalidation rules for different endpoints
  static const Map<String, List<String>> _cacheInvalidationRules = {
    // Bank-related endpoints
    '/mobile/bank/accounts': ['bank_accounts'],
    '/mobile/bank/preferences': ['preferences'],
    '/mobile/bank/payment-methods': ['payment_methods'],
    '/mobile/bank/transactions': ['transactions', 'donation_history'],
    '/mobile/bank/charge': ['transactions', 'donation_history', 'donation_summary'],
    '/mobile/bank/roundup': ['roundup_status', 'roundup_transactions', 'pending_roundups'],
    '/mobile/bank/ensure-stripe-customer': ['payment_methods'],
    
    // Profile-related endpoints
    '/mobile/auth/profile': ['user_profile', 'user_preferences'],
    '/mobile/auth/profile/image': ['user_profile', 'profile_image'],
    '/mobile/auth/profile/preferences': ['user_preferences'],
    '/mobile/auth/profile/verify-email': ['user_profile'],
    '/mobile/auth/profile/verify-phone': ['user_profile'],
    
    // Church-related endpoints
    '/mobile/auth/church': ['user_profile', 'available_churches'],
    '/mobile/church/messages': ['church_messages', 'unread_count'],
    
    // Stripe-related endpoints
    '/mobile/stripe/payment-methods': ['payment_methods'],
    
    // Notification endpoints
    '/mobile/donor/notifications': ['unread_count'],
  };

  /// Invalidate cache and refresh data after POST/PUT/DELETE request
  static Future<void> invalidateAndRefreshCache(String endpoint, {Map<String, dynamic>? requestData}) async {
    try {
      _logger.i('Invalidating cache for endpoint: $endpoint');
      
      // Get related cache types for this endpoint
      final cacheTypes = _getRelatedCacheTypes(endpoint);
      
      if (cacheTypes.isEmpty) {
        _logger.w('No cache types found for endpoint: $endpoint');
        return;
      }

      // Invalidate related caches
      await _cacheManager.invalidateMultipleCaches(cacheTypes);
      _logger.d('Invalidated caches: $cacheTypes');

      // Refresh data from server
      await _refreshDataFromServer(cacheTypes, endpoint, requestData);
      
      _logger.i('Cache invalidation and refresh completed for: $endpoint');
    } catch (e) {
      _logger.e('Cache invalidation error for $endpoint: $e');
    }
  }

  /// Get related cache types for an endpoint
  static List<String> _getRelatedCacheTypes(String endpoint) {
    // Find exact match first
    if (_cacheInvalidationRules.containsKey(endpoint)) {
      return _cacheInvalidationRules[endpoint]!;
    }

    // Find partial matches
    for (final entry in _cacheInvalidationRules.entries) {
      if (endpoint.startsWith(entry.key) || entry.key.startsWith(endpoint)) {
        return entry.value;
      }
    }

    // Default cache types based on endpoint patterns - MORE SPECIFIC
    if (endpoint.contains('bank/accounts')) {
      return ['bank_accounts'];
    } else if (endpoint.contains('bank/preferences')) {
      return ['preferences'];
    } else if (endpoint.contains('bank/payment-methods')) {
      return ['payment_methods'];
    } else if (endpoint.contains('bank/transactions')) {
      return ['transactions', 'donation_history'];
    } else if (endpoint.contains('bank/charge')) {
      return ['transactions', 'donation_history', 'donation_summary'];
    } else if (endpoint.contains('bank/roundup')) {
      return ['roundup_status', 'roundup_transactions', 'pending_roundups'];
    } else if (endpoint.contains('profile')) {
      return ['user_profile', 'user_preferences'];
    } else if (endpoint.contains('church')) {
      return ['user_profile', 'available_churches'];
    } else if (endpoint.contains('roundup')) {
      return ['roundup_status', 'roundup_transactions', 'pending_roundups'];
    } else if (endpoint.contains('notification')) {
      return ['unread_count'];
    } else if (endpoint.contains('payment')) {
      return ['payment_methods'];
    }

    return [];
  }

  /// Refresh data from server based on cache types
  static Future<void> _refreshDataFromServer(List<String> cacheTypes, String endpoint, Map<String, dynamic>? requestData) async {
    try {
      final refreshTasks = <Future<void>>[];

      for (final cacheType in cacheTypes) {
        switch (cacheType) {
          case 'bank_accounts':
            refreshTasks.add(_refreshBankAccounts());
            break;
          case 'preferences':
            refreshTasks.add(_refreshPreferences());
            break;
          case 'payment_methods':
            refreshTasks.add(_refreshPaymentMethods());
            break;
          case 'dashboard':
            refreshTasks.add(_refreshDashboard());
            break;
          case 'donation_summary':
            refreshTasks.add(_refreshDonationSummary());
            break;
          case 'transactions':
            refreshTasks.add(_refreshTransactions());
            break;
          case 'donation_history':
            refreshTasks.add(_refreshDonationHistory());
            break;
          case 'roundup_status':
            refreshTasks.add(_refreshRoundupStatus());
            break;
          case 'roundup_transactions':
            refreshTasks.add(_refreshRoundupTransactions());
            break;
          case 'pending_roundups':
            refreshTasks.add(_refreshPendingRoundups());
            break;
          case 'user_profile':
            refreshTasks.add(_refreshUserProfile());
            break;
          case 'user_preferences':
            refreshTasks.add(_refreshUserPreferences());
            break;
          case 'profile_image':
            refreshTasks.add(_refreshProfileImage());
            break;
          case 'church_messages':
            refreshTasks.add(_refreshChurchMessages());
            break;
          case 'available_churches':
            refreshTasks.add(_refreshAvailableChurches());
            break;
          case 'unread_count':
            refreshTasks.add(_refreshUnreadCount());
            break;
          case 'roundup_settings':
            refreshTasks.add(_refreshRoundupSettings());
            break;
        }
      }

      // Execute refresh tasks in parallel
      await Future.wait(refreshTasks);
      _logger.d('Refreshed ${refreshTasks.length} data types');
    } catch (e) {
      _logger.e('Error refreshing data from server: $e');
    }
  }

  /// Individual refresh methods
  static Future<void> _refreshBankAccounts() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchBankAccounts();
      _logger.d('Bank accounts refreshed');
    } catch (e) {
      _logger.e('Error refreshing bank accounts: $e');
    }
  }

  static Future<void> _refreshPreferences() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchPreferences();
      _logger.d('Preferences refreshed');
    } catch (e) {
      _logger.e('Error refreshing preferences: $e');
    }
  }

  static Future<void> _refreshPaymentMethods() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchPaymentMethods();
      _logger.d('Payment methods refreshed');
    } catch (e) {
      _logger.e('Error refreshing payment methods: $e');
    }
  }

  static Future<void> _refreshDashboard() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchDashboard();
      _logger.d('Dashboard refreshed');
    } catch (e) {
      _logger.e('Error refreshing dashboard: $e');
    }
  }

  static Future<void> _refreshDonationSummary() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.fetchDonationSummary();
      _logger.d('Donation summary refreshed');
    } catch (e) {
      _logger.e('Error refreshing donation summary: $e');
    }
  }

  static Future<void> _refreshTransactions() async {
    try {
      final roundupProvider = RoundupProvider();
      await roundupProvider.smartFetchRoundupTransactions();
      _logger.d('Transactions refreshed');
    } catch (e) {
      _logger.e('Error refreshing transactions: $e');
    }
  }

  static Future<void> _refreshDonationHistory() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchDonationHistory();
      _logger.d('Donation history refreshed');
    } catch (e) {
      _logger.e('Error refreshing donation history: $e');
    }
  }

  static Future<void> _refreshRoundupStatus() async {
    try {
      final roundupProvider = RoundupProvider();
      await roundupProvider.fetchRoundupStatus();
      _logger.d('Roundup status refreshed');
    } catch (e) {
      _logger.e('Error refreshing roundup status: $e');
    }
  }

  static Future<void> _refreshRoundupTransactions() async {
    try {
      final roundupProvider = RoundupProvider();
      await roundupProvider.fetchRoundupTransactions();
      _logger.d('Roundup transactions refreshed');
    } catch (e) {
      _logger.e('Error refreshing roundup transactions: $e');
    }
  }

  static Future<void> _refreshPendingRoundups() async {
    try {
      final roundupProvider = RoundupProvider();
      await roundupProvider.fetchPendingRoundups();
      _logger.d('Pending roundups refreshed');
    } catch (e) {
      _logger.e('Error refreshing pending roundups: $e');
    }
  }

  static Future<void> _refreshUserProfile() async {
    try {
      final authProvider = AuthProvider();
      await authProvider.refreshProfile();
      _logger.d('User profile refreshed');
    } catch (e) {
      _logger.e('Error refreshing user profile: $e');
    }
  }

  static Future<void> _refreshUserPreferences() async {
    try {
      final profileProvider = ProfileProvider();
      await profileProvider.refreshProfileData();
      _logger.d('User preferences refreshed');
    } catch (e) {
      _logger.e('Error refreshing user preferences: $e');
    }
  }

  static Future<void> _refreshProfileImage() async {
    try {
      final authProvider = AuthProvider();
      await authProvider.refreshProfile();
      _logger.d('Profile image refreshed');
    } catch (e) {
      _logger.e('Error refreshing profile image: $e');
    }
  }

  static Future<void> _refreshChurchMessages() async {
    try {
      final churchMessageProvider = ChurchMessageProvider();
      await churchMessageProvider.fetchMessages();
      await churchMessageProvider.fetchUnreadCount();
      _logger.d('Church messages refreshed');
    } catch (e) {
      _logger.e('Error refreshing church messages: $e');
    }
  }

  static Future<void> _refreshAvailableChurches() async {
    try {
      final churchProvider = ChurchProvider();
      await churchProvider.initialize();
      _logger.d('Available churches refreshed');
    } catch (e) {
      _logger.e('Error refreshing available churches: $e');
    }
  }

  static Future<void> _refreshUnreadCount() async {
    try {
      final notificationProvider = NotificationProvider();
      await notificationProvider.fetchNotifications();
      _logger.d('Unread count refreshed');
    } catch (e) {
      _logger.e('Error refreshing unread count: $e');
    }
  }

  static Future<void> _refreshRoundupSettings() async {
    try {
      final roundupProvider = RoundupProvider();
      await roundupProvider.fetchRoundupSettings();
      _logger.d('Roundup settings refreshed');
    } catch (e) {
      _logger.e('Error refreshing roundup settings: $e');
    }
  }

  /// Smart cache invalidation based on request data
  static Future<void> smartInvalidateCache(String endpoint, Map<String, dynamic>? requestData) async {
    try {
      // Determine specific cache types based on request data
      final specificCacheTypes = _getSpecificCacheTypes(endpoint, requestData);
      
      if (specificCacheTypes.isNotEmpty) {
        // Invalidate specific caches
        await _cacheManager.invalidateMultipleCaches(specificCacheTypes);
        _logger.d('Smart invalidated specific caches: $specificCacheTypes');
        
        // Refresh specific data
        await _refreshDataFromServer(specificCacheTypes, endpoint, requestData);
      } else {
        // Fall back to general invalidation
        await invalidateAndRefreshCache(endpoint, requestData: requestData);
      }
    } catch (e) {
      _logger.e('Smart cache invalidation error: $e');
    }
  }

  /// Get specific cache types based on request data
  static List<String> _getSpecificCacheTypes(String endpoint, Map<String, dynamic>? requestData) {
    if (requestData == null) return [];

    final cacheTypes = <String>[];

    // Bank account related
    if (endpoint.contains('bank/accounts') && requestData.containsKey('account_id')) {
      cacheTypes.addAll(['bank_accounts', 'dashboard', 'donation_summary']);
    }

    // Payment method related
    if (endpoint.contains('payment-methods') && requestData.containsKey('payment_method_id')) {
      cacheTypes.addAll(['payment_methods', 'dashboard']);
    }

    // Roundup related
    if (endpoint.contains('roundup') && requestData.containsKey('amount')) {
      cacheTypes.addAll(['roundup_status', 'roundup_transactions', 'pending_roundups', 'donation_summary']);
    }

    // Profile related
    if (endpoint.contains('profile') && (requestData.containsKey('email') || requestData.containsKey('phone'))) {
      cacheTypes.addAll(['user_profile', 'user_preferences']);
    }

    return cacheTypes;
  }
}
