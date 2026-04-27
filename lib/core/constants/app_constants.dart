/// App-wide constants for CrisisConnect
class AppConstants {
  AppConstants._();

  static const String appName = 'CrisisConnect';
  static const String appTagline = 'Every Second Counts';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String volunteerProfilesCollection = 'volunteer_profiles';
  static const String emergencyRequestsCollection = 'emergency_requests';
  static const String assignmentsCollection = 'assignments';
  static const String chatMessagesCollection = 'chat_messages';

  // SharedPreferences Keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefUserRole = 'user_role';
  static const String prefUserId = 'user_id';
  static const String prefCachedAssignments = 'cached_assignments';

  // Location update interval (minutes)
  static const int locationUpdateIntervalMins = 3;

  // SOS auto-assign skills
  static const List<String> sosRequiredSkills = ['Rescue', 'Medical'];

  // TODO: Replace with real Google Maps API key in AndroidManifest.xml and AppDelegate.swift
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // TODO: Initialize Firebase with real google-services.json and GoogleService-Info.plist
}
