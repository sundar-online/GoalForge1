import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import '../utils/logger.dart';

class SyncEngine {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  SyncEngine({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Iterates over the cached sync queue and attempts to replay transactions on Firestore
  Future<void> processSyncQueue() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      AppLogger.w('Skipping Sync Engine execution: User is unauthenticated.');
      return;
    }

    final queue = LocalDatabaseService.getQueue();
    if (queue.isEmpty) {
      AppLogger.d('Sync Queue is empty. Nothing to sync.');
      return;
    }

    AppLogger.i('Processing ${queue.length} pending tasks in the Sync Queue...');

    for (var task in queue) {
      final key = task['key'] as String;
      final id = task['id'] as String;
      final collection = task['collection'] as String;
      final action = task['action'] as String;
      final Map<String, dynamic>? payload = task['payload'] != null 
          ? Map<String, dynamic>.from(task['payload']) 
          : null;

      try {
        final ref = _getDocumentReference(user.uid, collection, id, payload);
        if (ref == null) {
          AppLogger.e('Could not resolve Firestore reference for task $key');
          await LocalDatabaseService.removeFromQueue(key);
          continue;
        }

        if (action == 'upsert') {
          if (payload == null) continue;
          await ref.set(payload, SetOptions(merge: true));
          AppLogger.i('Synced upsert for $collection/$id successfully.');
        } else if (action == 'delete') {
          await ref.delete();
          AppLogger.i('Synced deletion for $collection/$id successfully.');
        }

        // Remove from local sync queue on success
        await LocalDatabaseService.removeFromQueue(key);
      } catch (e, stack) {
        AppLogger.e('Failed to sync queue item $key. Sync will retry later.', e, stack);
        // Break out to retry on next cycle instead of looping errors
        break;
      }
    }
  }

  DocumentReference? _getDocumentReference(
    String uid,
    String collection,
    String id,
    Map<String, dynamic>? payload,
  ) {
    switch (collection) {
      case 'goals':
        return _firestore.collection('users').doc(uid).collection('goals').doc(id);
      case 'habits':
        final goalId = payload?['goalId'] as String?;
        if (goalId == null || goalId.isEmpty) {
          AppLogger.e('Cannot resolve habit path: missing parent goalId');
          return null;
        }
        return _firestore
            .collection('users')
            .doc(uid)
            .collection('goals')
            .doc(goalId)
            .collection('habits')
            .doc(id);
      case 'tasks':
        return _firestore.collection('users').doc(uid).collection('tasks').doc(id);
      case 'task_logs':
        return _firestore.collection('users').doc(uid).collection('task_logs').doc(id);
      case 'notes':
        return _firestore.collection('users').doc(uid).collection('notes').doc(id);
      case 'quick_thoughts':
        return _firestore.collection('users').doc(uid).collection('quick_thoughts').doc(id);
      case 'events':
        return _firestore.collection('users').doc(uid).collection('scheduled_events').doc(id);
      case 'focus':
        return _firestore.collection('users').doc(uid).collection('focus_sessions').doc(id);
      case 'xp':
        return _firestore.collection('users').doc(uid).collection('xp').doc('profile');
      case 'settings':
        return _firestore.collection('users').doc(uid).collection('settings').doc('general');
      default:
        return null;
    }
  }
}
