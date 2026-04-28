import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/emergency_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/volunteer_profile.dart';
import '../data/models/emergency_request.dart';
import '../domain/services/location_service.dart';

// ─── Infra Providers ─────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize with ProviderScope overrides in main()');
});

// ─── Repository Providers ─────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
});

/// Fetches the single active/assigned emergency request for a civilian.
/// Pass the civilianId as the arg. Returns null when no active request exists.
final activeCivilianRequestProvider =
    FutureProvider.family<EmergencyRequest?, String>((ref, civilianId) {
  return ref
      .read(emergencyRepositoryProvider)
      .getActiveCivilianRequest(civilianId);
});

// ─── Service Providers ────────────────────────────────────────────────────────

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});


// ─── Auth State ───────────────────────────────────────────────────────────────

final currentUserProvider = StateProvider<UserModel?>((ref) => null);
final volunteerProfileProvider = StateProvider<VolunteerProfile?>((ref) => null);

// ─── Auth Notifier ────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.getCurrentUser();
      _ref.read(currentUserProvider.notifier).state = user;
      if (user != null && user.role == UserRole.volunteer) {
        final profile = await _repo.getVolunteerProfile(user.id);
        _ref.read(volunteerProfileProvider.notifier).state = profile;
        // Sync the onboarding flag from Firestore → SharedPreferences
        // so it survives reinstalls / new devices
        if (profile != null && profile.onboardingComplete) {
          await _repo.markOnboardingComplete();
        }
      }
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ─── Email/Password ───────────────────────────────────────────────────────

  /// Creates account and immediately signs in.
  Future<UserModel> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      _ref.read(currentUserProvider.notifier).state = user;
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  /// Signs in existing user with email + password.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user =
          await _repo.signInWithEmail(email: email, password: password);
      _ref.read(currentUserProvider.notifier).state = user;
      if (user.role == UserRole.volunteer) {
        final profile = await _repo.getVolunteerProfile(user.id);
        _ref.read(volunteerProfileProvider.notifier).state = profile;
        // Sync onboarding flag from Firestore → prefs
        if (profile != null && profile.onboardingComplete) {
          await _repo.markOnboardingComplete();
        }
      }
      state = AsyncValue.data(user);
      return user;
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repo.sendPasswordReset(email);
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────

  /// Returns (user, isNewUser, googleAccount).
  /// If isNewUser == true, navigate to CompleteProfileScreen.
  Future<({UserModel? user, bool isNewUser, dynamic googleAccount})>
      signInWithGoogle() async {
    // NOTE: Do NOT set AsyncLoading here.
    // Setting AsyncLoading triggers router.refresh() which redirects the
    // auth screen away BEFORE we have a result, unmounting the screen and
    // breaking any subsequent navigation from the auth screen callbacks.
    try {
      final result = await _repo.signInWithGoogle();
      if (result.user != null) {
        // Returning user — fully resolved.
        // Update currentUser BEFORE state so the redirect reads the right user.
        _ref.read(currentUserProvider.notifier).state = result.user;
        if (result.user!.role == UserRole.volunteer) {
          final profile =
              await _repo.getVolunteerProfile(result.user!.id);
          _ref.read(volunteerProfileProvider.notifier).state = profile;
          if (profile != null && profile.onboardingComplete) {
            await _repo.markOnboardingComplete();
          }
        }
        // This state change triggers router.refresh() which navigates to home.
        state = AsyncValue.data(result.user);
      }
      // For new users or cancellations we leave state unchanged so the
      // auth screen stays showing and the caller can push CompleteProfile.
      return (
        user: result.user,
        isNewUser: result.isNewUser,
        googleAccount: result.googleAccount,
      );
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  /// Called after profile-completion screen for first-time Google users.
  Future<UserModel> completeGoogleProfile({
    required String name,
    required String email,
    required String? phoneNumber,
    required UserRole role,
  }) async {
    final user = await _repo.completeGoogleProfile(
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
    );
    _ref.read(currentUserProvider.notifier).state = user;
    state = AsyncValue.data(user);
    return user;
  }

  // ─── Volunteer Onboarding ─────────────────────────────────────────────────

  Future<void> saveVolunteerProfile(VolunteerProfile profile) async {
    await _repo.saveVolunteerProfile(profile);
    await _repo.markOnboardingComplete();
    _ref.read(volunteerProfileProvider.notifier).state = profile;
  }

  bool get isOnboardingComplete => _repo.isOnboardingComplete;

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _repo.signOut();
    _ref.read(currentUserProvider.notifier).state = null;
    _ref.read(volunteerProfileProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

// ─── Volunteer Availability Notifier ─────────────────────────────────────────

class AvailabilityNotifier extends StateNotifier<bool> {
  final AuthRepository _authRepo;
  final LocationService _locationService;

  AvailabilityNotifier(
    this._authRepo,
    this._locationService,
    bool initialValue,
  ) : super(initialValue);

  Future<void> toggle(VolunteerProfile profile) async {
    final newValue = !state;
    state = newValue;

    final updated = profile.copyWith(isAvailable: newValue);
    await _authRepo.saveVolunteerProfile(updated);

    if (newValue) {
      _locationService.startBackgroundTracking(
        intervalMinutes: 3,
        onLocationUpdate: (lat, lng) async {
          final p = profile.copyWith(
            lastLatitude: lat,
            lastLongitude: lng,
            locationUpdatedAt: DateTime.now(),
          );
          await _authRepo.saveVolunteerProfile(p);
        },
      );
    } else {
      _locationService.stopBackgroundTracking();
    }
  }
}

final availabilityProvider =
    StateNotifierProvider<AvailabilityNotifier, bool>((ref) {
  final profile = ref.watch(volunteerProfileProvider);
  return AvailabilityNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(locationServiceProvider),
    profile?.isAvailable ?? false,
  );
});
