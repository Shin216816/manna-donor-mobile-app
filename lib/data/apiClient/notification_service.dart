import 'package:manna_donate_app/core/api_service.dart';
import 'package:manna_donate_app/data/models/api_response.dart';

class NotificationService {
  final ApiService _api = ApiService();

  /// Get donor notifications
  Future<ApiResponse<List<Map<String, dynamic>>>>
  getDonorNotifications() async {
    final response = await _api.get('/mobile/donor/notifications');
    // Parse notifications from new response schema: data['notifications']
    return ApiResponse.fromJson(response.data, (data) {
      final list = data['notifications'] as List? ?? [];
      return list.cast<Map<String, dynamic>>();
    });
  }

  /// Mark notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(
    String notificationId,
  ) async {
    final response = await _api.post(
      '/mobile/donor/notifications/$notificationId/read',
    );
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsRead() async {
    final response = await _api.post('/mobile/donor/notifications/read-all');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// Delete notification
  Future<ApiResponse<Map<String, dynamic>>> deleteNotification(
    String notificationId,
  ) async {
    final response = await _api.delete('/mobile/donor/notifications/$notificationId');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// Get notification preferences
  Future<ApiResponse<Map<String, dynamic>>> getNotificationPreferences() async {
    final response = await _api.get('/mobile/donor/notification-preferences');
    return ApiResponse.fromJson(response.data, (data) => data);
  }

  /// Update notification preferences
  Future<ApiResponse<Map<String, dynamic>>> updateNotificationPreferences({
    required bool emailNotifications,
    required bool smsNotifications,
    required bool pushNotifications,
    required bool donationConfirmations,
    required bool roundupNotifications,
    required bool scheduleReminders,
  }) async {
    final response = await _api.post(
      '/mobile/donor/notification-preferences',
      data: {
        'email_notifications': emailNotifications,
        'sms_notifications': smsNotifications,
        'push_notifications': pushNotifications,
        'donation_confirmations': donationConfirmations,
        'roundup_notifications': roundupNotifications,
        'schedule_reminders': scheduleReminders,
      },
    );
    return ApiResponse.fromJson(response.data, (data) => data);
  }
}
