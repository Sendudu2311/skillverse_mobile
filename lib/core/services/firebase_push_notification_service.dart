import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/services/fcm_api_service.dart';
import 'push_notification_service.dart';

/// Top-level handler for background messages (must be top-level function).
/// Must call Firebase.initializeApp() because background isolate has no context.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FCM Background] ${message.notification?.title}');
}

/// Firebase Cloud Messaging implementation of [PushNotificationService].
///
/// Singleton pattern — access via [FirebasePushNotificationService.instance].
class FirebasePushNotificationService implements PushNotificationService {
  // ─── Singleton ──────────────────────────────────────────────────────────────
  static final FirebasePushNotificationService instance =
      FirebasePushNotificationService._internal();
  factory FirebasePushNotificationService() => instance;
  FirebasePushNotificationService._internal();

  // ─── Dependencies ───────────────────────────────────────────────────────────
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FcmApiService _fcmApiService = FcmApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<PushPayload> _foregroundController =
      StreamController<PushPayload>.broadcast();
  final StreamController<PushPayload> _tapController =
      StreamController<PushPayload>.broadcast();

  // P5.1/P5.3: Store stream subscriptions so they can be cancelled on dispose.
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<RemoteMessage>? _onMessageOpenedAppSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;

  /// P5.3: Callback registered by the app to handle foreground notification taps.
  /// Payload format: `{"route": "/courses/42"}` or plain route string.
  void Function(String route)? onNotificationTapNavigate;

  String? _currentToken;
  bool _initialized = false;
  bool _tokenRegisteredWithBackend = false;
  static const String _tokenRegisteredKey = 'fcm_token_registered';

  static const _androidChannel = AndroidNotificationChannel(
    'skillverse_notifications',
    'Skillverse Notifications',
    description: 'Thông báo từ Skillverse',
    importance: Importance.high,
  );

  // ─── Public API ─────────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    // Restore persisted token registration state
    try {
      final prefs = await SharedPreferences.getInstance();
      _tokenRegisteredWithBackend = prefs.getBool(_tokenRegisteredKey) ?? false;
    } catch (e) {
      debugPrint('🔔 [FCM] Failed to load token registration state: $e');
    }

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Setup local notifications for foreground display
    await _setupLocalNotifications();

    // Request permission (Android 13+ / iOS)
    await requestPermission();

    // Get FCM token (but do NOT register with backend yet — user may not be logged in)
    await _fetchToken();

    // Listen for token refresh (P5.2: stored so it can be cancelled)
    _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 [FCM] Token refreshed');
      _currentToken = newToken;
      // Re-register only if we previously registered successfully
      if (_tokenRegisteredWithBackend) {
        _registerTokenWithBackend(newToken);
      }
    });

    // Foreground messages (stored so it can be cancelled on dispose)
    _onMessageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Foreground] ${message.notification?.title}');
      _foregroundController.add(_remoteMessageToPayload(message));
      _showLocalNotification(message);
    });

    // Background/terminated notification tap
    _onMessageOpenedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM Tap] ${message.notification?.title}');
      _tapController.add(_remoteMessageToPayload(message));
    });

    // Check if app was opened from a terminated state notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔔 [FCM Initial] ${initialMessage.notification?.title}');
      _tapController.add(_remoteMessageToPayload(initialMessage));
    }

    _initialized = true;
  }

  /// Call this AFTER successful login to register the FCM token with Backend.
  /// The backend requires an auth token, so this must be called post-authentication.
  Future<void> registerTokenAfterLogin() async {
    if (_currentToken == null) {
      await _fetchToken();
    }
    if (_currentToken != null) {
      await _registerTokenWithBackend(_currentToken!);
      _tokenRegisteredWithBackend = true;
      _persistTokenRegistrationState(true);
      debugPrint('🔔 [FCM] Token registered with backend after login');
    }
  }

  /// Call this BEFORE or DURING logout to unregister the FCM token.
  /// Prevents push notifications from arriving after the user logs out.
  Future<void> unregisterTokenOnLogout() async {
    if (_currentToken != null) {
      await _fcmApiService.unregisterDeviceToken(_currentToken!);
      debugPrint('🔔 [FCM] Token unregistered on logout');
    }
    _tokenRegisteredWithBackend = false;
    _persistTokenRegistrationState(false);
  }

  Future<void> _persistTokenRegistrationState(bool registered) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tokenRegisteredKey, registered);
    } catch (e) {
      debugPrint('🔔 [FCM] Failed to persist token registration state: $e');
    }
  }

  @override
  Future<String?> getDeviceToken() async {
    _currentToken ??= await _messaging.getToken();
    return _currentToken;
  }

  @override
  Stream<PushPayload> get onForegroundMessage => _foregroundController.stream;

  @override
  Stream<PushPayload> get onNotificationTap => _tapController.stream;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('🔔 [FCM] Permission: ${settings.authorizationStatus}');
    return granted;
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // P5.3: Add iOS DarwinInitializationSettings so foreground notification taps
    // trigger onDidReceiveNotificationResponse on iOS.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 [Local] Notification tapped: ${response.payload}');
        // P5.3: Navigate if callback is registered and payload contains route
        if (onNotificationTapNavigate != null && response.payload != null) {
          final payload = response.payload!;
          // Support both plain route string and JSON {"route": "/path"}
          if (payload.startsWith('{')) {
            // Simple JSON parse for {"route": "/path"}
            final routeMatch = RegExp(r'"route"\s*:\s*"([^"]+)"').firstMatch(payload);
            if (routeMatch != null) {
              onNotificationTapNavigate!(routeMatch.group(1)!);
            }
          } else {
            onNotificationTapNavigate!(payload);
          }
        }
      },
    );

    // Create the notification channel on Android
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  Future<void> _fetchToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        debugPrint('🔔 [FCM] Token: ${_currentToken!.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('🔔 [FCM] Failed to get token: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    await _fcmApiService.registerDeviceToken(
      deviceToken: token,
      deviceType: Platform.isAndroid ? 'ANDROID' : 'IOS',
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  PushPayload _remoteMessageToPayload(RemoteMessage message) {
    return PushPayload(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
  }

  // P5.1: Dispose stream controllers and cancel subscriptions to prevent memory leaks.
  void dispose() {
    _foregroundController.close();
    _tapController.close();
    _onMessageSubscription?.cancel();
    _onMessageOpenedAppSubscription?.cancel();
    _onTokenRefreshSubscription?.cancel();
  }
}
