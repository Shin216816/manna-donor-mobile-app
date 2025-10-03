import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/models/church.dart';
import 'package:manna_donate_app/data/apiClient/church_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/cache_manager.dart';

class ChurchProvider extends ChangeNotifier {
  final ChurchService _churchService = ChurchService();
  final CacheManager _cacheManager = CacheManager();

  List<Church> _searchResults = [];
  List<Church> _availableChurches = [];
  Church? _selectedChurch;
  bool _loading = false;
  String? _error;

  // Getters
  List<Church> get searchResults => _searchResults;
  List<Church> get availableChurches => _availableChurches;
  Church? get selectedChurch => _selectedChurch;
  bool get loading => _loading;
  String? get error => _error;

  // Helper getters
  bool get hasSelectedChurch => _selectedChurch != null;
  List<Church> get churches =>
      _availableChurches.isNotEmpty ? _availableChurches : _searchResults;

  /// Initialize church data (cache-first)
  Future<void> initialize() async {
    await fetchAvailableChurches();
  }

  /// Initialize church data with user sync (cache-first)
  Future<void> initializeWithUserSync(int userId) async {
    await fetchAvailableChurches();
    await syncUserChurchFromServer(userId);
  }

  /// Fetch all available churches for donors (cache-first)
  Future<void> fetchAvailableChurches() async {
    // Force fetch from API to ensure fresh data
    await _fetchAvailableChurchesFromAPI();
  }

  /// Fetch available churches from API (used when cache is invalid or data changes)
  Future<void> _fetchAvailableChurchesFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _churchService.getAvailableChurches();
      if (response.success && response.data != null) {
        _availableChurches = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('available_churches', response.data!);
      } else {
        _error = response.message ?? 'Failed to fetch churches';
        _availableChurches = [];
      }
    } catch (e) {
      _error = 'Failed to fetch churches: $e';
      _availableChurches = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Search churches by name or location
  Future<void> searchChurches(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _churchService.searchChurches(query);
      if (response.success && response.data != null) {
        _searchResults = response.data!;
      } else {
        _error = response.message;
        _searchResults = [];
      }
    } catch (e) {
      _error = 'Failed to search churches: $e';
      _searchResults = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Select a church for the current user
  Future<ApiResponse> selectChurch(int userId, Church church) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _churchService.selectChurch(
        userId.toString(),
        church.id.toString(),
      );
      if (response.success) {
        _selectedChurch = church;
        
        // Handle welcome message if present in response
        if (response.data != null && response.data!['welcome_message'] != null) {
          handleWelcomeMessage(response.data!['welcome_message']);
        }
        
        // Invalidate user cache so that getProfile() will fetch fresh data
        await _cacheManager.invalidateCache('user_profile');
        
        // Also invalidate church-related caches to ensure fresh data
        await _cacheManager.invalidateCache('user_church_info');
        await _cacheManager.invalidateCache('church_messages');
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to select church: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Get user's selected church info
  Future<ApiResponse<Map<String, dynamic>>> getUserChurchInfo(
    int userId,
  ) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _churchService.getUserChurchInfo(
        userId.toString(),
      );
      if (response.success && response.data != null) {
        // Update selected church if user has one
        if (response.data!['church'] != null) {
          final churchData = response.data!['church'] as Map<String, dynamic>;
          _selectedChurch = Church.fromJson(churchData);
        } else {
          _selectedChurch = null;
        }
      } else {
        _error = response.message;
        _selectedChurch = null;
      }
      return response;
    } catch (e) {
      _error = 'Failed to get user church info: $e';
      _selectedChurch = null;
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Unselect church for the current user
  Future<ApiResponse> unselectChurch(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _churchService.unselectChurch(userId.toString());
      if (response.success) {
        _selectedChurch = null;
        // Invalidate user cache so that getProfile() will fetch fresh data
        await _cacheManager.invalidateCache('user_profile');
        
        // Also invalidate church-related caches to ensure fresh data
        await _cacheManager.invalidateCache('user_church_info');
        await _cacheManager.invalidateCache('church_messages');
      } else {
        _error = response.message;
      }
      return response;
    } catch (e) {
      _error = 'Failed to unselect church: $e';
      return ApiResponse(success: false, message: _error!);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh methods for pull-to-refresh (bypass cache)
  Future<void> refreshAvailableChurches() async {
    // Clear cache first, then fetch fresh data
    await _cacheManager.invalidateCache('available_churches');
    await _fetchAvailableChurchesFromAPI();
  }

  /// Force refresh churches data (clear cache and fetch)
  Future<void> forceRefreshChurches() async {
    await _cacheManager.invalidateCache('available_churches');
    await _fetchAvailableChurchesFromAPI();
  }

  /// Set selected church (for local state management)
  void setSelectedChurch(Church? church) {
    _selectedChurch = church;
    notifyListeners();
  }

  /// Sync selected church from user profile
  Future<void> syncSelectedChurchFromProfile(List<String> userChurchIds) async {
    if (userChurchIds.isEmpty) {
      _selectedChurch = null;
      notifyListeners();
      return;
    }

    // Find the first church in the available churches that matches user's church ID
    final firstChurchId = int.parse(userChurchIds.first);
    final userChurch = _availableChurches.firstWhere(
      (church) => church.id == firstChurchId,
      orElse: () => Church(
        id: 0,
        name: '',
        address: '',
        phone: '',
        website: '',
        kycStatus: '',
        isActive: false,
        isVerified: false,
      ),
    );

    if (userChurch.id != 0) {
      _selectedChurch = userChurch;
      notifyListeners();
    }
  }

  /// Sync user's church information from server and update cache
  Future<void> syncUserChurchFromServer(int userId) async {
    try {
      final response = await getUserChurchInfo(userId);
      if (response.success && response.data != null) {
        // Cache the user's church information
        await _cacheManager.cacheData('user_church_info', response.data!);
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking the app
      print('Error syncing user church from server: $e');
    }
  }

  /// Get cached user church info or fetch from server
  Future<Map<String, dynamic>?> getCachedUserChurchInfo(int userId) async {
    try {
      // Try to get from cache first
      final cachedData = await _cacheManager.getCachedData('user_church_info');
      if (cachedData != null) {
        return cachedData as Map<String, dynamic>;
      }
      
      // If not in cache, fetch from server
      final response = await getUserChurchInfo(userId);
      if (response.success && response.data != null) {
        // Cache the data for future use
        await _cacheManager.cacheData('user_church_info', response.data!);
        return response.data!;
      }
      
      return null;
    } catch (e) {
      print('Error getting cached user church info: $e');
      return null;
    }
  }

  /// Clear all data
  void clear() {
    _searchResults = [];
    _availableChurches = [];
    _selectedChurch = null;
    _error = null;
    notifyListeners();
  }

  // Backward compatibility methods
  /// Fetch churches (alias for fetchAvailableChurches)
  Future<void> fetchChurches() async {
    return fetchAvailableChurches();
  }

  /// Legacy method for fetching user churches by search
  Future<void> fetchUserChurchesBySearch(List<int> churchIds) async {
    if (churchIds.isEmpty) {
      _availableChurches = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // First fetch all available churches
      final response = await _churchService.getAvailableChurches();
      if (response.success && response.data != null) {
        // Filter churches to only include the user's linked churches
        _availableChurches = response.data!
            .where((church) => churchIds.contains(church.id))
            .toList();
      } else {
        _error = response.message;
        _availableChurches = [];
      }
    } catch (e) {
      _error = 'Failed to fetch user churches: $e';
      _availableChurches = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Legacy method for fetching nearby churches
  Future<void> fetchNearbyChurches() async {
    // This method is no longer needed in the new model
    // All available churches are fetched globally
    await fetchAvailableChurches();
  }

  /// Handle welcome message from church selection
  void handleWelcomeMessage(Map<String, dynamic> welcomeMessageData) {
    // Store the welcome message for later display
    // This can be used to show a notification or display in the messages screen
    final welcomeMessage = {
      'id': welcomeMessageData['id'],
      'title': welcomeMessageData['title'],
      'content': welcomeMessageData['content'],
      'type': welcomeMessageData['type'],
      'priority': welcomeMessageData['priority'],
      'created_at': welcomeMessageData['created_at'],
      'is_welcome_message': true,
    };
    
    // Cache the welcome message
    _cacheManager.cacheData('welcome_message', welcomeMessage);
    
    // You can also trigger a notification here
    // TODO: Implement notification system for welcome messages
  }

  /// Get cached welcome message
  Future<Map<String, dynamic>?> getCachedWelcomeMessage() async {
    try {
      return await _cacheManager.getCachedData('welcome_message') as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Clear welcome message cache
  Future<void> clearWelcomeMessage() async {
    await _cacheManager.invalidateCache('welcome_message');
  }
}
