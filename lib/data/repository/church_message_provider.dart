import 'package:flutter/material.dart';
import 'package:manna_donate_app/data/apiClient/church_message_service.dart';
import 'package:manna_donate_app/core/cache_manager.dart';

import 'package:manna_donate_app/data/models/church_message.dart';
import 'package:dio/dio.dart';

class ChurchMessageProvider extends ChangeNotifier {
  final ChurchMessageService _churchMessageService = ChurchMessageService();
  final CacheManager _cacheManager = CacheManager();

  List<ChurchMessage> _messages = [];
  int _unreadCount = 0;
  bool _loading = false;
  String? _error;

  // Getters
  List<ChurchMessage> get messages => _messages;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;
  String? get error => _error;

  // Setters
  void setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  // Computed properties
  List<ChurchMessage> get unreadMessages =>
      _messages.where((msg) => !msg.isRead).toList();
  List<ChurchMessage> get readMessages =>
      _messages.where((msg) => msg.isRead).toList();

  /// Fetch church messages (cache-first)
  Future<void> fetchMessages({String? messageType}) async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData(
      'church_messages',
    );
    if (cachedData != null) {
      _messages = List<ChurchMessage>.from(cachedData);
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, fetch from API
    await _fetchMessagesFromAPI(messageType: messageType);
  }

  /// Fetch church messages with cache and loading state
  Future<void> fetchMessagesWithLoading({String? messageType}) async {
    try {
      // Try to load from cache first
      final cachedData = await _cacheManager.smartGetCachedData(
        'church_messages',
      );
      if (cachedData != null) {
        try {
          final cachedMessages = List<ChurchMessage>.from(cachedData);
          // Only return early if we have valid cached data with actual messages
          if (cachedMessages.isNotEmpty) {
            _messages = cachedMessages;
            _error = null; // Clear any previous errors
            notifyListeners();
            return; // Return early if we have valid cached data
          }
        } catch (e) {
          // If parsing fails, invalidate cache and fetch fresh data
          await _cacheManager.invalidateCache('church_messages');
        }
      }

      // If no cache, empty cache, or parsing failed, show loading and fetch from API
      _loading = true;
      _error = null;
      notifyListeners();

      await _fetchMessagesFromAPI(messageType: messageType);

      // Ensure loading state is properly managed
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Failed to load messages: $e';
      _messages = [];
      notifyListeners();
    }
  }

  /// Refresh messages from server (bypass cache)
  Future<void> refreshMessages({String? messageType}) async {
    try {
      // Invalidate cache to force fresh data fetch
      await _cacheManager.invalidateCache('church_messages');

      // Fetch fresh data from API
      await _fetchMessagesFromAPI(messageType: messageType);
    } catch (e) {
      _error = 'Failed to refresh messages: $e';
      notifyListeners();
    }
  }

  /// Fetch messages from API (used when cache is invalid or data changes)
  Future<void> _fetchMessagesFromAPI({String? messageType}) async {
    // Note: Loading state is managed by the calling method (fetchMessagesWithLoading)
    // so we don't set it here to avoid conflicts

    try {
      final response = await _churchMessageService.getChurchMessages(
        messageType: messageType,
      );
      if (response.success && response.data != null) {
        _messages = response.data!;
        // Cache the fresh data
        await _cacheManager.cacheData('church_messages', response.data!);
        _error = null; // Clear any previous errors
      } else {
        _error = response.message;
        _messages = [];
      }
    } on DioException catch (e) {
      _error = 'Failed to fetch messages: ${e.message}';
      _messages = [];
    } catch (e) {
      _error = 'An unexpected error occurred';
      _messages = [];
    }

    // Note: Loading state is managed by the calling method
    notifyListeners();
  }

  /// Send message from church admin to donors
  Future<bool> sendMessageToDonors({
    required int churchId,
    required String title,
    required String message,
    required String messageType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _churchMessageService.sendMessageToDonors(
        churchId: churchId,
        title: title,
        message: message,
        messageType: messageType,
        metadata: metadata,
      );

      if (response.success) {
        // Invalidate cache since new message was sent
        await _cacheManager.invalidateOnDataChange('church_messages');
        // Fetch fresh data
        await _fetchMessagesFromAPI();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mark a message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      final response = await _churchMessageService.markMessageAsRead(messageId);
      if (response.success) {
        // Update local message
        final index = _messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          final message = _messages[index];
          _messages[index] = ChurchMessage(
            id: message.id,
            churchId: message.churchId,
            churchName: message.churchName,
            title: message.title,
            message: message.message,
            messageType: message.messageType,
            createdAt: message.createdAt,
            isRead: true,
            metadata: message.metadata,
          );
          _updateUnreadCount();
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle error - user can retry
    }
  }

  /// Mark all messages as read
  Future<void> markAllMessagesAsRead() async {
    try {
      final response = await _churchMessageService.markAllMessagesAsRead();
      if (response.success) {
        // Update all local messages
        _messages = _messages
            .map(
              (msg) => ChurchMessage(
                id: msg.id,
                churchId: msg.churchId,
                churchName: msg.churchName,
                title: msg.title,
                message: msg.message,
                messageType: msg.messageType,
                createdAt: msg.createdAt,
                isRead: true,
                metadata: msg.metadata,
              ),
            )
            .toList();
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      // Silently handle error - user can retry
    }
  }

  /// Fetch unread count (cache-first)
  Future<void> fetchUnreadCount() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData('unread_count');
    if (cachedData != null) {
      try {
        _unreadCount = cachedData as int;
        notifyListeners();
        return; // Return early if we have cached data
      } catch (e) {
        // If parsing fails, invalidate cache and fetch fresh data
        await _cacheManager.invalidateCache('unread_count');
      }
    }

    // If no cache or parsing failed, fetch from API
    await _fetchUnreadCountFromAPI();
  }

  /// Fetch unread count with cache and loading state
  Future<void> fetchUnreadCountWithLoading() async {
    // Try to load from cache first
    final cachedData = await _cacheManager.smartGetCachedData(
      'church_messages_unread_count',
    );
    if (cachedData != null) {
      _unreadCount = cachedData as int;
      notifyListeners();
      return; // Return early if we have cached data
    }

    // If no cache, show loading and fetch from API
    _loading = true;
    _error = null;
    notifyListeners();

    await _fetchUnreadCountFromAPI();

    // Ensure loading state is properly managed
    _loading = false;
    notifyListeners();
  }

  /// Fetch unread count from API (used when cache is invalid or data changes)
  Future<void> _fetchUnreadCountFromAPI() async {
    try {
      final response = await _churchMessageService.getUnreadCount();
      if (response.success && response.data != null) {
        _unreadCount = response.data!['unread_count'] ?? 0;
        // Cache the fresh data
        await _cacheManager.cacheData('unread_count', _unreadCount);
        notifyListeners();
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([fetchMessages(), fetchUnreadCount()]);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data in ChurchMessageProvider
  void clearAllData() {
    _messages = [];
    _unreadCount = 0;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  /// Refresh unread count (bypass cache)
  Future<void> refreshUnreadCount() async {
    await _fetchUnreadCountFromAPI();
  }

  /// Update unread count based on local messages
  void _updateUnreadCount() {
    _unreadCount = _messages.where((msg) => !msg.isRead).length;
  }

  /// Get messages by type
  List<ChurchMessage> getMessagesByType(String messageType) {
    return _messages.where((msg) => msg.messageType == messageType).toList();
  }

  /// Get messages from specific church
  List<ChurchMessage> getMessagesFromChurch(int churchId) {
    return _messages.where((msg) => msg.churchId == churchId).toList();
  }

  /// Get latest messages (last 5)
  List<ChurchMessage> get latestMessages {
    final sortedMessages = List<ChurchMessage>.from(_messages);
    sortedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedMessages.take(5).toList();
  }

  /// Delete a message
  Future<void> deleteMessage(int messageId) async {
    try {
      final response = await _churchMessageService.deleteMessage(messageId);
      if (response.success) {
        _messages.removeWhere((msg) => msg.id == messageId);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      // Silently handle error - user can retry
    }
  }
}
