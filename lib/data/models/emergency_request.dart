import 'package:equatable/equatable.dart';

enum EmergencyType { sos, help }
enum EmergencyPriority { high, low }
enum EmergencyStatus { active, assigned, resolved, cancelled }

enum HelpCategory {
  medical,
  engineering,
  food,
  mentalHealth,
  communication,
  other,
}

extension HelpCategoryX on HelpCategory {
  String get label {
    switch (this) {
      case HelpCategory.medical:
        return 'Medical Assistance';
      case HelpCategory.engineering:
        return 'Engineering / Structural Help';
      case HelpCategory.food:
        return 'Food & Supplies';
      case HelpCategory.mentalHealth:
        return 'Mental Health Support';
      case HelpCategory.communication:
        return 'Communication Help';
      case HelpCategory.other:
        return 'Other';
    }
  }

  /// Maps help category to volunteer skill categories for matching
  String get matchingSkill {
    switch (this) {
      case HelpCategory.medical:
        return 'Medical';
      case HelpCategory.engineering:
        return 'Engineering';
      case HelpCategory.food:
        return 'Food & Logistics';
      case HelpCategory.mentalHealth:
        return 'Mental Health Support';
      case HelpCategory.communication:
        return 'Communication & Coordination';
      case HelpCategory.other:
        return 'Rescue';
    }
  }
}

class EmergencyRequest extends Equatable {
  final String id;
  final EmergencyType type;
  final EmergencyPriority priority;
  final String civilianId;
  final String civilianName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final EmergencyStatus status;
  final HelpCategory? helpCategory;
  final String? description;
  final List<String> assignedVolunteerIds;

  const EmergencyRequest({
    required this.id,
    required this.type,
    required this.priority,
    required this.civilianId,
    required this.civilianName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    this.helpCategory,
    this.description,
    this.assignedVolunteerIds = const [],
  });

  factory EmergencyRequest.fromMap(Map<String, dynamic> map) {
    return EmergencyRequest(
      id: map['id'] as String,
      type: EmergencyType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => EmergencyType.help,
      ),
      priority: EmergencyPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => EmergencyPriority.low,
      ),
      civilianId: map['civilian_id'] as String,
      civilianName: map['civilian_name'] as String? ?? 'Unknown',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => EmergencyStatus.active,
      ),
      helpCategory: map['help_category'] != null
          ? HelpCategory.values.firstWhere(
              (e) => e.name == map['help_category'],
              orElse: () => HelpCategory.other,
            )
          : null,
      description: map['description'] as String?,
      assignedVolunteerIds:
          List<String>.from(map['assigned_volunteer_ids'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'civilian_id': civilianId,
      'civilian_name': civilianName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
      'help_category': helpCategory?.name,
      'description': description,
      'assigned_volunteer_ids': assignedVolunteerIds,
    };
  }

  EmergencyRequest copyWith({
    String? id,
    EmergencyType? type,
    EmergencyPriority? priority,
    String? civilianId,
    String? civilianName,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    EmergencyStatus? status,
    HelpCategory? helpCategory,
    String? description,
    List<String>? assignedVolunteerIds,
  }) {
    return EmergencyRequest(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      civilianId: civilianId ?? this.civilianId,
      civilianName: civilianName ?? this.civilianName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      helpCategory: helpCategory ?? this.helpCategory,
      description: description ?? this.description,
      assignedVolunteerIds: assignedVolunteerIds ?? this.assignedVolunteerIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        priority,
        civilianId,
        latitude,
        longitude,
        timestamp,
        status,
        helpCategory,
        description,
        assignedVolunteerIds,
      ];
}
