import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/roundup_service.dart';
import 'package:manna_donate_app/data/apiClient/donation_service.dart';
import 'package:manna_donate_app/data/apiClient/bank_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/roundup_status.dart';
import 'package:manna_donate_app/data/models/donation_item.dart';
import 'package:manna_donate_app/data/models/donation_history.dart';
import 'package:manna_donate_app/core/error_handler.dart';
import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:dio/dio.dart';

class RoundupProvider extends ChangeNotifier {
  final RoundupService _roundupService = RoundupService();
  final DonationService _donationService = DonationService();
  final CacheManager _cacheManager = CacheManager();

  Map<String, dynamic>? _roundupStatus;
  Map<String, dynamic>? _roundupSettings;
  RoundupStatus? _enhancedRoundupStatus;
  List<Map<String, dynamic>> _pendingRoundups = [];
  List<Map<String, dynamic>> _roundupTransactions = [];
  List<DonationHistory> _donationHistory = [];
  bool _loading = false;
  String? _error;
  bool _donationHistoryFetched = false;

  // Getters
  Map<String, dynamic>? get roundupStatus => _roundupStatus;
  Map<String, dynamic>? get roundupSettings => _roundupSettings;
  RoundupStatus? get enhancedRoundupStatus => _enhancedRoundupStatus;
  List<Map<String, dynamic>> get pendingRoundups => _pendingRoundups;
  List<Map<String, dynamic>> get roundupTransactions => _roundupTransactions;
  List<DonationHistory> get donationHistory => _donationHistory;
  bool get loading => _loading;
  String? get error => _error;
  bool get donationHistoryFetched => _donationHistoryFetched;

  // Computed properties
  double get pendingAmount {
    if (_roundupStatus == null) return 0.0;
    return (_roundupStatus!['pending_amount'] ?? 0.0).toDouble();
  }

  // Enhanced computed properties
  double get accumulatedRoundups {
    // Calculate ONLY this month's roundups from cache-stored transactions
    if (_roundupTransactions.isNotEmpty) {
      final thisMonth = DateTime.now().month;
      final thisYear = DateTime.now().year;
      
      final thisMonthRoundups = _roundupTransactions.fold<double>(
        0.0, 
        (sum, transaction) {
          // Check if transaction is from this month
          final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                                 DateTime.tryParse(transaction['date'] ?? '') ?? 
                                 DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                                 DateTime.now();
          
          if (transactionDate.month == thisMonth && transactionDate.year == thisYear) {
            final status = transaction['status'] ?? '';
            // Only count transactions that haven't been transferred yet
            if (status != 'transferred' && status != 'completed') {
              return sum + (transaction['roundup_amount'] ?? 0.0);
            }
          }
          return sum;
        }
      );
      
      return thisMonthRoundups;
    }
    
    // If no cached transactions, return 0.0
    return 0.0;
  }

  /// Get all-time accumulated roundups (including transferred ones)
  double get allTimeAccumulatedRoundups {
    // Calculate all-time roundups from cache-stored transactions
    if (_roundupTransactions.isNotEmpty) {
      final allTimeRoundups = _roundupTransactions.fold<double>(
        0.0, 
        (sum, transaction) {
          return sum + (transaction['roundup_amount'] ?? 0.0);
        }
      );
      
      return allTimeRoundups;
    }
    
    // If no cached transactions, return 0.0
    return 0.0;
  }

  DateTime? get nextTransferDate {
    if (_enhancedRoundupStatus != null) {
      return _enhancedRoundupStatus!.nextTransferDate;
    }
    return null;
  }

  double get estimatedNextTransfer {
    if (_enhancedRoundupStatus != null) {
      return _enhancedRoundupStatus!.estimatedNextTransfer;
    }
    return 0.0;
  }

  String get transferFrequency {
    if (_enhancedRoundupStatus != null) {
      return _enhancedRoundupStatus!.transferFrequencyDisplay;
    }
    return frequency; // Fallback to old data
  }

  bool get isTransferReady {
    // Use ONLY the cached transaction calculation for consistency
    return accumulatedRoundups >= 1.0;
  }

  String get nextTransferDateString {
    if (_roundupStatus == null) return 'Monthly';
    return _roundupStatus!['next_transfer_date'] ?? 'Monthly';
  }

  bool get isActive {
    if (_roundupSettings == null) return false;
    return _roundupSettings!['roundup_enabled'] ?? false;
  }

  String get multiplier {
    if (_roundupSettings == null) return '1X';
    return _roundupSettings!['multiplier'] ?? '1X';
  }

  String get frequency {
    if (_roundupSettings == null) return 'Monthly';
    return _roundupSettings!['frequency'] ?? 'Monthly';
  }

  // Additional computed properties for home screen
  Map<String, dynamic>? get thisMonthRoundup {
    if (_enhancedRoundupStatus != null) {
      // Use enhanced roundup status if available (most accurate)
      final result = {
        'totalAmount': _enhancedRoundupStatus!.thisMonthRoundups,
        'totalTransactions': _enhancedRoundupStatus!.totalTransactions,
      };
      return result;
    }
    
    // Try to calculate from roundup transactions as fallback
    if (_roundupTransactions.isNotEmpty) {
      final thisMonth = DateTime.now().month;
      final thisYear = DateTime.now().year;
      
      final thisMonthTransactions = _roundupTransactions.where((transaction) {
        // Try different date fields that might be used
        final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                               DateTime.tryParse(transaction['date'] ?? '') ?? 
                               DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                               DateTime.now();
        return transactionDate.month == thisMonth && transactionDate.year == thisYear;
      }).toList();
      
      final totalAmount = thisMonthTransactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + (transaction['roundup_amount'] ?? 0.0)
      );
      
      final result = {
        'totalAmount': totalAmount,
        'totalTransactions': thisMonthTransactions.length,
      };
      return result;
    }
    
    return null;
  }



  // Last month computed properties
  Map<String, dynamic>? get lastMonthRoundup {
    if (_roundupTransactions.isNotEmpty) {
      final now = DateTime.now();
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
      
      final lastMonthTransactions = _roundupTransactions.where((transaction) {
        final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                               DateTime.tryParse(transaction['date'] ?? '') ?? 
                               DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                               DateTime.now();
        return transactionDate.month == lastMonth && transactionDate.year == lastMonthYear;
      }).toList();
      
      final totalAmount = lastMonthTransactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + (transaction['roundup_amount'] ?? 0.0)
      );
      
      final result = {
        'totalAmount': totalAmount,
        'totalTransactions': lastMonthTransactions.length,
      };
      return result;
    }
    
    return null;
  }

  double get lastMonthRoundupTotal {
    final lastMonthData = lastMonthRoundup;
    return lastMonthData?['totalAmount'] ?? 0.0;
  }

  int get lastMonthTransactionCount {
    final lastMonthData = lastMonthRoundup;
    return lastMonthData?['totalTransactions'] ?? 0;
  }

  // Last month total donations (including regular donations, not just roundups)
  double get lastMonthDonationTotal {
    if (_donationHistory.isNotEmpty) {
      final now = DateTime.now();
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
      
      final lastMonthDonations = _donationHistory.where((donation) {
        final donationDate = donation.date;
        return donationDate.month == lastMonth && donationDate.year == lastMonthYear;
      }).toList();
      
      return lastMonthDonations.fold<double>(
        0.0, 
        (sum, donation) => sum + donation.amount
      );
    }
    
    return 0.0;
  }

  // Get the date of the last donation
  DateTime? get lastDonationDate {
    if (_donationHistory.isNotEmpty) {
      // Sort by date (newest first) and get the most recent donation
      final sortedDonations = List<DonationHistory>.from(_donationHistory);
      sortedDonations.sort((a, b) => b.date.compareTo(a.date));
      
      return sortedDonations.first.date;
    }
    
    return null;
  }

  /// Get total amount transferred to date
  double get totalTransferredAmount {
    // Always calculate from cached roundup transactions (most accurate)
    if (_roundupTransactions.isNotEmpty) {
      return _roundupTransactions.fold<double>(
        0.0,
        (sum, transaction) {
          final status = transaction['status'] ?? '';
          if (status == 'transferred' || status == 'completed') {
            return sum + (transaction['roundup_amount'] ?? 0.0);
          }
          return sum;
        }
      );
    }
    
    // Fallback to backend API value if no local transactions
    if (_enhancedRoundupStatus != null && _enhancedRoundupStatus!.metadata != null) {
      return (_enhancedRoundupStatus!.metadata!['total_transferred_amount'] ?? 0.0).toDouble();
    }
    
    return 0.0;
  }

  /// Get total roundupable amount (amount that can be rounded up)
  double get totalRoundupableAmount {
    // Always calculate from cached roundup transactions (most accurate)
    if (_roundupTransactions.isNotEmpty) {
      return _roundupTransactions.fold<double>(
        0.0,
        (sum, transaction) {
          final amount = (transaction['amount'] ?? 0.0).toDouble();
          // Only include positive amounts (purchases, not withdrawals)
          return sum + (amount > 0 ? amount : 0.0);
        }
      );
    }
    
    // Fallback to backend API value if no local transactions
    if (_enhancedRoundupStatus != null && _enhancedRoundupStatus!.metadata != null) {
      return (_enhancedRoundupStatus!.metadata!['total_roundupable_amount'] ?? 0.0).toDouble();
    }
    
    return 0.0;
  }

  // Calculate this month's roundup total from transactions (same as transactions screen)
  double get thisMonthRoundupTotal {
    if (_roundupTransactions.isEmpty) return 0.0;
    
    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    
    final thisMonthTransactions = _roundupTransactions.where((transaction) {
      // Try different date fields that might be used
      final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                             DateTime.tryParse(transaction['date'] ?? '') ?? 
                             DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                             DateTime.now();
      return transactionDate.month == thisMonth && transactionDate.year == thisYear;
    }).toList();
    
    return thisMonthTransactions.fold<double>(
      0.0, 
      (sum, transaction) => sum + (transaction['roundup_amount'] ?? 0.0)
    );
  }

  /// Calculate pending amount: roundups from registration date - total donated amount
  double getPendingAmount(DateTime? userRegistrationDate) {
    if (userRegistrationDate == null) return 0.0;
    
    // Sum roundup transactions from user registration date
    double totalRoundupsFromRegistration = 0.0;
    if (_roundupTransactions.isNotEmpty) {
      totalRoundupsFromRegistration = _roundupTransactions.fold<double>(
        0.0,
        (sum, transaction) {
          final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                                 DateTime.tryParse(transaction['date'] ?? '') ?? 
                                 DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                                 DateTime.now();
          
          // Only include transactions from registration date onwards
          if (transactionDate.isAfter(userRegistrationDate.subtract(const Duration(days: 1)))) {
            return sum + (transaction['roundup_amount'] ?? 0.0);
          }
          return sum;
        }
      );
    }
    
    // Sum all donated amounts
    double totalDonatedAmount = 0.0;
    if (_donationHistory.isNotEmpty) {
      totalDonatedAmount = _donationHistory.fold<double>(
        0.0,
        (sum, donation) => sum + donation.amount
      );
    }
    
    // Pending amount = roundups from registration - total donated
    return totalRoundupsFromRegistration - totalDonatedAmount;
  }

  /// Get this month's roundup total including pending amount
  double getThisMonthRoundupTotalWithPending(DateTime? userRegistrationDate) {
    return thisMonthRoundupTotal + getPendingAmount(userRegistrationDate);
  }

  // Get this month's transaction count
  int get thisMonthTransactionCount {
    if (_roundupTransactions.isEmpty) return 0;
    
    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    
    final thisMonthTransactions = _roundupTransactions.where((transaction) {
      // Try different date fields that might be used
      final transactionDate = DateTime.tryParse(transaction['created_at'] ?? '') ?? 
                             DateTime.tryParse(transaction['date'] ?? '') ?? 
                             DateTime.tryParse(transaction['transaction_date'] ?? '') ?? 
                             DateTime.now();
      return transactionDate.month == thisMonth && transactionDate.year == thisYear;
    }).toList();
    
    return thisMonthTransactions.length;
  }

  List<DonationItem> get recentDonations {
    if (_donationHistory.isEmpty) return [];

    // Convert donation history to donation items
    return _donationHistory.take(5).map((donation) {
      return DonationItem(
        id: donation.id.toString(),
        amount: donation.amount,
        date: donation.date,
        churchName: donation.churchName ?? 'Unknown Church',
        category: 'Donation',
      );
    }).toList();
  }

  /// Fetch donation history for recent donations (cache-first)
  Future<void> fetchDonationHistory() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('donation_history');
    if (cachedData != null) {
      _donationHistory = List<DonationHistory>.from(cachedData);
      _donationHistoryFetched = true;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchDonationHistoryFromAPI();
  }

  /// Smart fetch donation history (cache-first with validation)
  Future<void> smartFetchDonationHistory() async {
    try {
      // Check if cache is valid
      final isCacheValid = await _cacheManager.isCacheValid('donation_history');
      
      if (isCacheValid) {
        // Load from cache if valid
        final cachedData = await _cacheManager.getCachedData('donation_history');
        if (cachedData != null) {
          _donationHistory = List<DonationHistory>.from(cachedData);
          _donationHistoryFetched = true;
          notifyListeners();
          return;
        }
      }

      // Fetch from API if cache is invalid or empty
      await _fetchDonationHistoryFromAPI();
    } catch (e) {
      // Fallback to API fetch
      await _fetchDonationHistoryFromAPI();
    }
  }

  /// Fetch donation history from API (used when cache is invalid or data changes)
  Future<void> _fetchDonationHistoryFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {

      
      // Use bank service to get donation history from /bank/donation-history endpoint
      final bankService = BankService();
      final response = await bankService.getDonationHistory();
      
      if (response.success && response.data != null) {
        _donationHistory = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('donation_history', response.data!);
        

      } else {
        _error = response.message ?? 'Failed to fetch donation history';
        _donationHistory = [];

      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _donationHistory = [];
      
    } catch (e) {
      _error = 'An unexpected error occurred';
      _donationHistory = [];
      
    }

    _loading = false;
    _donationHistoryFetched = true;
    notifyListeners();
  }

  /// Reset donation history fetched flag (useful for refreshing data)
  void resetDonationHistoryFetched() {
    _donationHistoryFetched = false;
    notifyListeners();
  }

  Map<String, dynamic>? get impact {
    if (_roundupStatus == null) return null;
    return {
      'meals': _roundupStatus!['impact']?['meals'] ?? 0,
      'education': _roundupStatus!['impact']?['education'] ?? 0,
      'healthcare': _roundupStatus!['impact']?['healthcare'] ?? 0,
    };
  }

  /// Fetch enhanced roundup status with accumulated roundups and transfer dates (cache-first)
  Future<void> fetchEnhancedRoundupStatus() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('enhanced_roundup_status');
    if (cachedData != null) {
      try {
        _enhancedRoundupStatus = RoundupStatus.fromJson(cachedData);
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // Handle cache parsing error silently
      }
    }

    // If no cache, fetch from API
    await _fetchEnhancedRoundupStatusFromAPI();
  }

  /// Smart fetch enhanced roundup status (cache-first with validation)
  Future<void> smartFetchEnhancedRoundupStatus() async {
    try {
      // Check if cache is valid
      final isCacheValid = await _cacheManager.isCacheValid('enhanced_roundup_status');
      
      if (isCacheValid) {
        // Load from cache if valid
        final cachedData = await _cacheManager.getCachedData('enhanced_roundup_status');
        if (cachedData != null) {
          _enhancedRoundupStatus = RoundupStatus.fromJson(cachedData);
          notifyListeners();
          return;
        }
      }

      // Fetch from API if cache is invalid or empty
      await _fetchEnhancedRoundupStatusFromAPI();
    } catch (e) {
      // Fallback to API fetch
      await _fetchEnhancedRoundupStatusFromAPI();
    }
  }

  /// Fetch roundup status
  Future<void> fetchRoundupStatus() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getRoundupStatus();
      if (response.success && response.data != null) {
        _roundupStatus = response.data!;
      } else {
        _error = response.message;
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } catch (e) {
      _error = 'An unexpected error occurred';
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch roundup settings
  Future<void> fetchRoundupSettings() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getRoundupSettings();
      if (response.success && response.data != null) {
        _roundupSettings = response.data!;
      } else {
        _error = response.message;
      }
    } on DioException catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
    } catch (e) {
      _error = 'An unexpected error occurred';
    }

    _loading = false;
    notifyListeners();
  }

  /// Smart fetch roundup settings (cache-first)
  Future<void> smartFetchRoundupSettings() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('roundup_settings');
    if (cachedData != null) {
      try {
        _roundupSettings = cachedData as Map<String, dynamic>;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('roundup_settings');
      }
    }

    // If no cache or parsing failed, fetch from API
    await _fetchRoundupSettingsFromAPI();
  }

  /// Update roundup settings
  Future<ApiResponse<Map<String, dynamic>>> updateRoundupSettings({
    required bool isActive,
    required String multiplier,
    required String frequency,
    List<int>? churchIds,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.updateRoundupSettings(
        isActive: isActive,
        multiplier: multiplier,
        frequency: frequency,
        churchIds: churchIds,
      );

      if (response.success) {
        await fetchRoundupSettings();
        await fetchEnhancedRoundupStatus();
      } else {
        _error = response.message;
      }

      _loading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = 'Failed to update roundup settings: $e';
      _loading = false;
      notifyListeners();
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Fetch pending roundups
  Future<void> fetchPendingRoundups() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getPendingRoundups();
      if (response.success && response.data != null) {
        _pendingRoundups = List<Map<String, dynamic>>.from(response.data!);
      } else {
        _error = response.message;
        _pendingRoundups = [];
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch pending roundups: ${e.message}';
      _pendingRoundups = [];
    } catch (e) {
      _error = 'An unexpected error occurred';
      _pendingRoundups = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Smart fetch pending roundups (cache-first)
  Future<void> smartFetchPendingRoundups() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('pending_roundups');
    if (cachedData != null) {
      try {
        _pendingRoundups = List<Map<String, dynamic>>.from(cachedData);
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('pending_roundups');
      }
    }

    // If no cache or parsing failed, fetch from API
    await _fetchPendingRoundupsFromAPI();
  }

  /// Fetch pending roundups from API (used when cache is invalid or data changes)
  Future<void> _fetchPendingRoundupsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getPendingRoundups();
      if (response.success && response.data != null) {
        _pendingRoundups = List<Map<String, dynamic>>.from(response.data!);
        // Cache the fresh data
        await _cacheManager.cacheData('pending_roundups', response.data!);
      } else {
        _error = response.message;
        _pendingRoundups = [];
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch pending roundups: ${e.message}';
      _pendingRoundups = [];
    } catch (e) {
      _error = 'An unexpected error occurred';
      _pendingRoundups = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Fetch roundup transactions (cache-first)
  Future<void> fetchRoundupTransactions() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('roundup_transactions');
    if (cachedData != null) {
      _roundupTransactions = List<Map<String, dynamic>>.from(cachedData);
      notifyListeners();
      return;
    }

    // If no cache, fetch from API
    await _fetchRoundupTransactionsFromAPI();
  }

  /// Fetch this month's roundup transactions specifically
  Future<void> fetchThisMonthRoundupTransactions() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('this_month_roundup_transactions');
    if (cachedData != null) {
      _roundupTransactions = List<Map<String, dynamic>>.from(cachedData);
      notifyListeners();
      return;
    }

    // If no cache, fetch from API
    await _fetchThisMonthRoundupTransactionsFromAPI();
  }

  /// Fetch roundup transactions from API (used when cache is invalid or data changes)
  /// Fetch roundup transactions from the bank service
  Future<void> _fetchRoundupTransactionsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {

      
      // Use the bank service to get transactions
      final bankService = BankService();
      
      // Get transactions for the last 90 days
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 90)).toIso8601String().split('T')[0];
      final endDate = now.toIso8601String().split('T')[0];
      
      final response = await bankService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (response.success && response.data != null) {
        final transactionsData = response.data!;
        final transactionsList = transactionsData['transactions'] as List? ?? [];
        
        // Convert to the expected format for roundup transactions
        _roundupTransactions = transactionsList.map((transaction) {
          final Map<String, dynamic> txn = Map<String, dynamic>.from(transaction);
          final amount = (txn['amount'] ?? 0.0).toDouble();
          final roundupAmount = _calculateRoundupAmount(amount);
          
          return {
            'id': txn['id'],
            'name': txn['name'] ?? 'Transaction',
            'amount': amount,
            'date': txn['date'],
            'roundup_amount': roundupAmount,
            'status': 'pending',
            'type': txn['type'] ?? 'purchase',
          };
        }).where((transaction) {
          // Only include transactions with positive amounts and roundup amounts
          final amount = transaction['amount'] as double;
          final roundupAmount = transaction['roundup_amount'] as double;
          return amount > 0 && roundupAmount > 0;
        }).toList();
        
        // Cache the roundup transactions
        await _cacheManager.cacheData('roundup_transactions', _roundupTransactions);
        

      } else {
        _error = response.message ?? 'Failed to fetch transactions';
        _roundupTransactions = [];

      }
    } on DioException catch (e) {
      _error = 'Failed to fetch transactions: ${e.message}';
      _roundupTransactions = [];
      
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _roundupTransactions = [];
      
    } finally {
      // Ensure loading state is always cleared
      _loading = false;
      notifyListeners();
    }
  }

  /// Calculate roundup amount for a transaction
  double _calculateRoundupAmount(double amount) {
    // Only calculate roundups for positive amounts (purchases)
    if (amount <= 0) return 0.0;
    
    // Round up to the next dollar
    final roundedUp = amount.ceil();
    return roundedUp - amount;
  }

  /// Fetch this month's roundup transactions from API
  Future<void> _fetchThisMonthRoundupTransactionsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Invalidate the cache first to ensure fresh data
      await _cacheManager.invalidateCache('this_month_roundup_transactions');
      
      // Get raw transactions for this month from the bank service
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final startDate = startOfMonth.toIso8601String().split('T')[0];
      final endDate = endOfMonth.toIso8601String().split('T')[0];
      
      // Create BankService instance to get raw transactions
      final bankService = BankService();
      
      // First get bank accounts to get account IDs
      final bankAccountsResponse = await bankService.getBankAccounts();
      if (bankAccountsResponse.success && bankAccountsResponse.data != null) {
        final bankAccounts = bankAccountsResponse.data!;
        final accountIds = bankAccounts
            .where((account) => account.isLinked)
            .map((account) => account.accountId)
            .toList();
        
        if (accountIds.isNotEmpty) {
          final response = await bankService.getTransactions(
            startDate: startDate,
            endDate: endDate,
            accountIds: accountIds,
          );
          
          if (response.success && response.data != null) {
            final rawTransactions = response.data!['transactions'] as List? ?? [];
            
            // Calculate roundup amounts from raw transactions
            _roundupTransactions = _calculateRoundupsFromRawTransactions(rawTransactions);
            
            // Cache the calculated roundup transactions
            await _cacheManager.cacheData('this_month_roundup_transactions', _roundupTransactions);
            
            // Also update the general roundup transactions cache
            await _cacheManager.cacheData('roundup_transactions', _roundupTransactions);
          } else {
            _error = response.message;
            _roundupTransactions = [];
          }
        } else {
          _error = 'No linked bank accounts found';
          _roundupTransactions = [];
        }
      } else {
        _error = 'Failed to fetch bank accounts';
        _roundupTransactions = [];
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch this month\'s roundup transactions: ${e.message}';
      _roundupTransactions = [];
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      _roundupTransactions = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Refresh all roundup data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchRoundupStatus(),
      fetchEnhancedRoundupStatus(),
      fetchRoundupSettings(),
      fetchPendingRoundups(),
      fetchRoundupTransactions(),
    ]);
  }

  /// Smart fetch roundup transactions (cache-first)
  Future<void> smartFetchRoundupTransactions() async {
    try {
      // Try to load from cache first
      final cachedData = await _cacheManager.smartGetCachedData('roundup_transactions');
  
      
      if (cachedData != null) {
        try {
          _roundupTransactions = List<Map<String, dynamic>>.from(cachedData);
          notifyListeners();
          return; // Return early if we have cached data
        } catch (e) {
          // If parsing fails, invalidate cache and fetch fresh data
          await _cacheManager.invalidateCache('roundup_transactions');
        }
      }

      // If no cache or parsing failed, fetch from API
      await _fetchRoundupTransactionsFromAPI();
    } catch (e) {
      // Ensure we have an empty list if everything fails
      _roundupTransactions = [];
      notifyListeners();
    }
  }

  /// Smart fetch roundup transactions with cache and loading state
  Future<void> smartFetchRoundupTransactionsWithLoading() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('roundup_transactions');
    
    if (cachedData != null) {
      try {
        _roundupTransactions = List<Map<String, dynamic>>.from(cachedData);
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('roundup_transactions');
      }
    }

    // If no cache or parsing failed, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();
    
    await _fetchRoundupTransactionsFromAPI();
    
    // Ensure loading state is properly managed
    _loading = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data in RoundupProvider
  void clearAllData() {
    _roundupStatus = null;
    _roundupSettings = null;
    _enhancedRoundupStatus = null;
    _pendingRoundups = [];
    _roundupTransactions = [];
    _donationHistory = [];
    _loading = false;
    _error = null;
    _donationHistoryFetched = false;
    notifyListeners();
  }

  /// Refresh methods for pull-to-refresh (bypass cache)
  Future<void> refreshRoundupTransactions() async {
    await _fetchRoundupTransactionsFromAPI();
  }

  Future<void> refreshThisMonthRoundupTransactions() async {
    await _fetchThisMonthRoundupTransactionsFromAPI();
  }

  Future<void> refreshEnhancedRoundupStatus() async {
    await _fetchEnhancedRoundupStatusFromAPI();
  }

  Future<void> refreshDonationHistory() async {
    await _fetchDonationHistoryFromAPI();
  }

  Future<void> refreshRoundupSettings() async {
    await _fetchRoundupSettingsFromAPI();
  }

  Future<void> refreshPendingRoundups() async {
    await _fetchPendingRoundupsFromAPI();
  }

  /// Invalidate roundup transactions cache
  Future<void> invalidateRoundupTransactionsCache() async {
    await _cacheManager.invalidateCache('roundup_transactions');
    await _cacheManager.invalidateCache('this_month_roundup_transactions');
  }

  /// Refresh roundup transactions cache and data
  Future<void> refreshRoundupTransactionsCache() async {
    await invalidateRoundupTransactionsCache();
    await _fetchThisMonthRoundupTransactionsFromAPI();
  }

  /// Fetch roundup settings from API (used when cache is invalid or data changes)
  Future<void> _fetchRoundupSettingsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getRoundupSettings();
      if (response.success && response.data != null) {
        _roundupSettings = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('roundup_settings', response.data!);
      } else {
        _error = response.message;
        _roundupSettings = null;
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch roundup settings: ${e.message}';
      _roundupSettings = null;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _roundupSettings = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch enhanced roundup status from API (used when cache is invalid or data changes)
  Future<void> _fetchEnhancedRoundupStatusFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.getEnhancedRoundupStatus();
      if (response.success && response.data != null) {
    

        _enhancedRoundupStatus = RoundupStatus.fromJson(response.data!);
        
        // Cache the fresh data
        await _cacheManager.cacheData('enhanced_roundup_status', response.data!);
      } else {
        _error = response.message;
        _enhancedRoundupStatus = null;
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch enhanced roundup status: ${e.message}';
      _enhancedRoundupStatus = null;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _enhancedRoundupStatus = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Quick toggle roundups on/off
  Future<ApiResponse<Map<String, dynamic>>> quickToggleRoundups({
    required bool pause,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _roundupService.quickToggleRoundups(pause: pause);
      if (response.success) {
        // Invalidate cache since roundup settings changed
        await _cacheManager.invalidateOnDataChange('roundup_settings');
        await _cacheManager.invalidateOnDataChange('roundup_status');
        // Fetch fresh data
        await _fetchRoundupSettingsFromAPI();
        await _fetchEnhancedRoundupStatusFromAPI();
      } else {
        _error = response.message;
      }
      return response;
    } on DioException catch (e) {
      _error = 'Failed to toggle roundups: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    } catch (e) {
      _error = 'An unexpected error occurred';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Calculate roundup amounts from raw bank transactions
  List<Map<String, dynamic>> _calculateRoundupsFromRawTransactions(List<dynamic> rawTransactions) {
    List<Map<String, dynamic>> roundupTransactions = [];
    
    for (var transaction in rawTransactions) {
      if (transaction is! Map<String, dynamic>) continue;
      
      final amount = (transaction['amount']?.toDouble() ?? 0.0);
      
      // Only calculate roundups for positive amounts (purchases)
      if (amount <= 0) continue;
      
      // Calculate roundup amount (round up to nearest dollar)
      final roundupAmount = (amount.ceil() - amount);
      
      // Only include transactions with actual roundup amounts
      if (roundupAmount <= 0) continue;
      
      // Create roundup transaction with calculated roundup amount
      final roundupTransaction = {
        'transaction_id': transaction['transaction_id'],
        'account_id': transaction['account_id'],
        'amount': amount,
        'roundup_amount': roundupAmount,
        'merchant': transaction['merchant_name'] ?? transaction['name'] ?? 'Unknown Merchant',
        'date': transaction['date'],
        'category': _mapTransactionCategory(transaction),
        'account_name': _getAccountNameFromId(transaction['account_id']?.toString()),
        'status': 'pending', // Add status to track transferred vs pending
      };
      
      roundupTransactions.add(roundupTransaction);
    }
    
    // Sort by date (newest first)
    roundupTransactions.sort((a, b) {
      final dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    return roundupTransactions;
  }
  
  /// Map transaction type/category to user-friendly category
  String _mapTransactionCategory(Map<String, dynamic> transaction) {
    final transactionType = transaction['transaction_type']?.toString().toLowerCase();
    final merchantName = (transaction['merchant_name'] ?? transaction['name'] ?? '').toString().toLowerCase();
    
    if (transactionType == 'place' || merchantName.contains('restaurant') || merchantName.contains('food')) {
      return 'Food & Dining';
    } else if (merchantName.contains('gas') || merchantName.contains('fuel')) {
      return 'Gas & Transportation';
    } else if (merchantName.contains('grocery') || merchantName.contains('market')) {
      return 'Groceries';
    } else if (merchantName.contains('coffee') || merchantName.contains('starbucks')) {
      return 'Coffee & Drinks';
    } else if (transactionType == 'special') {
      return 'Transportation';
    } else {
      return 'General';
    }
  }
  
  /// Get account name from account ID (simplified - you may want to cache this)
  String _getAccountNameFromId(String? accountId) {
    if (accountId == null) return 'Unknown Account';
    // This is a simplified approach - in a real implementation, 
    // you might want to maintain a cache of account ID to name mappings
    return 'Bank Account';
  }



  /// Force refresh all roundup data for debugging
  Future<void> forceRefreshAllRoundupData() async {
    // Clear all caches
    await _cacheManager.invalidateCache('roundup_transactions');
    await _cacheManager.invalidateCache('this_month_roundup_transactions');
    await _cacheManager.invalidateCache('enhanced_roundup_status');
    
    // Fetch fresh data
    await Future.wait([
      _fetchRoundupTransactionsFromAPI(),
      _fetchEnhancedRoundupStatusFromAPI(),
    ]);
  }
}
