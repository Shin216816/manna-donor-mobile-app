import 'package:flutter/material.dart';

class RoundupStatus {
  final double accumulatedRoundups;
  final double thisMonthRoundups;
  final double lastMonthRoundups;
  final int totalTransactions;
  final DateTime nextTransferDate;
  final String transferFrequency; // 'weekly', 'biweekly', 'monthly'
  final double estimatedNextTransfer;
  final bool isTransferScheduled;
  final Map<String, dynamic>? metadata;

  RoundupStatus({
    required this.accumulatedRoundups,
    required this.thisMonthRoundups,
    required this.lastMonthRoundups,
    required this.totalTransactions,
    required this.nextTransferDate,
    required this.transferFrequency,
    required this.estimatedNextTransfer,
    required this.isTransferScheduled,
    this.metadata,
  });

  factory RoundupStatus.fromJson(Map<String, dynamic> json) {
    return RoundupStatus(
      accumulatedRoundups: (json['accumulated_roundups'] ?? 0.0).toDouble(),
      thisMonthRoundups: (json['this_month_roundups'] ?? 0.0).toDouble(),
      lastMonthRoundups: (json['last_month_roundups'] ?? 0.0).toDouble(),
      totalTransactions: json['total_transactions'] ?? 0,
      nextTransferDate: DateTime.tryParse(json['next_transfer_date'] ?? '') ?? DateTime.now(),
      transferFrequency: json['transfer_frequency'] ?? 'weekly',
      estimatedNextTransfer: (json['estimated_next_transfer'] ?? 0.0).toDouble(),
      isTransferScheduled: json['is_transfer_scheduled'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'accumulated_roundups': accumulatedRoundups,
    'this_month_roundups': thisMonthRoundups,
    'last_month_roundups': lastMonthRoundups,
    'total_transactions': totalTransactions,
    'next_transfer_date': nextTransferDate.toIso8601String(),
    'transfer_frequency': transferFrequency,
    'estimated_next_transfer': estimatedNextTransfer,
    'is_transfer_scheduled': isTransferScheduled,
    if (metadata != null) 'metadata': metadata,
  };

  String get transferFrequencyDisplay {
    switch (transferFrequency) {
      case 'weekly':
        return 'Weekly';
      case 'biweekly':
        return 'Bi-weekly';
      case 'monthly':
        return 'Monthly';
      default:
        return 'Weekly';
    }
  }

  String get nextTransferDateDisplay {
    final now = DateTime.now();
    final difference = nextTransferDate.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else if (difference.inDays < 14) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''}';
    } else {
      return '${(difference.inDays / 7).floor()} weeks';
    }
  }

  bool get isTransferReady => accumulatedRoundups >= 1.0;

  String get statusMessage {
    if (isTransferReady) {
      return 'Ready for transfer';
    } else {
      final remaining = 1.0 - accumulatedRoundups;
      return 'Need \$${remaining.toStringAsFixed(2)} more for transfer';
    }
  }

  Color get statusColor {
    if (isTransferReady) {
      return Colors.green;
    } else if (accumulatedRoundups >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }
} 