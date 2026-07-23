import '../models/scheduled_event.dart';

abstract class EventsRepository {
  /// Stream calendar events list.
  Stream<List<ScheduledEvent>> watchEvents();

  /// Get cached events.
  List<ScheduledEvent> getEvents();

  /// Create or update a calendar event.
  Future<void> upsertEvent(ScheduledEvent event);

  /// Delete a calendar event.
  Future<void> deleteEvent(String eventId);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteEvents();
}
