import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String type;
  final String? customerId;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? billingDetails;
  final Map<String, dynamic>? card;
  final Map<String, dynamic>? bankAccount;
  final Map<String, dynamic>? metadata;

  const PaymentMethod({
    required this.id,
    required this.type,
    this.customerId,
    required this.isDefault,
    required this.createdAt,
    this.updatedAt,
    this.billingDetails,
    this.card,
    this.bankAccount,
    this.metadata,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    // Handle different date formats from backend
    DateTime? parseCreatedDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is int) {
        // Convert Unix timestamp to DateTime
        return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      } else if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      return null;
    }

    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      customerId: json['customer_id']?.toString(),
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      createdAt: parseCreatedDate(json['created_at'] ?? json['created']) ?? DateTime.now(),
      updatedAt: parseCreatedDate(json['updated_at']),
      billingDetails: json['billing_details'],
      card: json['card'],
      bankAccount: json['bank_account'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    if (customerId != null) 'customer_id': customerId,
    'is_default': isDefault,
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    if (billingDetails != null) 'billing_details': billingDetails,
    if (card != null) 'card': card,
    if (bankAccount != null) 'bank_account': bankAccount,
    if (metadata != null) 'metadata': metadata,
  };

  // Helper getters for common card information
  String? get cardBrand => card?['brand'];
  String? get cardLast4 => card?['last4'];
  int? get cardExpMonth => card?['exp_month'];
  int? get cardExpYear => card?['exp_year'];
  String? get cardFingerprint => card?['fingerprint'];

  // Helper getters for billing details
  String? get billingName => billingDetails?['name'];
  String? get billingEmail => billingDetails?['email'];
  String? get billingPhone => billingDetails?['phone'];
  Map<String, dynamic>? get billingAddress => billingDetails?['address'];

  // Helper getters for bank account information
  String? get bankName => bankAccount?['bank_name'];
  String? get bankLast4 => bankAccount?['last4'];
  String? get bankAccountType => bankAccount?['account_type'];
  String? get bankRoutingNumber => bankAccount?['routing_number'];

  // Display name for UI
  String get displayName {
    switch (type) {
      case 'card':
        final brand = cardBrand ?? 'Card';
        final last4 = cardLast4 ?? '';
        return '$brand •••• $last4';
      case 'bank_account':
        final bank = bankName ?? 'Bank';
        final last4 = bankLast4 ?? '';
        return '$bank •••• $last4';
      default:
        return type.toUpperCase();
    }
  }

  // Short display name
  String get shortDisplayName {
    switch (type) {
      case 'card':
        final brand = cardBrand ?? 'Card';
        final last4 = cardLast4 ?? '';
        return '$brand $last4';
      case 'bank_account':
        final bank = bankName ?? 'Bank';
        final last4 = bankLast4 ?? '';
        return '$bank $last4';
      default:
        return type.toUpperCase();
    }
  }

  // Check if payment method is expired
  bool get isExpired {
    if (type == 'card' && cardExpYear != null && cardExpMonth != null) {
      final now = DateTime.now();
      final expYear = cardExpYear!;
      final expMonth = cardExpMonth!;
      
      if (now.year > expYear) return true;
      if (now.year == expYear && now.month > expMonth) return true;
    }
    return false;
  }

  // Check if payment method is valid
  bool get isValid {
    if (type == 'card') {
      return !isExpired && cardLast4 != null && cardBrand != null;
    } else if (type == 'bank_account') {
      return bankLast4 != null && bankName != null;
    }
    return true;
  }

  PaymentMethod copyWith({
    String? id,
    String? type,
    String? customerId,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? billingDetails,
    Map<String, dynamic>? card,
    Map<String, dynamic>? bankAccount,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billingDetails: billingDetails ?? this.billingDetails,
      card: card ?? this.card,
      bankAccount: bankAccount ?? this.bankAccount,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    customerId,
    isDefault,
    createdAt,
    updatedAt,
    billingDetails,
    card,
    bankAccount,
    metadata,
  ];
} 