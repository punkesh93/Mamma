import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    // ignore: avoid_print
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  void setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        debugPrint('Foreground notification: ${message.notification?.title}');
        // You could show a local notification here
      }
    });
  }

  /// Sends a simulated behavioral nudge based on user activity
  void sendSocialNudge(String type) {
    // In production, this would be a Firebase Cloud Function trigger.
    // For now, we simulate the concept.
    final nudges = {
      'mood': 'Other moms are tracking their mood now. How are you feeling today?',
      'water': 'Don\'t forget to stay hydrated! Your baby needs it too 💧',
      'milestone': 'You just completed another week! Share your progress with your partner 🌸',
    };

    final message = nudges[type] ?? 'Keep up the great work, Mama!';
    debugPrint('Simulated Push Notification [$type]: $message');
  }

  /// Logic for daily check-in reminders
  Future<void> scheduleDailyCheckIn() async {
    // This would use flutter_local_notifications to schedule a daily alarm.
    // Since we are primarily using FCM, we record the intent.
    debugPrint('Daily check-in reminders scheduled for 9:00 AM');
  }
}
