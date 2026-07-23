import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/focus_session.dart';
import '../../domain/repositories/focus_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/notification_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/logger.dart';

class FocusRepositoryImpl implements FocusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;
  final NotificationService _notificationService;

  FocusRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
    NotificationService? notificationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine,
        _notificationService = notificationService ?? NotificationService();

  List<FocusSession> _mapFocusSessions() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxFocus)
        .map((json) => FocusSession.fromJson(json))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<FocusSession>> watchFocusSessions() async* {
    yield _mapFocusSessions();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxFocus)) {
      yield _mapFocusSessions();
    }
  }

  @override
  List<FocusSession> getFocusSessions() => _mapFocusSessions();

  @override
  Future<void> logFocusSession(FocusSession session) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxFocus,
      session.id,
      session.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      session.id,
      'focus',
      'upsert',
      session.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();

    // 4. Trigger focus completion alert notification (encapsulated in repository)
    try {
      await _notificationService.showFocusCompletedNotification(
        sessionType: session.type,
        minutes: session.duration,
      );
    } catch (e) {
      AppLogger.e('Failed to show focus completion notification in repository', e);
    }
  }

  @override
  Future<void> fetchRemoteFocusSessions() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching focus sessions from Firestore...');
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('focus')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxFocus);

      for (var doc in snapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxFocus, doc.id, doc.data());
      }

      AppLogger.i('Focus sessions synced from remote successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote focus sessions', e, stack);
    }
  }
}
