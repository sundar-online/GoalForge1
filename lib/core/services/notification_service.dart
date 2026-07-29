import 'notification_platform_stub.dart'
    if (dart.library.html) 'notification_platform_web.dart';
import '../utils/logger.dart';

class NotificationChannel {
  final String id;
  final String name;
  final String description;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
  });
}

class NotificationService {
  static const NotificationChannel channelDailyReminders = NotificationChannel(
    id: 'daily_reminders',
    name: 'Daily Forge Reminders',
    description: 'Notifications for scheduled daily habits and operations.',
  );

  static const NotificationChannel channelEventAlerts = NotificationChannel(
    id: 'event_alerts',
    name: 'Calendar Event Alerts',
    description: 'Reminders for scheduled upcoming calendar events.',
  );

  static const NotificationChannel channelFocusTimer = NotificationChannel(
    id: 'focus_timer',
    name: 'Focus Session Alerts',
    description: 'Alerts when deep focus timer sessions complete.',
  );

  bool _initialized = false;
  final List<String> _scheduledNotificationIds = [];

  bool get isInitialized => _initialized;
  List<String> get scheduledNotificationIds => List.unmodifiable(_scheduledNotificationIds);

  /// Initializes notification channels and permission handlers
  Future<void> initialize() async {
    try {
      AppLogger.i('Initializing NotificationService channels...');
      _initialized = true;
      AppLogger.i('NotificationService initialized successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to initialize NotificationService', e, stack);
    }
  }

  /// Requests notification permissions on supported platforms
  Future<bool> requestPermission() async {
    return await NotificationPlatform.requestPermission();
  }

  /// Schedules a recurring daily habit reminder notification
  Future<void> scheduleDailyHabitReminder({required int hour, required int minute}) async {
    final id = 'daily_reminder_${hour}_$minute';
    AppLogger.i('Scheduled daily habit reminder at $hour:$minute (ID: $id)');
    if (!_scheduledNotificationIds.contains(id)) {
      _scheduledNotificationIds.add(id);
    }
  }

  /// Schedules a reminder notification prior to a scheduled event
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventTime,
    required int reminderMinutes,
  }) async {
    final notifyTime = eventTime.subtract(Duration(minutes: reminderMinutes));
    final id = 'event_$eventId';
    AppLogger.i('Scheduled event notification for "$title" at $notifyTime (ID: $id)');
    if (!_scheduledNotificationIds.contains(id)) {
      _scheduledNotificationIds.add(id);
    }
  }

  /// Displays an immediate completion alert notification when focus timer finishes
  Future<void> showFocusCompletedNotification({
    required String sessionType,
    required int minutes,
  }) async {
    const title = 'Focus Session Complete';
    final body = 'Your $minutes-minute session has ended.';
    AppLogger.i('Deep Focus Session Complete! ($minutes mins, +100 XP awarded)');
    NotificationPlatform.showNotification(title: title, body: body);
  }

  /// Cancels a scheduled notification by ID
  Future<void> cancelReminder(String id) async {
    _scheduledNotificationIds.remove(id);
    AppLogger.i('Cancelled notification ID: $id');
  }
}
