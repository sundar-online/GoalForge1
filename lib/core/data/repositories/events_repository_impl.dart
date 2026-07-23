import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/scheduled_event.dart';
import '../../domain/repositories/events_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/notification_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/date_utils.dart';
import '../../utils/logger.dart';

class EventsRepositoryImpl implements EventsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;
  final NotificationService _notificationService;

  EventsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine,
        _notificationService = notificationService ?? NotificationService();

  List<ScheduledEvent> _mapEvents() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxEvents)
        .map((json) => ScheduledEvent.fromJson(json))
        .toList();
  }

  @override
  Stream<List<ScheduledEvent>> watchEvents() async* {
    yield _mapEvents();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxEvents)) {
      yield _mapEvents();
    }
  }

  @override
  List<ScheduledEvent> getEvents() => _mapEvents();

  @override
  Future<void> upsertEvent(ScheduledEvent event) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxEvents,
      event.id,
      event.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      event.id,
      'events',
      'upsert',
      event.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();

    // 4. Schedule notification via NotificationService (encapsulated in repository)
    try {
      final eventDate = AppDateUtils.parseYYYYMMDD(event.eventDate);
      await _notificationService.scheduleEventReminder(
        eventId: event.id,
        title: event.title,
        eventTime: eventDate,
        reminderMinutes: event.reminderMinutes,
      );
    } catch (e) {
      AppLogger.e('Failed to schedule event notification in repository', e);
    }
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await LocalDatabaseService.delete(LocalDatabaseService.boxEvents, eventId);
    await LocalDatabaseService.addToQueue(eventId, 'events', 'delete', null);
    await _notificationService.cancelReminder('event_$eventId');
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteEvents() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching events from Firestore...');
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('events')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxEvents);

      for (var doc in snapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxEvents, doc.id, doc.data());
      }

      AppLogger.i('Events synced from remote successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote events', e, stack);
    }
  }
}
