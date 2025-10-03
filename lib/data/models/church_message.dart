import 'package:flutter/material.dart';

class ChurchMessage {
  final int id;
  final int churchId;
  final String churchName;
  final String title;
  final String message;
  final String messageType; // 'thank_you', 'impact_update', 'receipt', 'general'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata; // For additional data like donation amount, etc.

  ChurchMessage({
    required this.id,
    required this.churchId,
    required this.churchName,
    required this.title,
    required this.message,
    required this.messageType,
    required this.createdAt,
    required this.isRead,
    this.metadata,
  });

  factory ChurchMessage.fromJson(Map<String, dynamic> json) {
    return ChurchMessage(
      id: json['id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      churchName: json['church_name'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'general',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'church_id': churchId,
    'church_name': churchName,
    'title': title,
    'message': message,
    'message_type': messageType,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    if (metadata != null) 'metadata': metadata,
  };

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  String get messageTypeDisplay {
    switch (messageType) {
      case 'thank_you':
        return 'Thank You';
      case 'impact_update':
        return 'Impact Update';
      case 'receipt':
        return 'Donation Receipt';
      case 'general':
      default:
        return 'Message';
    }
  }

  IconData get messageTypeIcon {
    switch (messageType) {
      case 'thank_you':
        return Icons.favorite;
      case 'impact_update':
        return Icons.trending_up;
      case 'receipt':
        return Icons.receipt;
      case 'general':
      default:
        return Icons.message;
    }
  }

  Color get messageTypeColor {
    switch (messageType) {
      case 'thank_you':
        return Colors.green;
      case 'impact_update':
        return Colors.blue;
      case 'receipt':
        return Colors.orange;
      case 'general':
      default:
        return Colors.grey;
    }
  }
} 