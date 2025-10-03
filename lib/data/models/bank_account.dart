

class BankAccount {
  final int id;
  final int userId;
  final String accountId;
  final String name;
  final String mask;
  final String subtype;
  final String type;
  final String institution;
  final String accessToken;
  final DateTime createdAt;
  final bool isLinked;

  BankAccount({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.name,
    required this.mask,
    required this.subtype,
    required this.type,
    required this.institution,
    required this.accessToken,
    required this.createdAt,
    this.isLinked = true,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      accountId: json['account_id'] ?? '',
      name: json['name'] ?? '',
      mask: json['mask'] ?? '',
      subtype: json['subtype'] ?? '',
      type: json['type'] ?? '',
      institution: json['institution'] ?? '',
      accessToken: json['access_token'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isLinked: json['is_linked'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'name': name,
      'mask': mask,
      'subtype': subtype,
      'type': type,
      'institution': institution,
      'access_token': accessToken,
      'created_at': createdAt.toIso8601String(),
      'is_linked': isLinked,
    };
  }

  String get accountTypeDisplay {
    switch (type.toLowerCase()) {
      case 'depository':
        return 'Bank Account';
      case 'credit':
        return 'Credit Card';
      case 'loan':
        return 'Loan';
      case 'investment':
        return 'Investment';
      default:
        return type;
    }
  }

  String get displayName {
    return name.isNotEmpty ? name : '$institution Account';
  }

  String get institutionName {
    return institution.isNotEmpty ? institution : 'Unknown Bank';
  }

  String get maskedAccountNumber {
    if (mask.isNotEmpty) {
      return '••••$mask';
    }
    return '••••••••';
  }
} 