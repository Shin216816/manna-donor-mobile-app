class DonationHistory {
  final int id;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? executedAt;
  final int? churchId;
  final String? churchName;
  final String? stripeChargeId; // Added to match API response

  DonationHistory({
    required this.id,
    required this.amount,
    required this.status,
    this.createdAt,
    this.executedAt,
    this.churchId,
    this.churchName,
    this.stripeChargeId,
  });

  factory DonationHistory.fromJson(Map<String, dynamic> json) {
    return DonationHistory(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'unknown',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      executedAt: json['date'] != null ? DateTime.tryParse(json['date']) : null, // Backend returns 'date'
      churchId: json['church_id'],
      churchName: json['church_name'],
      stripeChargeId: json['stripe_charge_id'], // Added to match API response
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'executed_at': executedAt?.toIso8601String(),
      'church_id': churchId,
      'church_name': churchName,
      'stripe_charge_id': stripeChargeId,
    };
  }

  // Helper methods
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'processing':
        return 'Processing';
      default:
        return status;
    }
  }

  String get formattedAmount {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    if (executedAt != null) {
      return executedAt!.toLocal().toString().split(' ')[0];
    } else if (createdAt != null) {
      return createdAt!.toLocal().toString().split(' ')[0];
    }
    return 'Unknown';
  }

  DateTime get date {
    return executedAt ?? createdAt ?? DateTime.now();
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  
  /// Get formatted Stripe charge ID for display
  String get formattedStripeChargeId {
    if (stripeChargeId == null || stripeChargeId!.isEmpty) {
      return 'N/A';
    }
    // Show last 4 characters for privacy
    return '***${stripeChargeId!.substring(stripeChargeId!.length - 4)}';
  }
  
  /// Check if this donation has a Stripe charge ID
  bool get hasStripeChargeId => stripeChargeId != null && stripeChargeId!.isNotEmpty;
} 