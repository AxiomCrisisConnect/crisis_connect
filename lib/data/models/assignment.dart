import 'package:equatable/equatable.dart';

enum AssignmentStatus { pending, accepted, declined, resolved, cancelled }

class Assignment extends Equatable {
  final String id;
  final String emergencyRequestId;
  final String volunteerId;
  final String volunteerName;
  final List<String> volunteerSkills;
  final String civilianId;
  final String civilianName;
  final double emergencyLatitude;
  final double emergencyLongitude;
  final DateTime assignedAt;
  final DateTime? resolvedAt;
  final AssignmentStatus status;
  final int? volunteerRating; // 1-5 stars, nullable
  final String? ratingComment;

  const Assignment({
    required this.id,
    required this.emergencyRequestId,
    required this.volunteerId,
    required this.volunteerName,
    required this.volunteerSkills,
    required this.civilianId,
    required this.civilianName,
    required this.emergencyLatitude,
    required this.emergencyLongitude,
    required this.assignedAt,
    this.resolvedAt,
    required this.status,
    this.volunteerRating,
    this.ratingComment,
  });

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      id: map['id'] as String,
      emergencyRequestId: map['emergency_request_id'] as String,
      volunteerId: map['volunteer_id'] as String,
      volunteerName: map['volunteer_name'] as String? ?? 'Volunteer',
      volunteerSkills: List<String>.from(map['volunteer_skills'] ?? []),
      civilianId: map['civilian_id'] as String,
      civilianName: map['civilian_name'] as String? ?? 'Civilian',
      emergencyLatitude: (map['emergency_latitude'] as num).toDouble(),
      emergencyLongitude: (map['emergency_longitude'] as num).toDouble(),
      assignedAt: DateTime.fromMillisecondsSinceEpoch(map['assigned_at'] as int),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['resolved_at'] as int)
          : null,
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AssignmentStatus.pending,
      ),
      volunteerRating: map['volunteer_rating'] as int?,
      ratingComment: map['rating_comment'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emergency_request_id': emergencyRequestId,
      'volunteer_id': volunteerId,
      'volunteer_name': volunteerName,
      'volunteer_skills': volunteerSkills,
      'civilian_id': civilianId,
      'civilian_name': civilianName,
      'emergency_latitude': emergencyLatitude,
      'emergency_longitude': emergencyLongitude,
      'assigned_at': assignedAt.millisecondsSinceEpoch,
      'resolved_at': resolvedAt?.millisecondsSinceEpoch,
      'status': status.name,
      'volunteer_rating': volunteerRating,
      'rating_comment': ratingComment,
    };
  }

  Assignment copyWith({
    String? id,
    String? emergencyRequestId,
    String? volunteerId,
    String? volunteerName,
    List<String>? volunteerSkills,
    String? civilianId,
    String? civilianName,
    double? emergencyLatitude,
    double? emergencyLongitude,
    DateTime? assignedAt,
    DateTime? resolvedAt,
    AssignmentStatus? status,
    int? volunteerRating,
    String? ratingComment,
  }) {
    return Assignment(
      id: id ?? this.id,
      emergencyRequestId: emergencyRequestId ?? this.emergencyRequestId,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerSkills: volunteerSkills ?? this.volunteerSkills,
      civilianId: civilianId ?? this.civilianId,
      civilianName: civilianName ?? this.civilianName,
      emergencyLatitude: emergencyLatitude ?? this.emergencyLatitude,
      emergencyLongitude: emergencyLongitude ?? this.emergencyLongitude,
      assignedAt: assignedAt ?? this.assignedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      status: status ?? this.status,
      volunteerRating: volunteerRating ?? this.volunteerRating,
      ratingComment: ratingComment ?? this.ratingComment,
    );
  }

  @override
  List<Object?> get props => [
        id,
        emergencyRequestId,
        volunteerId,
        civilianId,
        assignedAt,
        status,
      ];
}
