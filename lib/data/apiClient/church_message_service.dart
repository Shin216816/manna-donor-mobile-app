import 'package:manna_donate_app/data/models/api_response.dart';
import 'package:manna_donate_app/data/models/church_message.dart';
import 'package:manna_donate_app/core/api_service.dart';
import 'package:dio/dio.dart';

class ChurchMessageService {
  final ApiService _apiService = ApiService();

  /// Get church messages for the authenticated user
  Future<ApiResponse<List<ChurchMessage>>> getChurchMessages({
    int limit = 50,
    int offset = 0,
    String? messageType,
  }) async {
    try {
      final response = await _apiService.get(
        '/mobile/church-messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (messageType != null) 'message_type': messageType,
        },
      );

      return ApiResponse.fromJson(response.data, (data) {
        final list = data['messages'] as List? ?? [];
        return list.map((json) => ChurchMessage.fromJson(json)).toList();
      });
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to fetch church messages: $e',
      );
    }
  }

  /// Send message from church admin to donors
  Future<ApiResponse<Map<String, dynamic>>> sendMessageToDonors({
    required int churchId,
    required String title,
    required String message,
    required String messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiService.post(
        '/mobile/church-admin/send-message',
        data: {
          'church_id': churchId,
          'title': title,
          'message': message,
          'message_type': messageType,
          if (metadata != null) 'metadata': metadata,
        },
      );

      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to send message to donors: $e',
      );
    }
  }

  /// Mark a message as read
  Future<ApiResponse<Map<String, dynamic>>> markMessageAsRead(
    int messageId,
  ) async {
    try {
      final response = await _apiService.post(
        '/mobile/church-messages/$messageId/read',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to mark message as read: $e',
      );
    }
  }

  /// Mark all messages as read
  Future<ApiResponse<Map<String, dynamic>>> markAllMessagesAsRead() async {
    try {
      final response = await _apiService.post(
        '/mobile/church-messages/read-all',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to mark all messages as read: $e',
      );
    }
  }

  /// Get unread message count
  Future<ApiResponse<Map<String, dynamic>>> getUnreadCount() async {
    try {
      final response = await _apiService.get(
        '/mobile/church-messages/unread-count',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      // Handle 500 errors gracefully by returning a default response
      if (e is DioException && e.response?.statusCode == 500) {
        return ApiResponse(
          success: true,
          data: {'unread_count': 0},
          message: 'Server error, using default unread count',
        );
      }
      return ApiResponse(
        success: false,
        message: 'Failed to get unread count: $e',
      );
    }
  }

  /// Delete a message
  Future<ApiResponse<Map<String, dynamic>>> deleteMessage(int messageId) async {
    try {
      final response = await _apiService.delete(
        '/mobile/church-messages/$messageId',
      );
      return ApiResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to delete message: $e',
      );
    }
  }
}
