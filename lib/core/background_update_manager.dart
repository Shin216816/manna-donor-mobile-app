import 'dart:async';
import 'package:manna_donate_app/core/initial_data_fetcher.dart';

class BackgroundUpdateManager {
  static final BackgroundUpdateManager _instance = BackgroundUpdateManager._internal();
  factory BackgroundUpdateManager() => _instance;
  BackgroundUpdateManager._internal();

  final InitialDataFetcher _dataFetcher = InitialDataFetcher();
  Timer? _updateTimer;
  bool _isUpdating = false;

  // Update intervals are defined in cache manager

  /// Start background updates
  void startBackgroundUpdates() {
    _stopBackgroundUpdates(); // Stop any existing timer
    
    // Update every 5 minutes
    _updateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performBackgroundUpdates();
    });
  }

  /// Stop background updates
  void stopBackgroundUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Stop background updates (alias for stopBackgroundUpdates)
  void _stopBackgroundUpdates() {
    stopBackgroundUpdates();
  }

  /// Perform background updates based on data priority
  Future<void> _performBackgroundUpdates() async {
    if (_isUpdating) return; // Prevent concurrent updates
    
    _isUpdating = true;
    
    try {
      // High priority updates (every 5 minutes)
      await _updateHighPriorityData();
      
      // Medium priority updates (every 10 minutes)
      if (_shouldUpdateMediumPriority()) {
        await _updateMediumPriorityData();
      }
      
      // Low priority updates (every 15 minutes)
      if (_shouldUpdateLowPriority()) {
        await _updateLowPriorityData();
      }
    } catch (e) {
      // Handle update error silently
    } finally {
      _isUpdating = false;
    }
  }

  /// Update high priority data
  Future<void> _updateHighPriorityData() async {
    try {
      await Future.wait([
        // Removed _updateDashboard() - not needed for profile screen
        _updateTransactions(),
        _updatePendingRoundups(),
      ]);
    } catch (e) {
      // Handle high priority update error silently
    }
  }

  /// Update medium priority data
  Future<void> _updateMediumPriorityData() async {
    try {
      await Future.wait([
        _updateDonationHistory(),
        _updateRoundupStatus(),
        _updateChurchMessages(),
      ]);
    } catch (e) {
      // Handle medium priority update error silently
    }
  }

  /// Update low priority data
  Future<void> _updateLowPriorityData() async {
    try {
      await Future.wait([
        _updateBankAccounts(),
        _updatePreferences(),
        _updateUserProfile(),
      ]);
    } catch (e) {
      // Handle low priority update error silently
    }
  }

  /// Check if medium priority updates should be performed
  bool _shouldUpdateMediumPriority() {
    // Update every 10 minutes
    return DateTime.now().minute % 10 == 0;
  }

  /// Check if low priority updates should be performed
  bool _shouldUpdateLowPriority() {
    // Update every 15 minutes
    return DateTime.now().minute % 15 == 0;
  }

  /// Update specific data types
  Future<void> _updateDashboard() async {
    try {
      final response = await _dataFetcher.bankService.getDashboard();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('dashboard', response.data);
      }
    } catch (e) {
      // Handle dashboard update error silently
    }
  }

  Future<void> _updateTransactions() async {
    try {
      // First get bank accounts to get account IDs
      final bankAccountsResponse = await _dataFetcher.bankService.getBankAccounts();
      if (bankAccountsResponse.success && bankAccountsResponse.data != null) {
        final bankAccounts = bankAccountsResponse.data!;
        // Only get account IDs from linked bank accounts
        final accountIds = bankAccounts
            .where((account) => account.isLinked)
            .map((account) => account.accountId)
            .toList();
        
        if (accountIds.isNotEmpty) {
          // Get transactions for a wider date range (last 12 months) for better summary calculations
          final now = DateTime.now();
          final startDate = now.subtract(const Duration(days: 365)).toIso8601String().split('T')[0];
          final endDate = now.toIso8601String().split('T')[0];
          
          final response = await _dataFetcher.bankService.getTransactions(
            startDate: startDate,
            endDate: endDate,
            accountIds: accountIds,
          );
          if (response.success && response.data != null) {
            await _dataFetcher.cacheData('transactions', response.data!['transactions'] ?? []);
          }
        }
      }
    } catch (e) {
      // Handle transactions update error silently
    }
  }

  Future<void> _updatePendingRoundups() async {
    try {
      final response = await _dataFetcher.roundupService.getPendingRoundups();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('pending_roundups', response.data);
      }
    } catch (e) {
      // Handle pending roundups update error silently
    }
  }

  Future<void> _updateDonationHistory() async {
    try {
      final response = await _dataFetcher.bankService.getDonationHistory();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('donation_history', response.data?.map((h) => h.toJson()).toList() ?? []);
      }
    } catch (e) {
      // Handle donation history update error silently
    }
  }

  Future<void> _updateRoundupStatus() async {
    try {
      final response = await _dataFetcher.roundupService.getEnhancedRoundupStatus();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('roundup_status', response.data);
      }
    } catch (e) {
      // Handle roundup status update error silently
    }
  }

  Future<void> _updateChurchMessages() async {
    try {
      final response = await _dataFetcher.churchMessageService.getChurchMessages();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('church_messages', response.data);
      }
    } catch (e) {
      // Handle church messages update error silently
    }
  }

  Future<void> _updateBankAccounts() async {
    try {
      final response = await _dataFetcher.bankService.getBankAccounts();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('bank_accounts', response.data);
      }
    } catch (e) {
      // Handle bank accounts update error silently
    }
  }

  Future<void> _updatePreferences() async {
    try {
      final response = await _dataFetcher.bankService.getPreferences();
      if (response.success) {
        await _dataFetcher.cacheData('preferences', response.data?.toJson());
      }
    } catch (e) {
      // Handle preferences update error silently
    }
  }

  Future<void> _updateUserProfile() async {
    try {
      final response = await _dataFetcher.authService.getProfile();
      if (response.success && response.data != null) {
        await _dataFetcher.cacheData('user_profile', response.data);
      }
    } catch (e) {
      // Handle user profile update error silently
    }
  }

  /// Force update specific data type
  Future<void> forceUpdate(String dataType) async {
    try {
      switch (dataType) {
        case 'dashboard':
          await _updateDashboard();
          break;
        case 'donation_history':
          await _updateDonationHistory();
          break;
        case 'roundup_status':
          await _updateRoundupStatus();
          break;
        case 'bank_accounts':
          await _updateBankAccounts();
          break;
        case 'preferences':
          await _updatePreferences();
          break;
        case 'user_profile':
          await _updateUserProfile();
          break;
        default:
          // Handle unknown data type
          break;
      }
    } catch (e) {
      // Handle force update error silently
    }
  }

  /// Update data when user makes changes
  Future<void> updateOnUserAction(String action) async {
    try {
      switch (action) {
        case 'profile_updated':
          await _dataFetcher.invalidateCache('user_profile');
          await _updateUserProfile();
          break;
        case 'bank_account_linked':
          await _dataFetcher.invalidateCache('bank_accounts');
          await _updateBankAccounts();
          break;
        case 'preferences_updated':
          await _dataFetcher.invalidateCache('preferences');
          await _updatePreferences();
          break;
        case 'donation_made':
          await _dataFetcher.invalidateMultipleCaches(['donation_history', 'dashboard']);
          await Future.wait([_updateDonationHistory(), _updateDashboard()]);
          break;
        case 'roundup_settings_changed':
          await _dataFetcher.invalidateMultipleCaches(['roundup_settings', 'roundup_status']);
          await Future.wait([_updateRoundupStatus()]);
          break;
        default:
          // Handle unknown action
          break;
      }
    } catch (e) {
      // Handle user action update error silently
    }
  }
}
