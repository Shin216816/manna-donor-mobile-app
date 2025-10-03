import 'package:equatable/equatable.dart';

class Church extends Equatable {
  final int id;
  final String name;
  final String address;
  final String? city;
  final String? state;
  final String? email;
  final String? phone;
  final String? website;
  final String? kycStatus;
  final bool isActive;
  final bool isVerified;
  final String? type;
  final DateTime? createdAt;

  const Church({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.state,
    this.email,
    this.phone,
    this.website,
    this.kycStatus,
    this.isActive = true,
    this.isVerified = false,
    this.type,
    this.createdAt,
  });

  factory Church.fromJson(Map<String, dynamic> json) => Church(
        id: json['id'] ?? json['church_id'] ?? 0,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        website: json['website'] ?? '',
        kycStatus: json['kyc_status'] ?? 'not_submitted',
        isActive: json['is_active'] ?? true,
        isVerified: json['is_verified'] ?? false,
        type: json['type'] ?? 'church',
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city ?? '',
        'state': state ?? '',
        'email': email ?? '',
        'phone': phone ?? '',
        'website': website ?? '',
        'kyc_status': kycStatus ?? 'not_submitted',
        'is_active': isActive,
        'is_verified': isVerified,
        'type': type ?? 'church',
        'created_at': createdAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        city,
        state,
        email,
        phone,
        website,
        kycStatus,
        isActive,
        isVerified,
        type,
        createdAt,
      ];
} 