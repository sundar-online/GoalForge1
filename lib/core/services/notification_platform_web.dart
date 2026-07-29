// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../utils/logger.dart';

class NotificationPlatform {
  static Future<bool> requestPermission() async {
    try {
      if (html.Notification.supported) {
        final permission = await html.Notification.requestPermission();
        AppLogger.i('Browser notification permission result: $permission');
        return permission == 'granted';
      }
    } catch (e) {
      AppLogger.w('Error requesting browser notification permission: $e');
    }
    return false;
  }

  static void showNotification({required String title, required String body}) {
    try {
      if (html.Notification.supported && html.Notification.permission == 'granted') {
        html.Notification(title, body: body);
        AppLogger.i('Displayed browser notification: "$title"');
      } else {
        AppLogger.w('Notification not granted or supported. Requesting permission...');
        requestPermission().then((granted) {
          if (granted && html.Notification.supported) {
            html.Notification(title, body: body);
          }
        });
      }
    } catch (e) {
      AppLogger.e('Failed to display browser notification: $e');
    }
  }
}
