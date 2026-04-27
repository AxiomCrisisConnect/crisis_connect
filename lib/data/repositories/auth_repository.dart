import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/volunteer_profile.dart';
import '../../core/constants/app_constants.dart';

// TODO: Ensure Firebase is initialized in main.dart before using this repo
// TODO: Enable Email/Password in Firebase Console → Authentication → Sign-in methods
// TODO: Enable Google in Firebase Console → Authentication → Sign-in methods
// TODO: Add SHA-1 / SHA-256 fingerprints in Firebase Console for Android Google Sign-In
// TODO: For iOS, add REVERSED_CLIENT_ID to URL schemes in Info.plist

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _prefs;

  AuthRepository({
    required SharedPreferences prefs,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // Web client ID (type 3) from google-services.json
              // Required on Android for the account picker to appear
              serverClientId:
                  '845941652373-agrqe40glt91c6qaoqaoa680fqtga089.apps.googleusercontent.com',
            ),
        _prefs = prefs;

  // ─── Email/Password Auth ──────────────────────────────────────────────────

  /// Creates a new Firebase Auth user + Firestore document.
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user!;
    await firebaseUser.updateDisplayName(name.trim());

    final user = UserModel(
      id: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phoneNumber: null,
      role: role,
      authProvider: UserAuthProvider.email,
      createdAt: DateTime.now(),
    );

    // Cache locally first so the user is always returned even if Firestore fails
    await _cacheUser(user);
    // Best-effort Firestore save — don't block sign-up if it fails
    try {
      await _saveUserToFirestore(user);
    } catch (_) {
      // Will be retried on next sign-in via _healOrphanedAccount
    }
    return user;
  }

  /// Signs in an existing user with email + password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user!;
    UserModel? user = await _fetchUserFromFirestore(firebaseUser.uid);

    // Auto-heal: Firebase Auth account exists but Firestore doc is missing
    // (can happen if Firestore was blocked during sign-up)
    if (user == null) {
      user = _getUserFromPrefs();
      if (user == null) {
        // Last resort: reconstruct a minimal profile from Firebase Auth data
        user = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@').first,
          email: email.trim(),
          phoneNumber: null,
          role: UserRole.civilian, // default — they can change it
          authProvider: UserAuthProvider.email,
          createdAt: DateTime.now(),
        );
      }
      // Try to write the recovered doc back to Firestore
      try { await _saveUserToFirestore(user); } catch (_) {}
    }

    await _cacheUser(user);
    return user;
  }

  /// Sends a password reset email.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  /// Signs in with Google. Returns (user, isNewUser).
  /// If [isNewUser] is true, caller should prompt for role selection.
  Future<({UserModel? user, bool isNewUser, GoogleSignInAccount? googleAccount})>
      signInWithGoogle() async {
    // Start Google flow
    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      // User cancelled picker
      return (user: null, isNewUser: false, googleAccount: null);
    }

    final googleAuth = await googleAccount.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;
    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;

    if (!isNew) {
      // Returning user — fetch from Firestore
      final user = await _fetchUserFromFirestore(firebaseUser.uid);
      if (user != null) {
        await _cacheUser(user);
        return (user: user, isNewUser: false, googleAccount: null);
      }
      // Firestore doc missing for a non-new Firebase user → treat as new
    }

    // New user — return google account info for profile completion screen
    return (user: null, isNewUser: true, googleAccount: googleAccount);
  }

  /// Called after the profile-completion screen for new Google users.
  Future<UserModel> completeGoogleProfile({
    required String name,
    required String email,
    required String? phoneNumber,
    required UserRole role,
  }) async {
    final firebaseUser = _auth.currentUser!;
    await firebaseUser.updateDisplayName(name.trim());

    final user = UserModel(
      id: firebaseUser.uid,
      name: name.trim(),
      email: email.trim(),
      phoneNumber: phoneNumber?.trim().isEmpty == true ? null : phoneNumber?.trim(),
      role: role,
      authProvider: UserAuthProvider.google,
      createdAt: DateTime.now(),
    );

    await _saveUserToFirestore(user);
    await _cacheUser(user);
    return user;
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _prefs.remove(AppConstants.prefUserId);
    await _prefs.remove(AppConstants.prefUserRole);
    await _prefs.remove(AppConstants.prefOnboardingComplete);
  }

  // ─── User State ───────────────────────────────────────────────────────────

  /// Returns the current persisted user, checking Firebase Auth first.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Try Firestore first, fall back to prefs cache
    final firestoreUser = await _fetchUserFromFirestore(firebaseUser.uid);
    if (firestoreUser != null) {
      await _cacheUser(firestoreUser);
      return firestoreUser;
    }

    // Fallback: prefs cache (offline or Firestore delay)
    return _getUserFromPrefs();
  }

  bool get isSignedIn => _auth.currentUser != null;

  bool get isOnboardingComplete =>
      _prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;

  Future<void> markOnboardingComplete() async {
    await _prefs.setBool(AppConstants.prefOnboardingComplete, true);
  }

  UserRole? get cachedRole {
    final role = _prefs.getString(AppConstants.prefUserRole);
    if (role == null) return null;
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.civilian,
    );
  }

  Future<void> updateUserName(String userId, String name) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'name': name.trim()});
    await _auth.currentUser?.updateDisplayName(name.trim());
  }

  // ─── Volunteer Profile ────────────────────────────────────────────────────

  Future<void> saveVolunteerProfile(VolunteerProfile profile) async {
    await _firestore
        .collection(AppConstants.volunteerProfilesCollection)
        .doc(profile.userId)
        .set(profile.toMap(), SetOptions(merge: true));
    // Also persist locally for fast reads / offline
    await _prefs.setString(
        'volunteer_profile_${profile.userId}', _encodeProfile(profile));
  }

  Future<VolunteerProfile?> getVolunteerProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.volunteerProfilesCollection)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return VolunteerProfile.fromMap(doc.data()!);
      }
    } catch (_) {
      // Firestore unavailable — fall back to local cache
    }
    final encoded = _prefs.getString('volunteer_profile_$userId');
    if (encoded == null) return null;
    return _decodeProfile(encoded);
  }

  // ─── Firestore Helpers ────────────────────────────────────────────────────

  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserModel?> _fetchUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      // Firestore unavailable (e.g. permission denied) — return null,
      // caller handles fallback
      return null;
    }
  }

  // ─── Local Prefs Helpers ─────────────────────────────────────────────────

  Future<void> _cacheUser(UserModel user) async {
    await _prefs.setString(AppConstants.prefUserId, user.id);
    await _prefs.setString(AppConstants.prefUserRole, user.role.name);
    await _prefs.setString('user_data_${user.id}', _encodeUser(user));
  }

  UserModel? _getUserFromPrefs() {
    final id = _prefs.getString(AppConstants.prefUserId);
    if (id == null) return null;
    final encoded = _prefs.getString('user_data_$id');
    if (encoded == null) return null;
    return _decodeUser(encoded);
  }

  // ─── Encoding (prefs cache — not the source of truth) ────────────────────

  String _encodeUser(UserModel u) => [
        u.id,
        u.name,
        u.email,
        u.phoneNumber ?? '',
        u.role.name,
        u.authProvider.name,
        u.createdAt.millisecondsSinceEpoch,
      ].join('||');

  UserModel _decodeUser(String s) {
    final p = s.split('||');
    return UserModel(
      id: p[0],
      name: p[1],
      email: p[2],
      phoneNumber: p[3].isEmpty ? null : p[3],
      role: UserRole.values.firstWhere((e) => e.name == p[4]),
      authProvider: UserAuthProvider.values.firstWhere(
        (e) => e.name == p[5],
        orElse: () => UserAuthProvider.email,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(int.parse(p[6])),
    );
  }

  String _encodeProfile(VolunteerProfile p) => [
        p.userId,
        p.skills.join(','),
        p.experienceLevel.name,
        p.licenseUrl ?? '',
        p.isAvailable,
        p.lastLatitude ?? '',
        p.lastLongitude ?? '',
        p.onboardingComplete,
      ].join('||');

  VolunteerProfile _decodeProfile(String s) {
    final parts = s.split('||');
    return VolunteerProfile(
      userId: parts[0],
      skills: parts[1].isEmpty ? [] : parts[1].split(','),
      experienceLevel: ExperienceLevel.values.firstWhere(
        (e) => e.name == parts[2],
        orElse: () => ExperienceLevel.student,
      ),
      licenseUrl: parts[3].isEmpty ? null : parts[3],
      isAvailable: parts[4] == 'true',
      lastLatitude: parts[5].isEmpty ? null : double.tryParse(parts[5]),
      lastLongitude: parts[6].isEmpty ? null : double.tryParse(parts[6]),
      onboardingComplete: parts[7] == 'true',
    );
  }
}
