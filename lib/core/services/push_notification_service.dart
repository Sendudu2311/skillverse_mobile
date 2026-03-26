// Push Notification Service — abstract interface + stub implementation.
//
// HOW TO ADD FCM SUPPORT LATER:
//   1. Add to pubspec.yaml:
//        firebase_core: ^2.x.x
//        firebase_messaging: ^14.x.x
//   2. Run `flutterfire configure` to generate google-services.json / GoogleService-Info.plist
//   3. Create FirebasePushNotificationService implementing PushNotificationService
//   4. Register device token with backend: POST /api/notifications/device-token
//   5. Replace StubPushNotificationService with FirebasePushNotificationService in main.dart

abstract class PushNotificationService {
  /// Initialize the push notification service (request permissions, setup handlers).
  Future<void> initialize();

  /// Get the device token used to target this device (FCM token / APNs token).
  /// Returns null if unavailable or permission denied.
  Future<String?> getDeviceToken();

  /// Stream of incoming notification payloads when the app is in the foreground.
  Stream<PushPayload> get onForegroundMessage;

  /// Stream of notification payloads when the user taps a notification
  /// while the app is in background or terminated.
  Stream<PushPayload> get onNotificationTap;

  /// Request notification permission from the OS.
  /// Required on iOS and Android 13+.
  /// Returns true if granted.
  Future<bool> requestPermission();
}

class PushPayload {
  final String? title;
  final String? body;

  /// Arbitrary key-value data attached to the push notification.
  /// Typically includes 'type' and 'relatedId' for deep-link routing.
  final Map<String, dynamic> data;

  const PushPayload({this.title, this.body, this.data = const {}});
}

// ── Stub (no-op until FCM is integrated) ─────────────────────────────────────

class StubPushNotificationService implements PushNotificationService {
  const StubPushNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getDeviceToken() async => null;

  @override
  Stream<PushPayload> get onForegroundMessage => const Stream.empty();

  @override
  Stream<PushPayload> get onNotificationTap => const Stream.empty();

  @override
  Future<bool> requestPermission() async => false;
}
