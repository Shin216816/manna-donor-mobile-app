import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int userId;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String? phone;
  final List<int> churchIds;
  final int? primaryChurchId;
  final bool isEmailVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? profilePictureUrl;
  final String role;
  final String? accountType;
  final DateTime? lastLogin;
  final String? stripeCustomerId;
  final String? googleId;
  final String? appleId;
  final bool isPhoneVerified;

  const User({
    required this.userId,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    this.phone,
    this.churchIds = const [],
    this.primaryChurchId,
    required this.isEmailVerified,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.profilePictureUrl,
    required this.role,
    this.accountType,
    this.lastLogin,
    this.stripeCustomerId,
    this.googleId,
    this.appleId,
    this.isPhoneVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle church IDs from backend response - support both singular and plural
    List<int> churchIds = [];
    if (json['church_ids'] != null) {
      // Handle array of church IDs
      final churchIdsList = json['church_ids'] as List<dynamic>;
      churchIds = churchIdsList.map((id) => id as int).toList();
    } else if (json['church_id'] != null) {
      // Handle singular church ID (backward compatibility)
      churchIds = [json['church_id'] as int];
    }
    
    // Safely handle user ID - try multiple possible field names
    final userId = json['id'] ?? json['user_id'] ?? json['userId'];
    if (userId == null) {
      throw Exception('User ID is required but was null in the response');
    }

    return User(
      userId: userId as int,
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'],
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      churchIds: churchIds,
      primaryChurchId: churchIds.isNotEmpty ? churchIds.first : null,
      isEmailVerified: json['is_email_verified'] ?? false,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      profilePictureUrl: json['profile_picture_url'],
      role: json['role'] ?? 'user',
      accountType: json['account_type'],
      lastLogin: json['last_login'] != null ? DateTime.tryParse(json['last_login']) : null,
      stripeCustomerId: json['stripe_customer_id'],
      googleId: json['google_id'],
      appleId: json['apple_id'],
      isPhoneVerified: json['is_phone_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': userId,  // Add 'id' for API service compatibility
        'user_id': userId,
        'first_name': firstName,
        if (middleName != null) 'middle_name': middleName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'church_ids': churchIds,
        if (primaryChurchId != null) 'primary_church_id': primaryChurchId,
        'is_email_verified': isEmailVerified,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'role': role,
        'account_type': accountType,
        if (lastLogin != null) 'last_login': lastLogin!.toIso8601String(),
        if (stripeCustomerId != null) 'stripe_customer_id': stripeCustomerId,
        if (googleId != null) 'google_id': googleId,
        if (appleId != null) 'apple_id': appleId,
        'is_phone_verified': isPhoneVerified,
      };

  int get id => userId;
  String get name => (firstName + ' ' + lastName).trim();
  
  // Check if user is a church admin
  bool get isChurchAdmin => role == 'church_admin';
  
  // Check if user is a platform admin
  bool get isPlatformAdmin => role == 'platform_admin';

  /// Create a copy of this user with updated fields
  User copyWith({
    int? userId,
    String? firstName,
    String? middleName,
    String? lastName,
    String? email,
    String? phone,
    List<int>? churchIds,
    int? primaryChurchId,
    bool? isEmailVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? profilePictureUrl,
    String? role,
    String? accountType,
    DateTime? lastLogin,
    String? stripeCustomerId,
    String? googleId,
    String? appleId,
    bool? isPhoneVerified,
  }) {
    return User(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      churchIds: churchIds ?? this.churchIds,
      primaryChurchId: primaryChurchId ?? this.primaryChurchId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      accountType: accountType ?? this.accountType,
      lastLogin: lastLogin ?? this.lastLogin,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      googleId: googleId ?? this.googleId,
      appleId: appleId ?? this.appleId,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        firstName,
        middleName,
        lastName,
        email,
        phone,
        churchIds,
        primaryChurchId,
        isEmailVerified,
        isActive,
        createdAt,
        updatedAt,
        profilePictureUrl,
        role,
        accountType,
        lastLogin,
        stripeCustomerId,
        googleId,
        appleId,
        isPhoneVerified,
      ];
} 