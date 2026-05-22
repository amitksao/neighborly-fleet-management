import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'core/injection.dart';
import 'fleet/infrastructure/notifications/fleet_notification_service.dart';
import 'app.dart';

/// Background message handler — must be a top-level function.
/// Runs in an isolate; cannot access Flutter UI or navigator.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Firebase must be initialized in background isolate
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.notification?.title}');
}

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional — push notifications only).
  // Without a firebase_options.dart / google-services config the app still
  // runs; notifications are simply disabled.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (_) {
    debugPrint('[Firebase] Not configured — push notifications disabled.');
  }

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
  }

  setupInjection();

  if (firebaseReady) {
    try {
      final notificationService =
          FleetNotificationService(navigatorKey: navigatorKey);
      await notificationService.initialize();
    } catch (_) {
      debugPrint('[Notifications] Failed to initialize — continuing without.');
    }
  }

  runApp(FleetApp(navigatorKey: navigatorKey));
}
