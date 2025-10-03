import 'package:manna_donate_app/data/apiClient/bank_service.dart';
import 'package:manna_donate_app/data/apiClient/roundup_service.dart';
import 'package:manna_donate_app/data/apiClient/auth_service.dart';
import 'package:manna_donate_app/data/apiClient/church_message_service.dart';
import 'package:manna_donate_app/data/apiClient/church_service.dart';
import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:logger/logger.dart';

class InitialDataFetcher {
  static final InitialDataFetcher _instance = InitialDataFetcher._internal();
  factory InitialDataFetcher() => _instance;
  InitialDataFetcher._internal();

  final CacheManager _cacheManager = CacheManager();
  final BankService bankService = BankService();
  final RoundupService roundupService = RoundupService();
  final AuthService authService = AuthService();
  final ChurchMessageService churchMessageService = ChurchMessageService();
  final ChurchService churchService = ChurchService();
  final Logger _logger = Logger();

  // Getter for cache manager
  CacheManager get cacheManager => _cacheManager;

  /// Fetch all necessary data for donor app
  Future<void> fetchAllDonorData() async {
    try {
      // Get current user data to set user ID for cache management
      final userResponse = await authService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userData = userResponse.data!;
        final userId =
            userData['id']?.toString() ?? userData['user_id']?.toString();
        if (userId != null) {
          await _cacheManager.setUserId(userId);
        }
      }

      // Fetch all data in parallel for maximum speed
      await Future.wait([
        _fetchBankData(),
        _fetchRoundupData(),
        _fetchProfileData(),
        _fetchChurchData(),
      ]);

      // Set last fetch time
      await _cacheManager.setLastFetchTime();
    } catch (e) {
      // Handle fetch error silently
    }
  }

  /// Fetch only critical data for faster initial load
  Future<void> fetchCriticalDataOnly() async {
    try {
      _logger.i('Starting critical data fetch...');

      // Get current user data to set user ID for cache management
      final userResponse = await authService.getMe();
      if (userResponse.success && userResponse.data != null) {
        final userData = userResponse.data!;
        final userId =
            userData['id']?.toString() ?? userData['user_id']?.toString();
        if (userId != null) {
          await _cacheManager.setUserId(userId);
          _logger.i('Set user ID for cache: $userId');
        }
      }

      // Fetch only critical data in parallel for maximum speed
      _logger.i('Fetching critical data in parallel...');
      await Future.wait([
        _fetchCriticalBankData(),
        _fetchCriticalProfileData(),
        _fetchCriticalRoundupData(),
        _fetchCriticalChurchData(),
      ]);

      // Set last fetch time
      await _cacheManager.setLastFetchTime();
      _logger.i('Critical data fetch completed');
    } catch (e) {
      _logger.e('Critical data fetch error: $e');
    }
  }

  /// Fetch bank-related data
  Future<void> _fetchBankData() async {
    try {
      // Bank accounts
      final bankAccountsResponse = await bankService.getBankAccounts();
      if (bankAccountsResponse.success && bankAccountsResponse.data != null) {
        await _cacheManager.cacheData(
          'bank_accounts',
          bankAccountsResponse.data,
        );
      }

      // Preferences
      final preferencesResponse = await bankService.getPreferences();
      if (preferencesResponse.success) {
        await _cacheManager.cacheData('preferences', preferencesResponse.data);
      }

      // Dashboard
      final dashboardResponse = await bankService.getDashboard();
      if (dashboardResponse.success && dashboardResponse.data != null) {
        await _cacheManager.cacheData('dashboard', dashboardResponse.data);
      }

      // Donation history (using mobile endpoint)
      final donationHistoryResponse = await roundupService.getDonationHistory();
      if (donationHistoryResponse.success &&
          donationHistoryResponse.data != null) {
        // Convert mobile donation history format to cache format
        final data = donationHistoryResponse.data!;
        final List<dynamic> historyList = data['history'] ?? [];
        await _cacheManager.cacheData(
          'donation_history',
          historyList,
        );
      }

      // Donation summary
      final donationSummaryResponse = await bankService.getDonationSummary();
      if (donationSummaryResponse.success &&
          donationSummaryResponse.data != null) {
        await _cacheManager.cacheData(
          'donation_summary',
          donationSummaryResponse.data,
        );
      }

      // Payment methods
      final paymentMethodsResponse = await bankService.getPaymentMethods();
      if (paymentMethodsResponse.success &&
          paymentMethodsResponse.data != null) {
        await _cacheManager.cacheData(
          'payment_methods',
          paymentMethodsResponse.data,
        );
      }

      // Transactions - get account IDs first
      final now = DateTime.now();
      final startDate = now
          .subtract(const Duration(days: 30))
          .toIso8601String()
          .split('T')[0];
      final endDate = now.toIso8601String().split('T')[0];

      // Get bank accounts to get account IDs for transactions
      final bankAccountsForTransactionsResponse = await bankService
          .getBankAccounts();
      if (bankAccountsForTransactionsResponse.success &&
          bankAccountsForTransactionsResponse.data != null) {
        final bankAccounts = bankAccountsForTransactionsResponse.data!;
        final accountIds = bankAccounts
            .map((account) => account.accountId)
            .toList();

        if (accountIds.isNotEmpty) {
          final transactionsResponse = await bankService.getTransactions(
            startDate: startDate,
            endDate: endDate,
            accountIds: accountIds,
          );
          if (transactionsResponse.success &&
              transactionsResponse.data != null) {
            // Store the transactions array from the response
            final transactionsData =
                transactionsResponse.data?['transactions'] ?? [];
            await _cacheManager.cacheData('transactions', transactionsData);
          }
        } else {
          // Cache empty transactions array if no accounts
          await _cacheManager.cacheData('transactions', []);
        }
      } else {
        // Cache empty transactions array if bank accounts fetch failed
        await _cacheManager.cacheData('transactions', []);
      }
    } catch (e) {
      // Handle bank data fetch error silently
    }
  }

  /// Fetch only critical bank data for faster initial load
  Future<void> _fetchCriticalBankData() async {
    try {
      _logger.i('Starting critical bank data fetch...');

      // Only fetch essential bank data
      await Future.wait([
        // Bank accounts
        bankService
            .getBankAccounts()
            .then((response) async {
              _logger.i(
                'Bank accounts response: success=${response.success}, message=${response.message}',
              );
              if (response.success && response.data != null) {
                await _cacheManager.cacheData('bank_accounts', response.data);
                _logger.i('Bank accounts cached successfully');
              } else {
                _logger.w('Bank accounts fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Bank accounts fetch error: $e');
            }),
        // Preferences
        bankService
            .getPreferences()
            .then((response) async {
              _logger.i(
                'Preferences response: success=${response.success}, message=${response.message}',
              );
              if (response.success) {
                await _cacheManager.cacheData('preferences', response.data);
                _logger.i('Preferences cached successfully');
              } else {
                _logger.w('Preferences fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Preferences fetch error: $e');
            }),
        // Payment methods
        (() async {
          _logger.i('Calling getPaymentMethods...');
          try {
            final response = await bankService.getPaymentMethods();
            _logger.i(
              'Payment methods response: success=${response.success}, message=${response.message}',
            );
            if (response.success && response.data != null) {
              _logger.i('Payment methods data: ${response.data}');
              // Store the payment_methods array from the response
              final paymentMethodsData =
                  response.data?['payment_methods'] ?? [];
              await _cacheManager.cacheData(
                'payment_methods',
                paymentMethodsData,
              );
              _logger.i('Payment methods cached successfully');
            } else {
              _logger.w('Payment methods fetch failed: ${response.message}');
            }
          } catch (e) {
            _logger.w('Payment methods fetch error: $e');
          }
        })(),
        // Donation summary
        bankService
            .getDonationSummary()
            .then((response) async {
              _logger.i(
                'Donation summary response: success=${response.success}, message=${response.message}',
              );
              if (response.success && response.data != null) {
                await _cacheManager.cacheData(
                  'donation_summary',
                  response.data,
                );
                _logger.i('Donation summary cached successfully');
              } else {
                _logger.w('Donation summary fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Donation summary fetch error: $e');
            }),
        // Transactions (last 30 days) - fetch after getting bank accounts
        (() async {
          _logger.i('Calling getTransactions...');
          try {
            // First get bank accounts to get account IDs
            final bankAccountsResponse = await bankService.getBankAccounts();
            if (bankAccountsResponse.success &&
                bankAccountsResponse.data != null) {
              final bankAccounts = bankAccountsResponse.data!;
              // Only get account IDs from linked bank accounts
              final accountIds = bankAccounts
                  .where((account) => account.isLinked)
                  .map((account) => account.accountId)
                  .toList();

              _logger.i(
                'Found ${accountIds.length} linked bank accounts for transactions',
              );

              if (accountIds.isNotEmpty) {
                // Get transactions for a wider date range (last 12 months) for better summary calculations
                final response = await bankService.getTransactions(
                  startDate: DateTime.now()
                      .subtract(const Duration(days: 365))
                      .toIso8601String()
                      .split('T')[0],
                  endDate: DateTime.now().toIso8601String().split('T')[0],
                  accountIds: accountIds,
                );
                _logger.i(
                  'Transactions response: success=${response.success}, message=${response.message}',
                );
                if (response.success && response.data != null) {
                  _logger.i('Transactions data: ${response.data}');
                  // Store the transactions array from the response
                  final transactionsData = response.data?['transactions'] ?? [];
                  await _cacheManager.cacheData(
                    'transactions',
                    transactionsData,
                  );
                  _logger.i('Transactions cached successfully');
                } else {
                  _logger.w('Transactions fetch failed: ${response.message}');
                }
              } else {
                _logger.w(
                  'No bank accounts found, skipping transactions fetch',
                );
                // Cache empty transactions array
                await _cacheManager.cacheData('transactions', []);
              }
            } else {
              _logger.w(
                'Failed to get bank accounts for transactions: ${bankAccountsResponse.message}',
              );
              // Cache empty transactions array
              await _cacheManager.cacheData('transactions', []);
            }
          } catch (e) {
            _logger.w('Transactions fetch error: $e');
            // Cache empty transactions array on error
            await _cacheManager.cacheData('transactions', []);
          }
        })(),
      ]);
      _logger.i('Critical bank data fetch completed');
    } catch (e) {
      _logger.w('Critical bank data fetch error: $e');
    }
  }

  /// Fetch roundup-related data
  Future<void> _fetchRoundupData() async {
    try {
      // Roundup status
      final roundupStatusResponse = await roundupService
          .getEnhancedRoundupStatus();
      if (roundupStatusResponse.success && roundupStatusResponse.data != null) {
        await _cacheManager.cacheData(
          'enhanced_roundup_status',
          roundupStatusResponse.data,
        );
      }

      // Roundup settings
      final roundupSettingsResponse = await roundupService.getRoundupSettings();
      if (roundupSettingsResponse.success &&
          roundupSettingsResponse.data != null) {
        await _cacheManager.cacheData(
          'roundup_settings',
          roundupSettingsResponse.data,
        );
      }

      // Pending roundups
      final pendingRoundupsResponse = await roundupService.getPendingRoundups();
      if (pendingRoundupsResponse.success &&
          pendingRoundupsResponse.data != null) {
        await _cacheManager.cacheData(
          'pending_roundups',
          pendingRoundupsResponse.data,
        );
      }

      // Roundup history
      final roundupHistoryResponse = await roundupService.getDonationHistory();
      if (roundupHistoryResponse.success &&
          roundupHistoryResponse.data != null) {
        await _cacheManager.cacheData(
          'roundup_history',
          roundupHistoryResponse.data,
        );
      }
    } catch (e) {
      // Handle roundup data fetch error silently
    }
  }

  /// Fetch only critical roundup data for faster initial load
  Future<void> _fetchCriticalRoundupData() async {
    try {
      // Only fetch essential roundup data
      await Future.wait([
        // Roundup transactions (calculated from raw bank transactions)
        (() async {
          try {
            // Get raw transactions from bank service (last 90 days)
            final now = DateTime.now();
            final startDate = now
                .subtract(const Duration(days: 90))
                .toIso8601String()
                .split('T')[0];
            final endDate = now.toIso8601String().split('T')[0];

            // Get bank accounts first
            final bankAccountsResponse = await bankService.getBankAccounts();
            if (bankAccountsResponse.success &&
                bankAccountsResponse.data != null) {
              final bankAccounts = bankAccountsResponse.data!;
              final accountIds = bankAccounts
                  .where((account) => account.isLinked)
                  .map((account) => account.accountId)
                  .toList();

              if (accountIds.isNotEmpty) {
                final transactionsResponse = await bankService.getTransactions(
                  startDate: startDate,
                  endDate: endDate,
                  accountIds: accountIds,
                );

                if (transactionsResponse.success &&
                    transactionsResponse.data != null) {
                  final rawTransactions =
                      transactionsResponse.data!['transactions'] as List? ?? [];

                  // Calculate roundup transactions from raw transactions
                  final roundupTransactions =
                      _calculateRoundupsFromRawTransactions(rawTransactions);

                  // Cache the calculated roundup transactions
                  await _cacheManager.cacheData(
                    'roundup_transactions',
                    roundupTransactions,
                  );
                  _logger.i(
                    'Calculated and cached ${roundupTransactions.length} roundup transactions',
                  );
                } else {
                  _logger.w(
                    'Failed to fetch raw transactions for roundup calculation',
                  );
                  await _cacheManager.cacheData('roundup_transactions', []);
                }
              } else {
                _logger.w(
                  'No linked bank accounts found for roundup calculations',
                );
                await _cacheManager.cacheData('roundup_transactions', []);
              }
            } else {
              _logger.w(
                'Failed to fetch bank accounts for roundup calculations',
              );
              await _cacheManager.cacheData('roundup_transactions', []);
            }
          } catch (e) {
            _logger.w('Roundup transactions calculation error: $e');
            await _cacheManager.cacheData('roundup_transactions', []);
          }
        })(),
        // This month's roundup transactions (calculated from raw bank transactions)
        (() async {
          try {
            // Get raw transactions for this month from bank service
            final now = DateTime.now();
            final startOfMonth = DateTime(now.year, now.month, 1);
            final endOfMonth = DateTime(now.year, now.month + 1, 0);

            final startDate = startOfMonth.toIso8601String().split('T')[0];
            final endDate = endOfMonth.toIso8601String().split('T')[0];

            // Get bank accounts first
            final bankAccountsResponse = await bankService.getBankAccounts();
            if (bankAccountsResponse.success &&
                bankAccountsResponse.data != null) {
              final bankAccounts = bankAccountsResponse.data!;
              final accountIds = bankAccounts
                  .where((account) => account.isLinked)
                  .map((account) => account.accountId)
                  .toList();

              if (accountIds.isNotEmpty) {
                final transactionsResponse = await bankService.getTransactions(
                  startDate: startDate,
                  endDate: endDate,
                  accountIds: accountIds,
                );

                if (transactionsResponse.success &&
                    transactionsResponse.data != null) {
                  final rawTransactions =
                      transactionsResponse.data!['transactions'] as List? ?? [];

                  // Calculate roundup transactions from raw transactions
                  final roundupTransactions =
                      _calculateRoundupsFromRawTransactions(rawTransactions);

                  // Cache the calculated roundup transactions for this month
                  await _cacheManager.cacheData(
                    'this_month_roundup_transactions',
                    roundupTransactions,
                  );
                  _logger.i(
                    'Calculated and cached ${roundupTransactions.length} this month roundup transactions',
                  );
                } else {
                  _logger.w(
                    'Failed to fetch this month raw transactions for roundup calculation',
                  );
                  await _cacheManager.cacheData(
                    'this_month_roundup_transactions',
                    [],
                  );
                }
              } else {
                _logger.w(
                  'No linked bank accounts found for this month roundup calculations',
                );
                await _cacheManager.cacheData(
                  'this_month_roundup_transactions',
                  [],
                );
              }
            } else {
              _logger.w(
                'Failed to fetch bank accounts for this month roundup calculations',
              );
              await _cacheManager.cacheData(
                'this_month_roundup_transactions',
                [],
              );
            }
          } catch (e) {
            _logger.w('This month roundup transactions calculation error: $e');
            await _cacheManager.cacheData(
              'this_month_roundup_transactions',
              [],
            );
          }
        })(),
        // Roundup status
        roundupService
            .getEnhancedRoundupStatus()
            .then((response) async {
              if (response.success && response.data != null) {
                await _cacheManager.cacheData(
                  'enhanced_roundup_status',
                  response.data,
                );
              } else {
                _logger.w('Roundup status fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Roundup status fetch error: $e');
            }),
        // Roundup settings
        roundupService
            .getRoundupSettings()
            .then((response) async {
              if (response.success && response.data != null) {
                await _cacheManager.cacheData(
                  'roundup_settings',
                  response.data,
                );
              } else {
                _logger.w('Roundup settings fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Roundup settings fetch error: $e');
            }),
        // Pending roundups
        roundupService
            .getPendingRoundups()
            .then((response) async {
              if (response.success && response.data != null) {
                await _cacheManager.cacheData(
                  'pending_roundups',
                  response.data,
                );
              } else {
                _logger.w('Pending roundups fetch failed: ${response.message}');
              }
            })
            .catchError((e) {
              _logger.w('Pending roundups fetch error: $e');
            }),
      ]);
    } catch (e) {
      _logger.w('Critical roundup data fetch error: $e');
    }
  }

  /// Fetch profile-related data
  Future<void> _fetchProfileData() async {
    try {
      // User profile
      final profileResponse = await authService.getProfile();
      if (profileResponse.success && profileResponse.data != null) {
        await _cacheManager.cacheData('user_profile', profileResponse.data);
      }

      // User preferences
      final userPreferencesResponse = await authService.getMe();
      if (userPreferencesResponse.success &&
          userPreferencesResponse.data != null) {
        await _cacheManager.cacheData(
          'user_preferences',
          userPreferencesResponse.data,
        );
      }

      // Profile image
      final profileImageResponse = await authService.getProfileImage();
      if (profileImageResponse.success && profileImageResponse.data != null) {
        await _cacheManager.cacheData(
          'profile_image',
          profileImageResponse.data,
        );
      }
    } catch (e) {
      // Handle profile data fetch error silently
    }
  }

  /// Fetch only critical profile data for faster initial load
  Future<void> _fetchCriticalProfileData() async {
    try {
      // Only fetch essential profile data
      await Future.wait([
        // User profile
        authService.getProfile().then((response) async {
          if (response.success && response.data != null) {
            await _cacheManager.cacheData('user_profile', response.data);
          }
        }),
        // User preferences
        authService.getMe().then((response) async {
          if (response.success && response.data != null) {
            await _cacheManager.cacheData('user_preferences', response.data);
          }
        }),
      ]);
    } catch (e) {
      // Handle critical profile data fetch error silently
    }
  }

  /// Fetch church-related data
  Future<void> _fetchChurchData() async {
    try {
      _logger.i('Starting church data fetch...');

      // Available churches
      final availableChurchesResponse = await churchService
          .getAvailableChurches();
      _logger.i(
        'Available churches response: success=${availableChurchesResponse.success}, message=${availableChurchesResponse.message}',
      );
      if (availableChurchesResponse.success &&
          availableChurchesResponse.data != null) {
        await _cacheManager.cacheData(
          'available_churches',
          availableChurchesResponse.data,
        );
        _logger.i('Available churches cached successfully');
      } else {
        _logger.w(
          'Available churches fetch failed: ${availableChurchesResponse.message}',
        );
      }

      // Church messages
      final churchMessagesResponse = await churchMessageService
          .getChurchMessages();
      _logger.i(
        'Church messages response: success=${churchMessagesResponse.success}, message=${churchMessagesResponse.message}',
      );
      if (churchMessagesResponse.success &&
          churchMessagesResponse.data != null) {
        await _cacheManager.cacheData(
          'church_messages',
          churchMessagesResponse.data,
        );
        _logger.i('Church messages cached successfully');
      } else {
        _logger.w(
          'Church messages fetch failed: ${churchMessagesResponse.message}',
        );
      }

      // Unread count
      try {
        final unreadCountResponse = await churchMessageService.getUnreadCount();
        _logger.i(
          'Unread count response: success=${unreadCountResponse.success}, message=${unreadCountResponse.message}',
        );
        if (unreadCountResponse.success && unreadCountResponse.data != null) {
          final unreadCount = unreadCountResponse.data!['unread_count'] ?? 0;
          await _cacheManager.cacheData('unread_count', unreadCount);
          _logger.i('Unread count cached successfully: $unreadCount');
        } else {
          _logger.w(
            'Unread count fetch failed: ${unreadCountResponse.message}',
          );
          // Set default unread count to 0 if fetch fails
          await _cacheManager.cacheData('unread_count', 0);
          _logger.i('Set default unread count to 0');
        }
      } catch (e) {
        _logger.w('Unread count fetch error: $e');
        // Set default unread count to 0 if fetch fails
        await _cacheManager.cacheData('unread_count', 0);
        _logger.i('Set default unread count to 0 due to error');
      }

      _logger.i('Church data fetch completed');
    } catch (e) {
      _logger.w('Church data fetch error: $e');
    }
  }

  /// Fetch only critical church data for faster initial load
  Future<void> _fetchCriticalChurchData() async {
    try {
      _logger.i('Starting critical church data fetch...');

      // Only fetch essential church data
      await Future.wait([
        // Available churches
        churchService.getAvailableChurches().then((response) async {
          _logger.i(
            'Available churches response: success=${response.success}, message=${response.message}',
          );
          if (response.success && response.data != null) {
            await _cacheManager.cacheData('available_churches', response.data);
            _logger.i('Available churches cached successfully');
          } else {
            _logger.w('Available churches fetch failed: ${response.message}');
          }
        }),
        // Church messages
        churchMessageService.getChurchMessages().then((response) async {
          _logger.i(
            'Church messages response: success=${response.success}, message=${response.message}',
          );
          if (response.success && response.data != null) {
            await _cacheManager.cacheData('church_messages', response.data);
            _logger.i('Church messages cached successfully');
          } else {
            _logger.w('Church messages fetch failed: ${response.message}');
          }
        }),
        // Unread count
        churchMessageService.getUnreadCount().then((response) async {
          _logger.i(
            'Unread count response: success=${response.success}, message=${response.message}',
          );
          if (response.success && response.data != null) {
            final unreadCount = response.data!['unread_count'] ?? 0;
            await _cacheManager.cacheData('unread_count', unreadCount);
            _logger.i('Unread count cached successfully: $unreadCount');
          } else {
            _logger.w('Unread count fetch failed: ${response.message}');
            // Set default unread count to 0 if fetch fails
            await _cacheManager.cacheData('unread_count', 0);
            _logger.i('Set default unread count to 0');
          }
        }),
      ]);
      _logger.i('Critical church data fetch completed');
    } catch (e) {
      _logger.w('Critical church data fetch error: $e');
    }
  }

  /// Check if initial fetch is needed
  Future<bool> needsInitialFetch() async {
    return await _cacheManager.needsInitialFetch();
  }

  /// Get cached data for specific type
  Future<dynamic> getCachedData(String dataType) async {
    return await _cacheManager.getCachedData(dataType);
  }

  /// Check if cache is valid for specific type
  Future<bool> isCacheValid(String dataType) async {
    return await _cacheManager.isCacheValid(dataType);
  }

  /// Invalidate specific cache
  Future<void> invalidateCache(String dataType) async {
    await _cacheManager.invalidateCache(dataType);
  }

  /// Invalidate multiple caches
  Future<void> invalidateMultipleCaches(List<String> dataTypes) async {
    await _cacheManager.invalidateMultipleCaches(dataTypes);
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _cacheManager.clearAllCache();
  }

  /// Cache data (delegate to cache manager)
  Future<void> cacheData(String dataType, dynamic data) async {
    await _cacheManager.cacheData(dataType, data);
  }

  /// Force refresh all data (for pull-to-refresh)
  Future<void> forceRefreshAllData() async {
    try {
      _logger.i('Force refreshing all data...');

      // Invalidate all caches first
      await _cacheManager.clearAllCache();

      // Fetch all data fresh from API
      await Future.wait([
        _fetchCriticalBankData(),
        _fetchCriticalRoundupData(),
        _fetchCriticalProfileData(),
        _fetchCriticalChurchData(),
      ]);

      _logger.i('Force refresh completed');
    } catch (e) {
      _logger.w('Force refresh error: $e');
    }
  }

  /// Calculate roundup amounts from raw bank transactions
  List<Map<String, dynamic>> _calculateRoundupsFromRawTransactions(
    List<dynamic> rawTransactions,
  ) {
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
        'merchant':
            transaction['merchant_name'] ??
            transaction['name'] ??
            'Unknown Merchant',
        'date': transaction['date'],
        'category': _mapTransactionCategory(transaction),
        'account_name': _getAccountNameFromId(
          transaction['account_id']?.toString(),
        ),
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
    final transactionType = transaction['transaction_type']
        ?.toString()
        .toLowerCase();
    final merchantName =
        (transaction['merchant_name'] ?? transaction['name'] ?? '')
            .toString()
            .toLowerCase();

    if (transactionType == 'place' ||
        merchantName.contains('restaurant') ||
        merchantName.contains('food')) {
      return 'Food & Dining';
    } else if (merchantName.contains('gas') || merchantName.contains('fuel')) {
      return 'Gas & Transportation';
    } else if (merchantName.contains('grocery') ||
        merchantName.contains('market')) {
      return 'Groceries';
    } else if (merchantName.contains('coffee') ||
        merchantName.contains('starbucks')) {
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
}
