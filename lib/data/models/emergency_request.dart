import 'package:cloud_firestore/cloud_firestore.dart';
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
    final isNewSchema = map.containsKey('location') || map.containsKey('emergency_id');
    if (isNewSchema) {
      final loc = map['location'] as Map<String, dynamic>?;
      final lat = (loc?['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (loc?['lng'] as num?)?.toDouble() ?? 0.0;
      final type = _parseType(map['type']);
      final category = _categoryFromSchema(map['category']);
      return EmergencyRequest(
        id: (map['emergency_id'] ?? map['id']) as String,
        type: type,
        priority: _parsePriority(map['priority']),
        civilianId: (map['civilian_id'] ?? '') as String,
        civilianName: (map['civilian_name'] ?? 'Unknown') as String,
        latitude: lat,
        longitude: lng,
        timestamp: _parseTimestamp(map['created_at']),
        status: _parseStatus(map['status']),
        helpCategory: type == EmergencyType.help ? category : null,
        description: (map['description'] as String?)?.trim().isEmpty == true
            ? null
            : map['description'] as String?,
        assignedVolunteerIds: const [],
      );
    }
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
      timestamp: _parseTimestamp(map['timestamp']),
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
      'emergency_id': id,
      'type': type == EmergencyType.sos ? 'SOS' : 'HELP',
      'priority': priority == EmergencyPriority.high ? 'high' : 'low',
      'civilian_id': civilianId,
      'category': _categoryToSchema(type, helpCategory),
      'description': description ?? '',
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'status': _statusToSchema(status),
      'created_at': Timestamp.fromDate(timestamp),
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

EmergencyType _parseType(dynamic value) {
  final v = value?.toString().toLowerCase() ?? '';
  if (v == 'sos') return EmergencyType.sos;
  if (v == 'help') return EmergencyType.help;
  return EmergencyType.help;
}

EmergencyPriority _parsePriority(dynamic value) {
  final v = value?.toString().toLowerCase() ?? '';
  return v == 'high' ? EmergencyPriority.high : EmergencyPriority.low;
}

EmergencyStatus _parseStatus(dynamic value) {
  final v = value?.toString().toLowerCase() ?? '';
  return switch (v) {
    'assigned' => EmergencyStatus.assigned,
    'resolved' => EmergencyStatus.resolved,
    'cancelled' => EmergencyStatus.cancelled,
    _ => EmergencyStatus.active,
  };
}

HelpCategory? _categoryFromSchema(dynamic value) {
  final v = value?.toString().toLowerCase() ?? '';
  return switch (v) {
    'medical' => HelpCategory.medical,
    'food' => HelpCategory.food,
    'engineering' => HelpCategory.engineering,
    'other' => HelpCategory.other,
    _ => HelpCategory.other,
  };
}

String _categoryToSchema(EmergencyType type, HelpCategory? category) {
  if (type == EmergencyType.sos) return 'Other';
  return switch (category) {
    HelpCategory.medical => 'Medical',
    HelpCategory.food => 'Food',
    HelpCategory.engineering => 'Engineering',
    _ => 'Other',
  };
}

String _statusToSchema(EmergencyStatus status) {
  return switch (status) {
    EmergencyStatus.active => 'active',
    EmergencyStatus.assigned => 'assigned',
    EmergencyStatus.resolved => 'resolved',
    EmergencyStatus.cancelled => 'cancelled',
  };
}

DateTime _parseTimestamp(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}
