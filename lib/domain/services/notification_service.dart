// TODO: Uncomment after adding Firebase to pubspec and configuring google-services.json:
// import 'package:firebase_messaging/firebase_messaging.dart';

// TODO: Configure FCM in Firebase Console and add server key to backend
// TODO: Implement Firebase Cloud Functions to trigger push notifications on assignment creation

class NotificationService {
  // TODO: Inject FirebaseMessaging in production:
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  NotificationService();

  Future<void> initialize() async {
    // TODO: In production:
    // final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   final token = await _messaging.getToken();
    //   await _saveTokenToBackend(token!);
    // }
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    // FirebaseMessaging.onBackgroundMessage(_bgHandler);
  }

  /// Mock: Send assignment notification to a volunteer.
  /// In production, trigger via Firebase Cloud Function or server API.
  Future<void> sendAssignmentNotification({
    required String volunteerId,
    required String civilianName,
    required String crisisType,
    required String location,
  }) async {
    // TODO: POST to Cloud Function endpoint with FCM token lookup + send
  }

  // Future<void> _saveTokenToBackend(String token) async {
  //   // TODO: Save FCM token to Firestore user document
  // }
}

// TODO: Register background message handler at app level:
// @pragma('vm:entry-point')
// Future<void> _bgHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// }
