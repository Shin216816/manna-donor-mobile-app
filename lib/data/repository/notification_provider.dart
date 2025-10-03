import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/notification_service.dart';
import 'package:manna_donate_app/data/models/notification.dart';
import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/core/cache_manager.dart';
import 'package:dio/dio.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final CacheManager _cacheManager = CacheManager();

  List<DonorNotification> _notifications = [];
  Map<String, dynamic>? _preferences;
  bool _loading = false;
  String? _error;

  List<DonorNotification> get notifications => _notifications;
  Map<String, dynamic>? get preferences => _preferences;
  bool get loading => _loading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Fetch donor notifications (cache-first)
  Future<void> fetchNotifications() async {
    // Skip if we already know notifications are not available
    if (_error != null && _error!.contains('not available yet')) {
      return;
    }

    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('notifications');
    if (cachedData != null) {
      _notifications = List<DonorNotification>.from(cachedData);
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchNotificationsFromAPI();
  }

  /// Fetch notifications from API (used when cache is invalid or data changes)
  Future<void> _fetchNotificationsFromAPI() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _notificationService.getDonorNotifications();
      if (response.success && response.data != null) {
        _notifications = response.data!
            .map((json) => DonorNotification.fromJson(json))
            .toList();
        // Cache the fresh data
        await _cacheManager.cacheData('notifications', _notifications);
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        _error =
            'You are not authorized to view notifications. Please log in again.';
      } else if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet - show empty state
        _notifications = [];
        _error = 'Notifications feature not available yet';
      } else {
        _error = 'An error occurred: ${e.message}';
      }
    } catch (e) {
      _error = 'An unexpected error occurred.';
    }

    _loading = false;
    notifyListeners();
  }

  /// Mark notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(
    String notificationId,
  ) async {
    try {
      final response = await _notificationService.markNotificationRead(
        notificationId,
      );
      if (response.success) {
        // Update local notification
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          notifyListeners();
        }
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet
        return ApiResponse(
          success: false,
          message: 'Notifications feature not available yet',
        );
      }
      _error = 'Failed to mark notification as read: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsRead() async {
    try {
      final response = await _notificationService.markAllNotificationsRead();
      if (response.success) {
        // Update all local notifications
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet
        return ApiResponse(
          success: false,
          message: 'Notifications feature not available yet',
        );
      }
      _error = 'Failed to mark all notifications as read: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Delete notification
  Future<ApiResponse<Map<String, dynamic>>> deleteNotification(
    String notificationId,
  ) async {
    try {
      final response = await _notificationService.deleteNotification(
        notificationId,
      );
      if (response.success) {
        // Remove from local list
        _notifications.removeWhere((n) => n.id == notificationId);
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
      }
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet
        return ApiResponse(
          success: false,
          message: 'Notifications feature not available yet',
        );
      }
      _error = 'Failed to delete notification: ${e.message}';
      return ApiResponse(success: false, message: _error!);
    }
  }

  /// Fetch notification preferences (cache-first)
  Future<void> fetchNotificationPreferences() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('notification_preferences');
    if (cachedData != null) {
      _preferences = cachedData as Map<String, dynamic>?;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchNotificationPreferencesFromAPI();
  }

  /// Fetch notification preferences from API (used when cache is invalid or data changes)
  Future<void> _fetchNotificationPreferencesFromAPI() async {
    try {
      final response = await _notificationService.getNotificationPreferences();
      if (response.success && response.data != null) {
        _preferences = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('notification_preferences', response.data!);
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
        notifyListeners();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet - use default preferences
        _preferences = {
          'email_notifications': true,
          'sms_notifications': false,
          'push_notifications': true,
          'donation_confirmations': true,
          'roundup_notifications': true,
          'schedule_reminders': true,
        };
        _error = null;
        // Cache the default preferences
        await _cacheManager.cacheData('notification_preferences', _preferences);
      } else {
        _error = 'Failed to fetch notification preferences: ${e.message}';
      }
      notifyListeners();
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    required bool emailNotifications,
    required bool smsNotifications,
    required bool pushNotifications,
    required bool donationConfirmations,
    required bool roundupNotifications,
    required bool scheduleReminders,
  }) async {
    try {
      final response = await _notificationService.updateNotificationPreferences(
        emailNotifications: emailNotifications,
        smsNotifications: smsNotifications,
        pushNotifications: pushNotifications,
        donationConfirmations: donationConfirmations,
        roundupNotifications: roundupNotifications,
        scheduleReminders: scheduleReminders,
      );
      if (response.success && response.data != null) {
        _preferences = response.data!;
        notifyListeners();
      } else {
        _error = ApiResponse.userFriendlyMessage(
          response.errorCode,
          response.message,
        );
        notifyListeners();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Notifications endpoint not implemented yet
        _error = 'Notifications feature not available yet';
      } else {
        _error = 'Failed to update notification preferences: ${e.message}';
      }
      notifyListeners();
    }
  }

  /// Add local notification (for immediate feedback)
  void addLocalNotification(String message) {
    final notification = DonorNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Notification',
      message: message,
      type: 'local',
      isRead: false,
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notification);
    notifyListeners();
  }

  /// Clear all notifications
  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data in NotificationProvider
  void clearAllData() {
    _notifications = [];
    _preferences = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  /// Check if notifications feature is available
  bool get isNotificationsAvailable {
    return _error == null || !_error!.contains('not available yet');
  }

  /// Initialize notifications (call once to check availability)
  Future<void> initializeNotifications() async {
    // Don't automatically fetch notifications - let the UI decide when to load them
    // This prevents 404 errors on app startup
    if (_notifications.isEmpty && _error == null) {
      // Set default state without making API calls
      _notifications = [];
      _error = null;
      notifyListeners();
    }
  }
}
