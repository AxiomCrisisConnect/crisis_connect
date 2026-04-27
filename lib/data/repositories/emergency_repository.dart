import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_request.dart';
import '../models/assignment.dart';
import '../models/volunteer_profile.dart';

// TODO: Uncomment after Firebase setup:
// import 'package:cloud_firestore/cloud_firestore.dart';


// TODO: Replace all SharedPreferences mock storage with Firestore in production

class EmergencyRepository {
  // TODO: Use Firestore in production
  // final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  EmergencyRepository({required SharedPreferences prefs}) : _prefs = prefs;

  // ─── Create Emergency Request ─────────────────────────────────────────────────

  Future<EmergencyRequest> createEmergencyRequest(EmergencyRequest request) async {
    // TODO: await _firestore.collection(AppConstants.emergencyRequestsCollection).doc(request.id).set(request.toMap());
    // Cache locally for offline support
    final list = _prefs.getStringList('emergency_requests') ?? [];
    list.add(request.id);
    await _prefs.setStringList('emergency_requests', list);
    await _prefs.setString('emergency_${request.id}', _encodeRequest(request));
    return request;
  }

  Future<void> updateRequestStatus(String requestId, EmergencyStatus status) async {
    // TODO: await _firestore.collection(AppConstants.emergencyRequestsCollection).doc(requestId).update({'status': status.name});
    final encoded = _prefs.getString('emergency_$requestId');
    if (encoded != null) {
      final req = _decodeRequest(encoded);
      await _prefs.setString('emergency_$requestId', _encodeRequest(req.copyWith(status: status)));
    }
  }

  Future<EmergencyRequest?> getRequest(String id) async {
    // TODO: fetch from Firestore
    final encoded = _prefs.getString('emergency_$id');
    if (encoded == null) return null;
    return _decodeRequest(encoded);
  }

  Future<List<EmergencyRequest>> getCivilianRequests(String civilianId) async {
    // TODO: Query Firestore: _firestore.collection(AppConstants.emergencyRequestsCollection).where('civilian_id', isEqualTo: civilianId)
    final ids = _prefs.getStringList('emergency_requests') ?? [];
    final all = <EmergencyRequest>[];
    for (final id in ids) {
      final encoded = _prefs.getString('emergency_$id');
      if (encoded != null) {
        final req = _decodeRequest(encoded);
        if (req.civilianId == civilianId) all.add(req);
      }
    }
    return all..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // ─── Assignment Engine ────────────────────────────────────────────────────────

  /// Find nearest available volunteers filtered by required skills.
  /// Returns a sorted list (nearest first) of volunteer IDs.
  List<String> findNearestVolunteers({
    required List<VolunteerProfile> allVolunteers,
    required double lat,
    required double lng,
    required List<String> requiredSkillCategories,
    int limit = 3,
  }) {
    final eligible = allVolunteers.where((v) {
      if (!v.isAvailable) return false;
      if (v.lastLatitude == null || v.lastLongitude == null) return false;
      // Check if volunteer has ANY of the required skill categories
      return requiredSkillCategories.any((req) =>
          v.skills.any((skill) => skill.startsWith(req)));
    }).toList();

    eligible.sort((a, b) {
      final da = _haversineDistance(lat, lng, a.lastLatitude!, a.lastLongitude!);
      final db = _haversineDistance(lat, lng, b.lastLatitude!, b.lastLongitude!);
      return da.compareTo(db);
    });

    return eligible.take(limit).map((v) => v.userId).toList();
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  // ─── Assignments ──────────────────────────────────────────────────────────────

  Future<Assignment> createAssignment(Assignment assignment) async {
    // TODO: await _firestore.collection(AppConstants.assignmentsCollection).doc(assignment.id).set(assignment.toMap());
    await _prefs.setString('assignment_${assignment.id}', _encodeAssignment(assignment));
    final list = _prefs.getStringList('assignments') ?? [];
    list.add(assignment.id);
    await _prefs.setStringList('assignments', list);
    return assignment;
  }

  Future<void> updateAssignmentStatus(String id, AssignmentStatus status, {DateTime? resolvedAt}) async {
    // TODO: Firestore update
    final encoded = _prefs.getString('assignment_$id');
    if (encoded != null) {
      final a = _decodeAssignment(encoded);
      await _prefs.setString('assignment_$id', _encodeAssignment(a.copyWith(status: status, resolvedAt: resolvedAt)));
    }
  }

  Future<Assignment?> getActiveAssignmentForVolunteer(String volunteerId) async {
    // TODO: Firestore query
    final ids = _prefs.getStringList('assignments') ?? [];
    for (final id in ids) {
      final encoded = _prefs.getString('assignment_$id');
      if (encoded != null) {
        final a = _decodeAssignment(encoded);
        if (a.volunteerId == volunteerId &&
            (a.status == AssignmentStatus.pending || a.status == AssignmentStatus.accepted)) {
          return a;
        }
      }
    }
    return null;
  }

  Future<List<Assignment>> getAssignmentsForVolunteer(String volunteerId) async {
    // TODO: Firestore query
    final ids = _prefs.getStringList('assignments') ?? [];
    final result = <Assignment>[];
    for (final id in ids) {
      final encoded = _prefs.getString('assignment_$id');
      if (encoded != null) {
        final a = _decodeAssignment(encoded);
        if (a.volunteerId == volunteerId) result.add(a);
      }
    }
    return result..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
  }

  Future<List<Assignment>> getAssignmentsForCivilian(String civilianId) async {
    // TODO: Firestore query
    final ids = _prefs.getStringList('assignments') ?? [];
    final result = <Assignment>[];
    for (final id in ids) {
      final encoded = _prefs.getString('assignment_$id');
      if (encoded != null) {
        final a = _decodeAssignment(encoded);
        if (a.civilianId == civilianId) result.add(a);
      }
    }
    return result..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
  }

  Future<void> rateVolunteer(String assignmentId, int rating, String? comment) async {
    // TODO: Firestore update for volunteer rating
    final encoded = _prefs.getString('assignment_$assignmentId');
    if (encoded != null) {
      final a = _decodeAssignment(encoded);
      await _prefs.setString('assignment_$assignmentId',
          _encodeAssignment(a.copyWith(volunteerRating: rating, ratingComment: comment)));
    }
  }

  // ─── Mock Encoding ────────────────────────────────────────────────────────────

  String _encodeRequest(EmergencyRequest r) {
    return [
      r.id, r.type.name, r.priority.name, r.civilianId, r.civilianName,
      r.latitude, r.longitude, r.timestamp.millisecondsSinceEpoch,
      r.status.name, r.helpCategory?.name ?? '',
      r.description ?? '', r.assignedVolunteerIds.join(','),
    ].join('||');
  }

  EmergencyRequest _decodeRequest(String s) {
    final p = s.split('||');
    return EmergencyRequest(
      id: p[0], type: EmergencyType.values.firstWhere((e) => e.name == p[1]),
      priority: EmergencyPriority.values.firstWhere((e) => e.name == p[2]),
      civilianId: p[3], civilianName: p[4],
      latitude: double.parse(p[5]), longitude: double.parse(p[6]),
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(p[7])),
      status: EmergencyStatus.values.firstWhere((e) => e.name == p[8]),
      helpCategory: p[9].isEmpty ? null : HelpCategory.values.firstWhere((e) => e.name == p[9]),
      description: p[10].isEmpty ? null : p[10],
      assignedVolunteerIds: p[11].isEmpty ? [] : p[11].split(','),
    );
  }

  String _encodeAssignment(Assignment a) {
    return [
      a.id, a.emergencyRequestId, a.volunteerId, a.volunteerName,
      a.volunteerSkills.join(','), a.civilianId, a.civilianName,
      a.emergencyLatitude, a.emergencyLongitude,
      a.assignedAt.millisecondsSinceEpoch,
      a.resolvedAt?.millisecondsSinceEpoch ?? '',
      a.status.name, a.volunteerRating ?? '', a.ratingComment ?? '',
    ].join('||');
  }

  Assignment _decodeAssignment(String s) {
    final p = s.split('||');
    return Assignment(
      id: p[0], emergencyRequestId: p[1], volunteerId: p[2], volunteerName: p[3],
      volunteerSkills: p[4].isEmpty ? [] : p[4].split(','),
      civilianId: p[5], civilianName: p[6],
      emergencyLatitude: double.parse(p[7]), emergencyLongitude: double.parse(p[8]),
      assignedAt: DateTime.fromMillisecondsSinceEpoch(int.parse(p[9])),
      resolvedAt: p[10].isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(p[10])),
      status: AssignmentStatus.values.firstWhere((e) => e.name == p[11]),
      volunteerRating: p[12].isEmpty ? null : int.tryParse(p[12]),
      ratingComment: p[13].isEmpty ? null : p[13],
    );
  }
}
