

class DonationPreferences {
  final String frequency; // 'biweekly' or 'monthly'
  final String multiplier; // '1x' (No Roundup), '2x', '3x', or '5x'
  final int? churchId;
  final bool pause;
  final bool coverProcessingFees;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DonationPreferences({
    required this.frequency,
    required this.multiplier,
    this.churchId,
    this.pause = false,
    this.coverProcessingFees = false,
    this.createdAt,
    this.updatedAt,
  });

  factory DonationPreferences.fromJson(Map<String, dynamic> json) {
    // Handle church_id properly - convert 0 to null for internal consistency
    final churchIdValue = json['church_id'];
    final churchId = churchIdValue == 0 || churchIdValue == null ? null : churchIdValue;
    
    return DonationPreferences(
      frequency: json['frequency'] ?? 'biweekly',
      multiplier: json['multiplier'] ?? '1x',
      churchId: churchId,
      pause: json['pause'] ?? false,
      coverProcessingFees: json['cover_processing_fees'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'multiplier': multiplier,
      'church_id': churchId, // This will be null if no church is selected
      'pause': pause,
      'cover_processing_fees': coverProcessingFees,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  DonationPreferences copyWith({
    String? frequency,
    String? multiplier,
    int? churchId,
    bool? pause,
    bool? coverProcessingFees,
  }) {
    return DonationPreferences(
      frequency: frequency ?? this.frequency,
      multiplier: multiplier ?? this.multiplier,
      churchId: churchId ?? this.churchId,
      pause: pause ?? this.pause,
      coverProcessingFees: coverProcessingFees ?? this.coverProcessingFees,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Helper methods
  String get frequencyDisplay {
    switch (frequency.toLowerCase()) {
      case 'biweekly':
        return 'Every 2 weeks';
      case 'monthly':
        return 'Monthly';
      default:
        return frequency;
    }
  }

  String get multiplierDisplay {
    return multiplier.toUpperCase();
  }

  bool get isActive {
    return !pause;
  }
} 