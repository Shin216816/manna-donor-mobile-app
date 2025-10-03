class DonationItem {
  final String id;
  final double amount;
  final DateTime date;
  final String churchName;
  final String category;

  DonationItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.churchName,
    required this.category,
  });

  factory DonationItem.fromJson(Map<String, dynamic> json) {
    return DonationItem(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      churchName: json['church_name'] ?? 'Unknown Church',
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'church_name': churchName,
      'category': category,
    };
  }
} 