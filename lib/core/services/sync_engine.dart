import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'local_database_service.dart';
import '../utils/logger.dart';

class SyncEngine {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  StreamSubscription<User?>? _authSubscription;
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, StreamSubscription> _habitSubscriptions = {};
  String? _currentUid;

  SyncEngine({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    // Automatically manage real-time Firestore listeners based on Auth state changes
    _authSubscription = _firebaseAuth.authStateChanges().listen((user) {
      if (user != null) {
        if (_currentUid != user.uid) {
          _currentUid = user.uid;
          startRealTimeListeners(user.uid);
        }
      } else {
        _currentUid = null;
        stopRealTimeListeners();
      }
    });
  }

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

  /// Starts real-time Firestore listeners to sync cloud changes back to local database
  void startRealTimeListeners(String uid) {
    stopRealTimeListeners();
    AppLogger.i('SyncEngine: Starting real-time Firestore listeners for user $uid...');

    // Trigger processing of any pending offline tasks
    processSyncQueue();

    // Helper to listen to a collection and sync changes to local database box
    void listenCollection(String collectionName, String boxName) {
      final sub = _firestore
          .collection('users')
          .doc(uid)
          .collection(collectionName)
          .snapshots()
          .listen((snapshot) async {
        for (var change in snapshot.docChanges) {
          final docId = change.doc.id;
          final data = change.doc.data();

          if (change.type == DocumentChangeType.removed) {
            await LocalDatabaseService.delete(boxName, docId);
            AppLogger.d('SyncEngine: Remote delete synced locally for $boxName/$docId');
          } else {
            if (data != null) {
              final localData = LocalDatabaseService.get(boxName, docId);
              if (localData == null || !_areMapsEqual(localData, data)) {
                await LocalDatabaseService.save(boxName, docId, data);
                AppLogger.d('SyncEngine: Remote write synced locally for $boxName/$docId');
              }
            }
          }
        }
      }, onError: (e) {
        AppLogger.e('SyncEngine: Error in real-time listener for collection $collectionName', e);
      });
      _subscriptions.add(sub);
    }

    // Listen to all flat user subcollections
    listenCollection('goals', LocalDatabaseService.boxGoals);
    listenCollection('tasks', LocalDatabaseService.boxTasks);
    listenCollection('task_logs', LocalDatabaseService.boxTaskLogs);
    listenCollection('notes', LocalDatabaseService.boxNotes);
    listenCollection('quick_thoughts', LocalDatabaseService.boxQuickThoughts);
    listenCollection('scheduled_events', LocalDatabaseService.boxEvents);
    listenCollection('focus_sessions', LocalDatabaseService.boxFocus);
    listenCollection('xp', LocalDatabaseService.boxXp);
    listenCollection('settings', LocalDatabaseService.boxSettings);

    // Dynamic habit listeners: listen to habits subcollection for each goal
    final goalsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('goals')
        .snapshots()
        .listen((snapshot) {
      final activeGoalIds = <String>{};
      for (var doc in snapshot.docs) {
        activeGoalIds.add(doc.id);
        if (!_habitSubscriptions.containsKey(doc.id)) {
          final goalId = doc.id;
          final habitSub = _firestore
              .collection('users')
              .doc(uid)
              .collection('goals')
              .doc(goalId)
              .collection('habits')
              .snapshots()
              .listen((habitSnapshot) async {
            for (var change in habitSnapshot.docChanges) {
              final habitId = change.doc.id;
              final habitData = change.doc.data();

              if (change.type == DocumentChangeType.removed) {
                await LocalDatabaseService.delete(LocalDatabaseService.boxHabits, habitId);
                AppLogger.d('SyncEngine: Remote delete synced locally for habits/$habitId');
              } else {
                if (habitData != null) {
                  final localData = LocalDatabaseService.get(LocalDatabaseService.boxHabits, habitId);
                  if (localData == null || !_areMapsEqual(localData, habitData)) {
                    await LocalDatabaseService.save(LocalDatabaseService.boxHabits, habitId, habitData);
                    AppLogger.d('SyncEngine: Remote write synced locally for habits/$habitId');
                  }
                }
              }
            }
          }, onError: (e) {
            AppLogger.e('SyncEngine: Error in real-time listener for habits of goal $goalId', e);
          });
          _habitSubscriptions[goalId] = habitSub;
        }
      }

      // Cleanup subscriptions for deleted goals
      final removedGoalIds = _habitSubscriptions.keys.where((id) => !activeGoalIds.contains(id)).toList();
      for (var goalId in removedGoalIds) {
        _habitSubscriptions[goalId]?.cancel();
        _habitSubscriptions.remove(goalId);
        AppLogger.d('SyncEngine: Cancelled habit listener for deleted goal $goalId');
      }
    });
    _subscriptions.add(goalsSub);
  }

  /// Cancels all active real-time subscriptions
  void stopRealTimeListeners() {
    AppLogger.i('SyncEngine: Stopping all real-time Firestore listeners...');
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (var sub in _habitSubscriptions.values) {
      sub.cancel();
    }
    _habitSubscriptions.clear();
  }

  /// Clean up engine subscriptions on dispose
  void dispose() {
    _authSubscription?.cancel();
    stopRealTimeListeners();
  }

  // Deep comparison helper for Maps
  bool _areMapsEqual(Map<dynamic, dynamic> map1, Map<dynamic, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key)) return false;
      final val1 = map1[key];
      final val2 = map2[key];
      if (val1 is Map && val2 is Map) {
        if (!_areMapsEqual(val1, val2)) return false;
      } else if (val1 is List && val2 is List) {
        if (!_areListsEqual(val1, val2)) return false;
      } else {
        if (val1 != val2) return false;
      }
    }
    return true;
  }

  bool _areListsEqual(List<dynamic> list1, List<dynamic> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final val1 = list1[i];
      final val2 = list2[i];
      if (val1 is Map && val2 is Map) {
        if (!_areMapsEqual(val1, val2)) return false;
      } else if (val1 is List && val2 is List) {
        if (!_areListsEqual(val1, val2)) return false;
      } else {
        if (val1 != val2) return false;
      }
    }
    return true;
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
      case 'quick_thought':
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
