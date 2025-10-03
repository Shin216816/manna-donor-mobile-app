import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/repository/bank_provider.dart';
import 'package:manna_donate_app/core/cache_manager.dart';

class BackgroundDataFetcher {
  static final Logger _logger = Logger();
  static final CacheManager _cacheManager = CacheManager();

  /// Fetch essential data for navigation decision only
  
  static Future<void> fetchEssentialDataForNavigation() async {
    try {
      _logger.i('Fetching essential data for navigation decision...');
      
      // Note: This method should be called with context to access existing providers
      // For now, we'll just log and return to prevent hanging
      _logger.i('Essential data fetch skipped - use context-based method instead');
      
    } catch (e) {
      _logger.e('Essential data fetch error: $e');
    }
  }

  /// Fetch essential data with context (use this instead)
  static Future<void> fetchEssentialDataForNavigationWithContext(BuildContext context) async {
    try {
      _logger.i('Fetching essential data for navigation decision with context...');
      
      final bankProvider = Provider.of<BankProvider>(context, listen: false);
      
      // Only fetch data needed to determine if user has completed setup
      await Future.wait([
        bankProvider.smartFetchBankAccounts(),
        bankProvider.smartFetchPreferences(),
        bankProvider.smartFetchPaymentMethods(),
      ], eagerError: false);
      
      _logger.i('Essential data for navigation fetched with context');
    } catch (e) {
      _logger.e('Essential data fetch error: $e');
    }
  }

  /// Fetch bank accounts for navigation decision only
  static Future<void> _fetchBankAccountsForNavigation() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchBankAccounts();
      _logger.d('Bank accounts for navigation fetched');
    } catch (e) {
      _logger.e('Bank accounts for navigation fetch error: $e');
    }
  }

  /// Fetch preferences for navigation decision only
  static Future<void> _fetchPreferencesForNavigation() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchPreferences();
      _logger.d('Preferences for navigation fetched');
    } catch (e) {
      _logger.e('Preferences for navigation fetch error: $e');
    }
  }

  /// Fetch payment methods for navigation decision only
  static Future<void> _fetchPaymentMethodsForNavigation() async {
    try {
      final bankProvider = BankProvider();
      await bankProvider.smartFetchPaymentMethods();
      _logger.d('Payment methods for navigation fetched');
    } catch (e) {
      _logger.e('Payment methods for navigation fetch error: $e');
    }
  }

  /// Invalidate all caches when user logs out
  static Future<void> invalidateAllCaches() async {
    try {
      await _cacheManager.clearAllCaches();
      _logger.i('All caches invalidated');
    } catch (e) {
      _logger.e('Cache invalidation error: $e');
    }
  }

  /// Check if essential data for navigation is loaded
  static Future<bool> isEssentialDataLoaded() async {
    try {
      final bankProvider = BankProvider();
      final hasBankAccounts = bankProvider.hasLinkedAccounts;
      final hasPreferences = bankProvider.hasUserPreferences;
      final hasPaymentMethods = bankProvider.paymentMethods.isNotEmpty;
      
      return hasBankAccounts || hasPreferences || hasPaymentMethods;
    } catch (e) {
      _logger.e('Essential data check error: $e');
      return false;
    }
  }
}
