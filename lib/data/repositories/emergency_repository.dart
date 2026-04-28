import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency_request.dart';
import '../models/assignment.dart';
import '../models/volunteer_profile.dart';
import '../../core/constants/app_constants.dart';

class EmergencyRepository {
  final FirebaseFirestore _firestore;

  EmergencyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _emergencies =>
      _firestore.collection(AppConstants.emergencyRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _assignments =>
      _firestore.collection(AppConstants.assignmentsCollection);

  // ─── Create Emergency Request ─────────────────────────────────────────────

  Future<EmergencyRequest> createEmergencyRequest(
      EmergencyRequest request) async {
    final data = _requestToFirestore(request);
    await _emergencies.doc(request.id).set(data);
    return request;
  }

  Future<void> updateRequestStatus(
      String requestId, EmergencyStatus status) async {
    await _emergencies.doc(requestId).update({
      'status': _statusToSchema(status),
    });
  }

  Future<EmergencyRequest?> getRequest(String id) async {
    final doc = await _emergencies.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    data.putIfAbsent('emergency_id', () => doc.id);
    return EmergencyRequest.fromMap(data);
  }

  Future<List<EmergencyRequest>> getCivilianRequests(
      String civilianId) async {
    // Fetch all requests for this civilian without orderBy to avoid needing a
    // composite index, then sort locally.
    final snap = await _emergencies
        .where('civilian_id', isEqualTo: civilianId)
        .get();
        
    final requests = snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data.putIfAbsent('emergency_id', () => doc.id);
      return EmergencyRequest.fromMap(data);
    }).toList();
    
    // Sort descending by timestamp
    requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return requests;
  }

  /// Returns the most recent active or assigned request for this civilian,
  /// or null if none exists. Used to enforce one active request at a time
  /// and to populate the live status card on the home screen.
  Future<EmergencyRequest?> getActiveCivilianRequest(
      String civilianId) async {
    // Fetch all requests for this civilian without orderBy or multiple where 
    // clauses to avoid needing a composite index in Firestore.
    final snap = await _emergencies
        .where('civilian_id', isEqualTo: civilianId)
        .get();
        
    final docs = snap.docs.where((doc) {
      final s = doc.data()['status']?.toString().toLowerCase();
      return s == 'active' || s == 'assigned';
    }).toList();
    
    if (docs.isEmpty) return null;
    
    final requests = docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data.putIfAbsent('emergency_id', () => doc.id);
      return EmergencyRequest.fromMap(data);
    }).toList();
    
    // Sort descending by timestamp and return the most recent one
    requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return requests.first;
  }

  // ─── Assignment Engine ────────────────────────────────────────────────────

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
      return requiredSkillCategories.any(
          (req) => v.skills.any((skill) => skill.startsWith(req)));
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

  // ─── Assignments ─────────────────────────────────────────────────────────

  Future<Assignment> createAssignment(Assignment assignment) async {
    await _assignments.doc(assignment.id).set(assignment.toMap());
    return assignment;
  }

  Future<void> updateAssignmentStatus(
      String id, AssignmentStatus status,
      {DateTime? resolvedAt}) async {
    final data = <String, dynamic>{
      'status': status.name,
    };
    if (resolvedAt != null) {
      data['resolved_at'] = Timestamp.fromDate(resolvedAt);
    }
    await _assignments.doc(id).update(data);
  }

  Future<Assignment?> getActiveAssignmentForVolunteer(String volunteerId) async {
    final snap = await _assignments
        .where('volunteer_id', isEqualTo: volunteerId)
        .where('status', whereIn: [
          AssignmentStatus.pending.name,
          AssignmentStatus.accepted.name,
        ])
        .orderBy('assigned_at', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final data = Map<String, dynamic>.from(snap.docs.first.data());
    data.putIfAbsent('id', () => snap.docs.first.id);
    return Assignment.fromMap(data);
  }

  Future<List<Assignment>> getAssignmentsForVolunteer(String volunteerId) async {
    final snap = await _assignments
        .where('volunteer_id', isEqualTo: volunteerId)
        .orderBy('assigned_at', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data.putIfAbsent('id', () => doc.id);
      return Assignment.fromMap(data);
    }).toList();
  }

  Future<List<Assignment>> getAssignmentsForCivilian(String civilianId) async {
    final snap = await _assignments
        .where('civilian_id', isEqualTo: civilianId)
        .orderBy('assigned_at', descending: true)
        .get();
    return snap.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      data.putIfAbsent('id', () => doc.id);
      return Assignment.fromMap(data);
    }).toList();
  }

  Future<void> rateVolunteer(
      String assignmentId, int rating, String? comment) async {
    await _assignments.doc(assignmentId).update({
      'volunteer_rating': rating,
      'rating_comment': comment,
    });
  }

  Map<String, dynamic> _requestToFirestore(EmergencyRequest r) {
    return {
      'emergency_id': r.id,
      'type': r.type == EmergencyType.sos ? 'SOS' : 'HELP',
      'priority': r.priority == EmergencyPriority.high ? 'high' : 'low',
      'civilian_id': r.civilianId,
      'category': _categoryToSchema(r.type, r.helpCategory),
      'description': r.description ?? '',
      'location': {
        'lat': r.latitude,
        'lng': r.longitude,
        'geohash': _encodeGeohash(r.latitude, r.longitude),
      },
      'status': _statusToSchema(r.status),
      'created_at': Timestamp.fromDate(r.timestamp),
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

  String _encodeGeohash(double lat, double lng, {int precision = 9}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var isEven = true;
    var bit = 0;
    var ch = 0;
    var latMin = -90.0;
    var latMax = 90.0;
    var lngMin = -180.0;
    var lngMax = 180.0;
    final geohash = StringBuffer();

    while (geohash.length < precision) {
      if (isEven) {
        final mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          ch |= 1 << (4 - bit);
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return geohash.toString();
  }
}
