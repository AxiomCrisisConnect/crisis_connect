import 'package:equatable/equatable.dart';

enum ExperienceLevel { student, junior, senior, expert }

class SkillCategory {
  static const Map<String, List<String>> categories = {
    'Medical': ['Doctor', 'Nurse', 'Paramedic', 'Pharmacist'],
    'Rescue': [],
    'Engineering': ['Civil', 'Electrical', 'Plumbing'],
    'Food & Logistics': [],
    'Mental Health Support': [],
    'Communication & Coordination': [],
  };

  static List<String> get topLevel => categories.keys.toList();

  static List<String> subcategoriesFor(String category) =>
      categories[category] ?? [];

  static bool hasSubcategories(String category) =>
      (categories[category] ?? []).isNotEmpty;
}

class VolunteerProfile extends Equatable {
  final String userId;
  final List<String> skills; // e.g. ['Medical:Doctor', 'Rescue', 'Engineering:Civil']
  final ExperienceLevel experienceLevel;
  final String? licenseUrl;
  final bool isAvailable;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? locationUpdatedAt;
  final bool onboardingComplete;

  const VolunteerProfile({
    required this.userId,
    required this.skills,
    required this.experienceLevel,
    this.licenseUrl,
    this.isAvailable = false,
    this.lastLatitude,
    this.lastLongitude,
    this.locationUpdatedAt,
    this.onboardingComplete = false,
  });

  factory VolunteerProfile.fromMap(Map<String, dynamic> map) {
    return VolunteerProfile(
      userId: map['user_id'] as String,
      skills: List<String>.from(map['skills'] ?? []),
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == map['experience_level'],
        orElse: () => ExperienceLevel.student,
      ),
      licenseUrl: map['license_url'] as String?,
      isAvailable: map['is_available'] as bool? ?? false,
      lastLatitude: (map['last_latitude'] as num?)?.toDouble(),
      lastLongitude: (map['last_longitude'] as num?)?.toDouble(),
      locationUpdatedAt: map['location_updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['location_updated_at'] as int)
          : null,
      onboardingComplete: map['onboarding_complete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'skills': skills,
      'experience_level': experienceLevel.name,
      'license_url': licenseUrl,
      'is_available': isAvailable,
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'location_updated_at': locationUpdatedAt?.millisecondsSinceEpoch,
      'onboarding_complete': onboardingComplete,
    };
  }

  VolunteerProfile copyWith({
    String? userId,
    List<String>? skills,
    ExperienceLevel? experienceLevel,
    String? licenseUrl,
    bool? isAvailable,
    double? lastLatitude,
    double? lastLongitude,
    DateTime? locationUpdatedAt,
    bool? onboardingComplete,
  }) {
    return VolunteerProfile(
      userId: userId ?? this.userId,
      skills: skills ?? this.skills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      lastLatitude: lastLatitude ?? this.lastLatitude,
      lastLongitude: lastLongitude ?? this.lastLongitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  String get experienceLevelLabel {
    switch (experienceLevel) {
      case ExperienceLevel.student:
        return 'Student';
      case ExperienceLevel.junior:
        return '1–5 Years (Practising)';
      case ExperienceLevel.senior:
        return '5–10 Years (Senior)';
      case ExperienceLevel.expert:
        return '10+ Years (Expert)';
    }
  }

  @override
  List<Object?> get props => [
        userId,
        skills,
        experienceLevel,
        licenseUrl,
        isAvailable,
        lastLatitude,
        lastLongitude,
        locationUpdatedAt,
        onboardingComplete,
      ];
}
