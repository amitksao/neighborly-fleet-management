import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Handles FCM push notifications for the Fleet module.
///
/// Call [initialize] once at app startup (after Firebase.initializeApp).
/// The app must supply a [navigatorKey] so this service can navigate
/// without a BuildContext.
class FleetNotificationService {
  final GlobalKey<NavigatorState> navigatorKey;

  FleetNotificationService({required this.navigatorKey});

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission (iOS/web; Android grants by default on API < 33)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground message handler — shows a banner while the app is open
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated tap handler — user taps notification to open app
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for notifications that launched the app from terminated state
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }

    // Register device token update handler
    messaging.onTokenRefresh.listen((token) {
      // TODO: send updated token to backend via PATCH /users/me/device-token
      debugPrint('[FCM] Token refreshed: $token');
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    final data = message.data;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Show a simple SnackBar for foreground messages
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.notification?.body ??
              message.data['title'] as String? ??
              'New notification',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _routeFromData(data),
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    _routeFromData(message.data);
  }

  void _routeFromData(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final rideId = data['rideId'] as String?;
    final fleetId = data['fleetId'] as String?;

    // Route based on notification type
    if (rideId != null) {
      // Driver received a ride assignment — go to assignment screen
      // The assignment screen is already shown by the scheduled notification;
      // this handles the tap-from-background case.
      navigator.pushNamed('/fleet/ride-active');
      return;
    }

    if (fleetId != null) {
      navigator.pushNamed('/fleet/dashboard', arguments: fleetId);
      return;
    }
  }

  /// Returns the current FCM device token. Call this after [initialize]
  /// and send the result to your backend to store on the user record.
  Future<String?> getToken() async {
    return FirebaseMessaging.instance.getToken();
  }
}
