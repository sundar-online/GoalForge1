import '../utils/logger.dart';

class NotificationPlatform {
  static Future<bool> requestPermission() async {
    return true;
  }

  static void showNotification({required String title, required String body}) {
    AppLogger.i('[NotificationStub] Notification: $title - $body');
  }
}
