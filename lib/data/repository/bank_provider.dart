import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/bank_service.dart';
import 'package:manna_donate_app/data/apiClient/roundup_service.dart';
import 'package:manna_donate_app/data/models/bank_account.dart';
import 'package:manna_donate_app/data/models/donation_preferences.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/data/models/payment_method.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/error_handler.dart';

import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:manna_donate_app/core/initial_data_fetcher.dart';
import 'package:dio/dio.dart';

class BankProvider extends ChangeNotifier {
  final BankService _bankService = BankService();
  final RoundupService _roundupService = RoundupService();

  final CacheManager _cacheManager = CacheManager();


  List<BankAccount> _accounts = [];
  DonationPreferences? _preferences;
  Map<String, dynamic>? _dashboard;
  List<DonationHistory> _donationHistory = [];
  Map<String, dynamic>? _donationSummary;
  List<Map<String, dynamic>> _transactions = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _loading = false;
  bool _isInitializing = false;
  String? _error;
  DateTime? _lastFetchTime;
  static const Duration _fetchCooldown = Duration(seconds: 2);

  // Getters
  List<BankAccount> get accounts => _accounts;
  DonationPreferences? get preferences => _preferences;
  Map<String, dynamic>? get dashboard => _dashboard;
  List<DonationHistory> get donationHistory => _donationHistory;
  Map<String, dynamic>? get donationSummary => _donationSummary;
  List<Map<String, dynamic>> get transactions => _transactions;

  /// Calculate transaction summary for a specific date range
  Map<String, dynamic> calculateTransactionSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;
    
    // Filter transactions by date range and account
    final filteredTransactions = _transactions.where((transaction) {
      final transactionDate = DateTime.tryParse(transaction['date'] ?? '');
      if (transactionDate == null) return false;
      
      // Check date range
      if (transactionDate.isBefore(start) || transactionDate.isAfter(end)) {
        return false;
      }
      
      // Check account ID if specified
      if (accountId != null && transaction['account_id'] != accountId) {
        return false;
      }
      
      return true;
    }).toList();

    // Calculate totals
    double totalSpent = 0.0;
    double totalReceived = 0.0;
    int transactionCount = filteredTransactions.length;
    
    for (final transaction in filteredTransactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      if (amount < 0) {
        totalSpent += amount.abs();
      } else {
        totalReceived += amount;
      }
    }

    return {
      'totalSpent': totalSpent,
      'totalReceived': totalReceived,
      'transactionCount': transactionCount,
      'netAmount': totalReceived - totalSpent,
      'startDate': start.toIso8601String().split('T')[0],
      'endDate': end.toIso8601String().split('T')[0],
    };
  }

  /// Get this month's transaction summary
  Map<String, dynamic> get thisMonthSummary {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return calculateTransactionSummary(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  /// Get this year's transaction summary
  Map<String, dynamic> get thisYearSummary {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    return calculateTransactionSummary(
      startDate: startOfYear,
      endDate: endOfYear,
    );
  }

  /// Calculate roundup amounts from transactions for verification
  Map<String, dynamic> calculateRoundupFromTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    double multiplier = 1.0,
  }) {
    final now = DateTime.now();
    final start = startDate ?? now.subtract(const Duration(days: 30));
    final end = endDate ?? now;
    
    // Filter transactions by date range and account
    final filteredTransactions = _transactions.where((transaction) {
      final transactionDate = DateTime.tryParse(transaction['date'] ?? '');
      if (transactionDate == null) return false;
      
      // Check date range
      if (transactionDate.isBefore(start) || transactionDate.isAfter(end)) {
        return false;
      }
      
      // Check account ID if specified
      if (accountId != null && transaction['account_id'] != accountId) {
        return false;
      }
      
      return true;
    }).toList();

    // Calculate roundup amounts
    double totalRoundupAmount = 0.0;
    int roundupTransactionCount = 0;
    List<Map<String, dynamic>> roundupDetails = [];
    
    for (final transaction in filteredTransactions) {
      final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
      
      // Only calculate roundups for spending transactions (negative amounts)
      if (amount < 0) {
        final absAmount = amount.abs();
        // Calculate roundup: round up to nearest dollar
        // If amount is $6.33, roundup = $0.67 (to make it $7.00)
        // If amount is $12.00, roundup = $0.00 (already exact dollar)
        // If amount is $4.33, roundup = $0.67 (to make it $5.00)
        final roundupAmount = (1.0 - (absAmount % 1.0)) * multiplier;
        
        // Only add roundup if it's greater than 0 (not already an exact dollar)
        if (roundupAmount > 0 && roundupAmount < 1.0) {
          totalRoundupAmount += roundupAmount;
          roundupTransactionCount++;
          
          roundupDetails.add({
            'transaction_id': transaction['transaction_id'],
            'name': transaction['name'],
            'amount': absAmount,
            'roundup_amount': roundupAmount,
            'date': transaction['date'],
          });
        }
      }
    }

    return {
      'totalRoundupAmount': totalRoundupAmount,
      'roundupTransactionCount': roundupTransactionCount,
      'totalTransactions': filteredTransactions.length,
      'startDate': start.toIso8601String().split('T')[0],
      'endDate': end.toIso8601String().split('T')[0],
      'multiplier': multiplier,
      'roundupDetails': roundupDetails,
    };
  }

  /// Get this month's roundup calculation for verification
  Map<String, dynamic> get thisMonthRoundupCalculation {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return calculateRoundupFromTransactions(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get loading => _loading || _isInitializing;
  String? get error => _error;

  // Helper getters
  bool get hasLinkedAccounts => _accounts.isNotEmpty;
  bool get hasActivePreferences {
    // Show main content if user has created preferences (not null) and they are active
    return _preferences != null && _preferences!.isActive;
  }

  bool get hasUserPreferences {
    // True if preferences exist and were set up by the user (has createdAt timestamp)
    return _preferences != null && _preferences!.createdAt != null;
  }

  bool get hasPreferencesForOnboarding {
    // True if preferences exist at all (for onboarding logic)
    return _preferences != null;
  }

  BankAccount? get defaultAccount =>
      _accounts.isNotEmpty ? _accounts.first : null;

  /// Reset the fetch cooldown to allow immediate fetching
  void resetFetchCooldown() {
    _lastFetchTime = null;
  }

  /// Create Plaid Link Token
  Future<ApiResponse<Map<String, dynamic>>> createLinkToken() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if user is authenticated first
      final userId = await _bankService.apiService.getUserId();

      if (userId == 0) {
        _error = 'User not authenticated. Please log in again.';
        return ApiResponse(success: false, message: _error!);
      }

      final response = await _bankService.createLinkToken();
      if (!response.success) {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to create link token: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Exchange Plaid public token and link bank account
  Future<ApiResponse<Map<String, dynamic>>> linkBankAccount(
    String publicToken,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.exchangePublicToken(publicToken);
      if (response.success) {
        // Invalidate cache since bank accounts changed
        await _cacheManager.invalidateOnDataChange('bank_accounts');
        // Fetch fresh data
        await _fetchBankAccountsFromAPI();
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to link bank account: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Save payment method to Stripe
  Future<ApiResponse<Map<String, dynamic>>> savePaymentMethod(
    String paymentMethodId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.savePaymentMethod(paymentMethodId);
      if (response.success) {
        // Invalidate cache since payment methods changed
        await _cacheManager.invalidateOnDataChange('payment_methods');
        // Also invalidate related caches that might show payment method info
        await _cacheManager.invalidateOnDataChange('bank_accounts');
        // Fetch fresh data
        await _fetchPaymentMethodsFromAPI();
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to save payment method: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch user's linked bank accounts (cache-first)
  Future<void> fetchBankAccounts() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('bank_accounts');
    if (cachedData != null) {
      _accounts = List<BankAccount>.from(cachedData);
      notifyListeners();
      return;
    }

    // If no cache, fetch from API
    await _fetchBankAccountsFromAPI();
  }

  /// Fetch bank accounts from API (used when cache is invalid or data changes)
  Future<void> _fetchBankAccountsFromAPI() async {
    // Check if we should skip this call due to cooldown
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _fetchCooldown) {
      return;
    }

    // Don't set loading if we're already initializing
    if (!_isInitializing) {
      _loading = true;
      notifyListeners();
    }

    _error = null;
    _lastFetchTime = DateTime.now();

    try {
      final response = await _bankService.getBankAccounts();

      if (response.success && response.data != null) {
        _accounts = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('bank_accounts', response.data!);
      } else {
        _error = response.message;
        _accounts = [];
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view bank accounts. Please log in again.';
      } else {
        _error = ErrorHandler.getErrorMessage(e);
      }
      _accounts = [];
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _accounts = [];
    }

    if (!_isInitializing) {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch donation preferences (cache-first)
  Future<void> fetchPreferences() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('preferences');
    if (cachedData != null) {
      _preferences = cachedData;
      notifyListeners();
      return;
    }

    // If no cache, fetch from API
    await _fetchPreferencesFromAPI();
  }

  /// Fetch preferences from API (used when cache is invalid or data changes)
  Future<void> _fetchPreferencesFromAPI() async {
    // Check if we should skip this call due to cooldown
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _fetchCooldown) {
      return;
    }

    // Don't set loading if we're already initializing
    if (!_isInitializing) {
      _loading = true;
      notifyListeners();
    }

    _error = null;
    _lastFetchTime = DateTime.now();

    try {
      final response = await _bankService.getPreferences();

      if (response.success) {
        _preferences = response.data; // Can be null if no preferences exist
        // Cache the fresh data
        await _cacheManager.cacheData('preferences', response.data);
      } else {
        _error = response.message;
        _preferences = null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view preferences. Please log in again.';
      } else {
        _error = ErrorHandler.getErrorMessage(e);
      }
      _preferences = null;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _preferences = null;
    }

    if (!_isInitializing) {
      _loading = false;
      notifyListeners();
    }
  }

  /// Invalidate cache when bank data changes
  Future<void> _invalidateBankCache() async {
    await _cacheManager.invalidateMultipleCaches([
      'bank_accounts',
      'preferences',
      'dashboard',
      'donation_history',
      'payment_methods',
    ]);
  }

  /// Update donation preferences
  Future<ApiResponse<DonationPreferences>> updatePreferences({
    String? frequency,
    String? multiplier,
    int? churchId,
    bool? pause,
    bool? coverProcessingFees,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final preferences = <String, dynamic>{};
      if (frequency != null) preferences['frequency'] = frequency;
      if (multiplier != null) preferences['multiplier'] = multiplier;
      // Always include church_id, even if null, to ensure proper clearing of selection
      // Convert 0 to null for backend consistency
      preferences['church_id'] = churchId == 0 ? null : churchId;
      if (pause != null) preferences['pause'] = pause;
      if (coverProcessingFees != null)
        preferences['cover_processing_fees'] = coverProcessingFees;

      final response = await _bankService.updatePreferences(preferences);
      if (response.success && response.data != null) {
        _preferences = response.data!;
        
        // Invalidate cache after successful update
        await _invalidateBankCache();
        
        // Fetch fresh data from server and update cache
        await Future.wait([
          _fetchDashboardFromAPI(),
          _fetchDonationHistoryFromAPI(),
          _fetchDonationSummaryFromAPI(),
        ]);
        
        // Cache the updated preferences
        await _cacheManager.cacheData('preferences', response.data!.toJson());
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to update preferences: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch comprehensive dashboard data (cache-first)
  Future<void> fetchDashboard() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('dashboard');
    if (cachedData != null) {
      _dashboard = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDashboardFromAPI();
  }

  /// Fetch dashboard from API (used when cache is invalid or data changes)
  Future<void> _fetchDashboardFromAPI() async {
    // Don't set loading if we're already initializing
    if (!_isInitializing) {
      _loading = true;
      notifyListeners();
    }

    _error = null;

    try {
      final response = await _bankService.getDashboard();
      if (response.success && response.data != null) {
        _dashboard = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('dashboard', response.data!);
      } else {
        _error = response.message;
        _dashboard = null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view dashboard. Please log in again.';
      } else {
        _error = ErrorHandler.getErrorMessage(e);
      }
      _dashboard = null;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _dashboard = null;
    }

    if (!_isInitializing) {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch donation history (cache-first)
  Future<void> fetchDonationHistory() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_history');
    if (cachedData != null) {
      _donationHistory = List<DonationHistory>.from(cachedData);
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDonationHistoryFromAPI();
  }

  /// Fetch donation history from API (used when cache is invalid or data changes)
  Future<void> _fetchDonationHistoryFromAPI() async {
    // Don't set loading if we're already initializing
    if (!_isInitializing) {
      _loading = true;
      notifyListeners();
    }

    _error = null;

    try {
      // Use bank service to get donation history from /bank/donation-history endpoint
      final response = await _bankService.getDonationHistory();
      if (response.success && response.data != null) {
        _donationHistory = response.data!;
        
        // Cache the fresh data
        await _cacheManager.cacheData('donation_history', _donationHistory);
        
    

      } else {
        _error = response.message;
        _donationHistory = [];

      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view donation history. Please log in again.';
      } else {
        _error = ErrorHandler.getErrorMessage(e);
      }
      _donationHistory = [];
      
    } catch (e) {
      _error = 'Failed to fetch donation history: $e';
      _donationHistory = [];
      
    }

    if (!_isInitializing) {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch donation summary (cache-first)
  Future<void> fetchDonationSummary() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_summary');
    if (cachedData != null) {
      _donationSummary = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDonationSummaryFromAPI();
  }

  /// Fetch donation summary from API (used when cache is invalid or data changes)
  Future<void> _fetchDonationSummaryFromAPI() async {
    // Don't set loading if we're already initializing
    if (!_isInitializing) {
      _loading = true;
      notifyListeners();
    }

    _error = null;

    try {
      final response = await _bankService.getDonationSummary();
      if (response.success && response.data != null) {
        _donationSummary = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('donation_summary', response.data!);
      } else {
        _error = response.message;
        _donationSummary = null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view donation summary. Please log in again.';
      } else if (e.response?.statusCode == 400) {
        _error =
            'Unable to fetch donation summary. You may not have any donation history yet.';
      } else {
        _error = ErrorHandler.getErrorMessage(e);
      }
      _donationSummary = null;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _donationSummary = null;
    }

    if (!_isInitializing) {
      _loading = false;
      notifyListeners();
    }
  }

  /// Calculate roundups for a date range
  Future<ApiResponse<Map<String, dynamic>>> calculateRoundups({
    required String startDate,
    required String endDate,
    String multiplier = '1x',
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.calculateRoundups(
        startDate: startDate,
        endDate: endDate,
        multiplier: multiplier,
      );
      if (!response.success) {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to calculate roundups: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Execute donation batch
  Future<ApiResponse<Map<String, dynamic>>> executeDonationBatch(
    int batchId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.executeDonationBatch(batchId);
      if (response.success) {
        // Invalidate cache since donation data changed
        await _cacheManager.invalidateOnDataChange('donation_history');
        await _cacheManager.invalidateOnDataChange('donation_summary');
        // Fetch fresh data
        await _fetchDonationHistoryFromAPI();
        await _fetchDonationSummaryFromAPI();
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to execute donation batch: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch transactions for a date range
  Future<ApiResponse<Map<String, dynamic>>> fetchTransactions({
    required String startDate,
    required String endDate,
    List<String>? accountIds,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.getTransactions(
        startDate: startDate,
        endDate: endDate,
        accountIds: accountIds,
      );
      if (response.success && response.data != null) {
        _transactions = response.data!['transactions'] ?? [];
      } else {
        _error = response.message;
        _transactions = [];
      }
      return response;
    } catch (e) {
      _error = 'Failed to fetch transactions: $e';
      _transactions = [];
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // REMOVED: Bank transactions should be handled by RoundupProvider
  // This was causing confusion between bank transactions and roundup transactions

  /// Initialize all data with smart loading (non-blocking)
  Future<void> initialize() async {
    if (_isInitializing) {
      return;
    }

    _isInitializing = true;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Load critical data first (bank accounts and preferences)
      await Future.wait([
        smartFetchBankAccounts(),
        smartFetchPreferences(),
      ]);

      // Load secondary data in background without blocking
      _loadSecondaryDataInBackground();
    } catch (e) {
      _error = 'Failed to initialize: $e';
    } finally {
      _isInitializing = false;
      _loading = false;
      notifyListeners();
    }
  }

  /// Load secondary data in background without blocking UI
  void _loadSecondaryDataInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await Future.wait([
          smartFetchDashboard(),
          smartFetchDonationHistory(),
          smartFetchPaymentMethods(),
          // REMOVED: Transactions are handled by RoundupProvider
        ]);

        // Only fetch donation summary if user has active preferences with church selected
        if (_preferences != null &&
            _preferences!.isActive &&
            _preferences!.churchId != null) {
          await _smartFetchDonationSummary();
        }
      } catch (e) {
        // Handle error silently for background loading
      }
    });
  }

  /// Smart fetch bank accounts with cache
  Future<void> smartFetchBankAccounts() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('bank_accounts');
    if (cachedData != null) {
      try {
        final accounts = (cachedData as List<dynamic>)
            .map((json) => BankAccount.fromJson(json as Map<String, dynamic>))
            .toList();
        _accounts = accounts;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('bank_accounts');
      }
    }

    // If no cache or parsing failed, fetch from API
    await _fetchBankAccountsFromAPI();
  }

  /// Smart fetch preferences with cache
  Future<void> smartFetchPreferences() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('preferences');
    if (cachedData != null) {
      try {
        _preferences = DonationPreferences.fromJson(cachedData as Map<String, dynamic>);
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('preferences');
      }
    }

    // If no cache or parsing failed, fetch from API
    await _fetchPreferencesFromAPI();
  }

  /// Smart fetch dashboard with cache
  Future<void> smartFetchDashboard() async {
    // Try to get cached data first
    final cachedData = await _cacheManager.smartGetCachedData('dashboard');
    if (cachedData != null) {
      try {
        _dashboard = cachedData as Map<String, dynamic>;
        _error = null;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // Handle cache parsing error silently
      }
    }

    // Only fetch from API if no cache or cache is invalid
    await _fetchDashboardFromAPI();
  }

  /// Smart fetch donation history with cache
  Future<void> smartFetchDonationHistory() async {
    // Try to get cached data first
    final cachedData = await _cacheManager.smartGetCachedData('donation_history');
    if (cachedData != null) {
      try {
        final history = (cachedData as List).map((json) => DonationHistory.fromJson(json)).toList();
        _donationHistory = history;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // Handle cache parsing error silently
      }
    }

    // Only fetch from API if no cache or cache is invalid
    await _fetchDonationHistoryFromAPI();
  }

  /// Smart fetch donation summary with cache
  Future<void> _smartFetchDonationSummary() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_summary');
    if (cachedData != null) {
      _donationSummary = cachedData as Map<String, dynamic>?;
      notifyListeners();
    }

    // Fetch fresh data from API
    final response = await _bankService.getDonationSummary();
    if (response.success && response.data != null) {
      _donationSummary = response.data!;
      // Cache the fresh data
      await _cacheManager.cacheData('donation_summary', response.data!);
    } else {
      _error = response.message;
      _donationSummary = null;
    }
    
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _accounts = [];
    _preferences = null;
    _dashboard = null;
    _donationHistory = [];
    _donationSummary = null;
    _transactions = [];
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Backward compatibility methods
  /// Fetch accounts (alias for fetchBankAccounts)
  Future<void> fetchAccounts() async {
    return fetchBankAccounts();
  }

  /// Legacy method for donation schedules (no longer supported)
  Future<void> fetchDonationSchedules() async {
    // Donation schedules are no longer supported in the new roundup-only model
    _error =
        'Donation schedules are no longer supported. Please use roundup donations instead.';
    notifyListeners();
  }

  /// Legacy method for creating donation schedules (no longer supported)
  Future<ApiResponse<Map<String, dynamic>>> createDonationSchedule({
    required double amount,
    required String dayOfWeek,
    required String recipientId,
    String? accessToken,
    String? status,
  }) async {
    return ApiResponse(
      success: false,
      message:
          'Donation schedules are no longer supported. Please use roundup donations instead.',
    );
  }

  /// Legacy method for updating donation schedules (no longer supported)
  Future<ApiResponse<Map<String, dynamic>>> updateDonationSchedule({
    required String scheduleId,
    double? amount,
    String? frequency,
    String? status,
    String? dayOfWeek,
    String? recipientId,
    String? accessToken,
  }) async {
    return ApiResponse(
      success: false,
      message:
          'Donation schedules are no longer supported. Please use roundup donations instead.',
    );
  }

  /// Legacy method for deleting donation schedules (no longer supported)
  Future<ApiResponse<Map<String, dynamic>>> deleteDonationSchedule(
    String scheduleId,
  ) async {
    return ApiResponse(
      success: false,
      message:
          'Donation schedules are no longer supported. Please use roundup donations instead.',
    );
  }

  /// Legacy method for one-time charges (no longer supported)
  Future<ApiResponse<Map<String, dynamic>>> charge({
    required double amount,
    required int churchId,
    required String description,
    String? paymentMethodId,
    String? paymentSource,
  }) async {
    return ApiResponse(
      success: false,
      message:
          'One-time charges are no longer supported. Please use roundup donations instead.',
    );
  }

  /// Set default account (legacy method)
  Future<ApiResponse<Map<String, dynamic>>> setDefaultAccount(
    String accountId,
  ) async {
    // In the new model, this would set the default payment method
    // For now, return success but log that this is deprecated
    return ApiResponse(
      success: true,
      message:
          'Default account setting is deprecated. Please use payment methods instead.',
    );
  }

  /// Activate account (legacy method)
  Future<ApiResponse<Map<String, dynamic>>> activateAccount(
    String accountId,
  ) async {
    // In the new model, accounts are always active if they exist
    return ApiResponse(
      success: true,
      message: 'Account activated successfully.',
    );
  }

  /// Deactivate account (legacy method)
  Future<ApiResponse<Map<String, dynamic>>> deactivateAccount(
    String accountId,
  ) async {
    // In the new model, we don't deactivate accounts
    return ApiResponse(
      success: false,
      message: 'Account deactivation is not supported in the new model.',
    );
  }

  /// Delete account (legacy method)
  Future<ApiResponse<Map<String, dynamic>>> deleteAccount(
    String accountId,
  ) async {
    // In the new model, we don't delete accounts
    return ApiResponse(
      success: false,
      message: 'Account deletion is not supported in the new model.',
    );
  }

  // Legacy getters for backward compatibility
  List<Map<String, dynamic>> get donationSchedules => [];

  /// Fetch payment methods (cache-first)
  Future<void> fetchPaymentMethods() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('payment_methods');
    if (cachedData != null) {
      // Handle both old format (nested) and new format (direct array)
      List paymentMethodsData;
      if (cachedData is Map<String, dynamic> && cachedData.containsKey('payment_methods')) {
        // Old format: {payment_methods: [...]}
        paymentMethodsData = cachedData['payment_methods'] as List? ?? [];
      } else {
        // New format: direct array
        paymentMethodsData = cachedData as List? ?? [];
      }
      
      _paymentMethods = paymentMethodsData.map((json) {
        if (json is Map<String, dynamic>) {
          return PaymentMethod.fromJson(json);
        } else if (json is Map) {
          return PaymentMethod.fromJson(Map<String, dynamic>.from(json));
        } else {
          return PaymentMethod(
            id: 'unknown',
            type: 'unknown',
            isDefault: false,
            createdAt: DateTime.now(),
          );
        }
      }).toList();
      notifyListeners();
      return;
    }

    // If no cache, fetch from API
    await _fetchPaymentMethodsFromAPI();
  }

  /// Smart fetch payment methods (cache-first with validation)
  Future<void> smartFetchPaymentMethods() async {
    try {
      // Check if cache is valid
      final isCacheValid = await _cacheManager.isCacheValid('payment_methods');
      
      if (isCacheValid) {
        // Load from cache if valid
        final cachedData = await _cacheManager.getCachedData('payment_methods');
        if (cachedData != null) {
          // Handle both old format (nested) and new format (direct array)
          List paymentMethodsData;
          if (cachedData is Map<String, dynamic> && cachedData.containsKey('payment_methods')) {
            // Old format: {payment_methods: [...]}
            paymentMethodsData = cachedData['payment_methods'] as List? ?? [];
          } else {
            // New format: direct array
            paymentMethodsData = cachedData as List? ?? [];
          }
          
          _paymentMethods = paymentMethodsData.map((json) {
            if (json is Map<String, dynamic>) {
              return PaymentMethod.fromJson(json);
            } else if (json is Map) {
              return PaymentMethod.fromJson(Map<String, dynamic>.from(json));
            } else {
              return PaymentMethod(
                id: 'unknown',
                type: 'unknown',
                isDefault: false,
                createdAt: DateTime.now(),
              );
            }
          }).toList();
          notifyListeners();
          return;
        }
      }

      // Fetch from API if cache is invalid or empty
      await _fetchPaymentMethodsFromAPI();
    } catch (e) {
      // Fallback to API fetch
      await _fetchPaymentMethodsFromAPI();
    }
  }

  /// Fetch payment methods from API (used when cache is invalid or data changes)
  Future<void> _fetchPaymentMethodsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.getPaymentMethods();

      if (response.success && response.data != null) {
        final paymentMethodsData =
            response.data!['payment_methods'] as List? ?? [];
        _paymentMethods = paymentMethodsData.map((json) {
          if (json is Map<String, dynamic>) {
            return PaymentMethod.fromJson(json);
          } else if (json is Map) {
            return PaymentMethod.fromJson(Map<String, dynamic>.from(json));
          } else {
            return PaymentMethod(
              id: 'unknown',
              type: 'unknown',
              isDefault: false,
              createdAt: DateTime.now(),
            );
          }
        }).toList();
        // Cache the fresh data - store only the payment_methods array
        await _cacheManager.cacheData('payment_methods', paymentMethodsData);
      } else {
        _error = response.message;
        _paymentMethods = [];
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _paymentMethods = [];
    } catch (e) {
      _error = 'Failed to fetch payment methods: $e';
      _paymentMethods = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Set default payment method
  Future<ApiResponse<Map<String, dynamic>>> setDefaultPaymentMethod(
    String paymentMethodId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.setDefaultPaymentMethod(paymentMethodId);

      if (response.success) {
        // Invalidate cache since payment methods changed
        await _cacheManager.invalidateOnDataChange('payment_methods');
        // Fetch fresh data
        await _fetchPaymentMethodsFromAPI();
      } else {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = 'Failed to set default payment method: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Delete payment method
  Future<ApiResponse<Map<String, dynamic>>> deletePaymentMethod(
    String paymentMethodId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _bankService.deletePaymentMethod(paymentMethodId);

      if (response.success) {
        // Invalidate cache since payment methods changed
        await _cacheManager.invalidateOnDataChange('payment_methods');
        // Fetch fresh data
        await _fetchPaymentMethodsFromAPI();
      } else {
        _error = response.message;
      }

      return response;
    } catch (e) {
      _error = 'Failed to delete payment method: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Refresh methods for pull-to-refresh (bypass cache)
  Future<void> refreshBankAccounts() async {
    await _fetchBankAccountsFromAPI();
  }

  Future<void> refreshPaymentMethods() async {
    await _fetchPaymentMethodsFromAPI();
  }

  Future<void> refreshPreferences() async {
    await _fetchPreferencesFromAPI();
  }

  Future<void> refreshDashboard() async {
    await _fetchDashboardFromAPI();
  }

  Future<void> refreshDonationHistory() async {
    await _fetchDonationHistoryFromAPI();
  }

  Future<void> refreshDonationSummary() async {
    await _fetchDonationSummaryFromAPI();
  }

  // REMOVED: Bank transactions should be handled by RoundupProvider
  // This was causing confusion between bank transactions and roundup transactions

  /// Smart fetch bank accounts with cache and loading state
  Future<void> smartFetchBankAccountsWithLoading() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('bank_accounts');
    if (cachedData != null) {
      try {
        final accounts = (cachedData as List<dynamic>)
            .map((json) => BankAccount.fromJson(json as Map<String, dynamic>))
            .toList();
        _accounts = accounts;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('bank_accounts');
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchBankAccountsFromAPI();
  }

  /// Smart fetch preferences with cache and loading state
  Future<void> smartFetchPreferencesWithLoading() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('preferences');
    if (cachedData != null) {
      try {
        _preferences = DonationPreferences.fromJson(cachedData as Map<String, dynamic>);
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('preferences');
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchPreferencesFromAPI();
  }

  /// Smart fetch dashboard with cache and loading state
  Future<void> smartFetchDashboardWithLoading() async {
    // Try to get cached data first
    final cachedData = await _cacheManager.smartGetCachedData('dashboard');
    if (cachedData != null) {
      try {
        _dashboard = cachedData as Map<String, dynamic>;
        _error = null;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // Handle cache parsing error silently
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchDashboardFromAPI();
  }

  /// Smart fetch donation history with cache and loading state
  Future<void> smartFetchDonationHistoryWithLoading() async {
    // Try to get cached data first
    final cachedData = await _cacheManager.smartGetCachedData('donation_history');
    if (cachedData != null) {
      try {
        final history = (cachedData as List).map((json) => DonationHistory.fromJson(json)).toList();
        _donationHistory = history;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // Handle cache parsing error silently
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchDonationHistoryFromAPI();
  }

  // REMOVED: Bank transactions should be handled by RoundupProvider
  // This was causing confusion between bank transactions and roundup transactions

  /// Smart fetch payment methods with cache and loading state
  Future<void> smartFetchPaymentMethodsWithLoading() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('payment_methods');
    if (cachedData != null) {
      try {
        final methods = (cachedData as List<dynamic>)
            .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
            .toList();
        _paymentMethods = methods;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('payment_methods');
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchPaymentMethodsFromAPI();
  }
}
