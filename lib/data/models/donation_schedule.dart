class DonationSchedule {
  final int id;
  final int userId;
  final double amount;
  final String dayOfWeek;
  final String recipientId;
  final String status;
  final DateTime? nextRun;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DonationSchedule({
    required this.id,
    required this.userId,
    required this.amount,
    required this.dayOfWeek,
    required this.recipientId,
    required this.status,
    this.nextRun,
    required this.createdAt,
    this.updatedAt,
  });

  factory DonationSchedule.fromJson(Map<String, dynamic> json) {
    return DonationSchedule(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      amount: (json['amount'] as num).toDouble(),
      dayOfWeek: json['day_of_week'] as String,
      recipientId: json['recipient_id'] as String,
      status: json['status'] as String,
      nextRun: json['next_run'] != null 
          ? DateTime.parse(json['next_run'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'day_of_week': dayOfWeek,
      'recipient_id': recipientId,
      'status': status,
      'next_run': nextRun?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DonationSchedule copyWith({
    int? id,
    int? userId,
    double? amount,
    String? dayOfWeek,
    String? recipientId,
    String? status,
    DateTime? nextRun,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DonationSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      recipientId: recipientId ?? this.recipientId,
      status: status ?? this.status,
      nextRun: nextRun ?? this.nextRun,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DonationSchedule(id: $id, amount: $amount, dayOfWeek: $dayOfWeek, status: $status)';
  }
} 