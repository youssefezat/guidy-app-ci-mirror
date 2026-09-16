import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Client-side FCM setup. This gets the app ready to *receive* push
/// notifications (permission, token, foreground handling) -- actually
/// *sending* them (e.g. "your saved commute route is delayed today")
/// requires a backend or Cloud Function that decides when to send and
/// calls the FCM API with the device token, which is a separate piece of
/// infrastructure this client code doesn't include.
class NotificationService {
  static FirebaseMessaging? get _messaging =>
      Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null;

  static Future<void> initialize() async {
    // Push notifications via FCM are only supported on Android and iOS
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('[FCM] Notifications are only supported on Android and iOS.');
      return;
    }

    if (Firebase.apps.isEmpty) {
      debugPrint('[FCM] Firebase not initialized; skipping notifications.');
      return;
    }

    try {
      final messaging = _messaging;
      if (messaging == null) return;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] Notification permission denied.');
        return;
      }

      final token = await messaging.getToken();
      debugPrint('[FCM] Device token: $token');
      // TODO: send this token to your backend (keyed by the signed-in user)
      // once there's an endpoint to store it -- that's what a future
      // "service disruption alert" feature would target for delivery.

      // Foreground messages don't show a system notification automatically
      // on their own; wire this into a UI (snackbar/in-app banner) once
      // there's real content the backend can push.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('[FCM] Error initializing notifications: $e');
    }
  }
}
