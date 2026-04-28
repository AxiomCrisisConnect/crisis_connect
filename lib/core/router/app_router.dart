import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:crisis_connect/providers/providers.dart';
import 'package:crisis_connect/data/models/user_model.dart';

// Auth screens
import 'package:crisis_connect/presentation/auth/screens/auth_screen.dart';
import 'package:crisis_connect/presentation/auth/screens/forgot_password_screen.dart';
import 'package:crisis_connect/presentation/auth/screens/complete_profile_screen.dart';

// Volunteer screens
import 'package:crisis_connect/presentation/volunteer/screens/onboarding_step1_screen.dart';
import 'package:crisis_connect/presentation/volunteer/screens/onboarding_step2_screen.dart';
import 'package:crisis_connect/presentation/volunteer/screens/onboarding_step3_screen.dart';
import 'package:crisis_connect/presentation/volunteer/screens/volunteer_home_screen.dart';
import 'package:crisis_connect/presentation/volunteer/screens/volunteer_profile_screen.dart';
import 'package:crisis_connect/presentation/volunteer/screens/assignment_history_screen.dart';

// Civilian screens
import 'package:crisis_connect/presentation/civilian/screens/civilian_home_screen.dart';
import 'package:crisis_connect/presentation/civilian/screens/live_tracking_screen.dart';
import 'package:crisis_connect/presentation/civilian/screens/help_request_screen.dart';
import 'package:crisis_connect/presentation/civilian/screens/sos_history_screen.dart';

// Shared
import 'package:crisis_connect/presentation/shared/widgets/splash_screen.dart';

// ─── Route names ─────────────────────────────────────────────────────────────

class AppRoutes {
  // Splash
  static const String splash = '/';

  // Auth
  static const String auth = '/auth';
  static const String forgotPassword = '/auth/forgot-password';
  static const String completeProfile = '/auth/complete-profile';

  // Volunteer onboarding
  static const String onboardingStep1 = '/onboarding/1';
  static const String onboardingStep2 = '/onboarding/2';
  static const String onboardingStep3 = '/onboarding/3';

  // Volunteer home
  static const String volunteerHome = '/volunteer/home';
  static const String volunteerProfile = '/volunteer/profile';
  static const String assignmentHistory = '/volunteer/history';

  // Civilian home
  static const String civilianHome = '/civilian/home';
  static const String sosActive = '/civilian/sos-active';
  static const String helpRequest = '/civilian/help';
  static const String helpActive = '/civilian/help-active';
  static const String sosHistory = '/civilian/history';
}

// ─── Router provider ─────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final user = ref.read(currentUserProvider);
      final isLoading = authState is AsyncLoading;
      final loc = state.matchedLocation;

      // 1. While app is initializing, force show splash screen
      if (isLoading) return loc == AppRoutes.splash ? null : AppRoutes.splash;

      // Routes that don't need an authenticated user
      final publicRoutes = {
        AppRoutes.splash,
        AppRoutes.auth,
        AppRoutes.forgotPassword,
        AppRoutes.completeProfile,
      };

      final isPublic = publicRoutes.contains(loc);

      // 2. Not signed in
      if (user == null) {
        // Allow public routes (auth, forgot password, etc), but not splash once loaded
        if (isPublic && loc != AppRoutes.splash) return null;
        return AppRoutes.auth;
      }

      // 3. Signed in
      // Volunteer onboarding gate
      final authRepo = ref.read(authRepositoryProvider);
      if (user.role == UserRole.volunteer &&
          !authRepo.isOnboardingComplete &&
          !loc.startsWith('/onboarding')) {
        return AppRoutes.onboardingStep1;
      }

      // Send fully authenticated user coming from public/splash to home
      if (isPublic) {
        return user.role == UserRole.volunteer
            ? AppRoutes.volunteerHome
            : AppRoutes.civilianHome;
      }
    
      return null;
    },
    routes: [
      // ── Splash ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CompleteProfileScreen(
            prefillName: extra['name'] as String? ?? '',
            email: extra['email'] as String? ?? '',
          );
        },
      ),

      // ── Volunteer onboarding ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboardingStep1,
        builder: (context, state) => const OnboardingStep1Screen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingStep2,
        builder: (context, state) => OnboardingStep2Screen(
          selectedSkills: state.extra as List<String>? ?? [],
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingStep3,
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return OnboardingStep3Screen(
            selectedSkills:
                (args['skills'] as List?)?.cast<String>() ?? [],
            experienceLevel:
                args['experienceLevel'] as String? ?? 'student',
          );
        },
      ),

      // ── Volunteer home ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.volunteerHome,
        builder: (context, state) => const VolunteerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.volunteerProfile,
        builder: (context, state) => const VolunteerProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.assignmentHistory,
        builder: (context, state) => const AssignmentHistoryScreen(),
      ),

      // ── Civilian home ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.civilianHome,
        builder: (context, state) => const CivilianHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.sosActive,
        builder: (context, state) => LiveTrackingScreen(
          requestId: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.helpRequest,
        builder: (context, state) => const HelpRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.helpActive,
        builder: (context, state) => LiveTrackingScreen(
          requestId: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.sosHistory,
        builder: (context, state) => const SOSHistoryScreen(),
      ),
    ],
  );

  // Trigger router to re-evaluate redirect rules on auth state change
  ref.listen(
    authNotifierProvider,
    (_, _) => router.refresh(),
  );

  return router;
});
