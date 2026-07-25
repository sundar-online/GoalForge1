import 'dart:async';
import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';
import '../../utils/logger.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static Database? _db;
  static final Map<String, Map<String, String>> _inMemoryStore = {};
  static final Map<String, StreamController<void>> _watchers = {};

  static const String boxGoals = 'gf_goals';
  static const String boxHabits = 'gf_habits';
  static const String boxTasks = 'gf_tasks';
  static const String boxTaskLogs = 'gf_task_logs';
  static const String boxNotes = 'gf_notes';
  static const String boxQuickThoughts = 'gf_quick_thoughts';
  static const String boxEvents = 'gf_events';
  static const String boxXp = 'gf_xp';
  static const String boxSettings = 'gf_settings';
  static const String boxFocus = 'gf_focus';
  static const String boxSyncQueue = 'gf_sync_queue';

  static const String _dbName = 'goalforge_db';
  static const String _storeName = 'isar_docs';

  static Future<void> init() async {
    try {
      AppLogger.i('Initializing Web Local Database (IndexedDB backend)...');
      _inMemoryStore.clear();

      final idbFactory = idbFactoryBrowser;

      _db = await idbFactory.open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
          final db = event.database;
          if (!db.objectStoreNames.contains(_storeName)) {
            final store = db.createObjectStore(_storeName, keyPath: 'id');
            store.createIndex('collectionName', 'collectionName', unique: false);
          }
        },
      ).timeout(const Duration(seconds: 3));

      // Pre-populate in-memory cache from IndexedDB using store.getAll()
      if (_db != null) {
        final txn = _db!.transaction(_storeName, idbModeReadOnly);
        final store = txn.objectStore(_storeName);
        final records = await store.getAll().timeout(const Duration(seconds: 2));

        for (final record in records) {
          if (record is Map) {
            final boxName = record['collectionName'] as String?;
            final docId = record['docId'] as String?;
            final dataJson = record['dataJson'] as String?;
            if (boxName != null && docId != null && dataJson != null) {
              _inMemoryStore.putIfAbsent(boxName, () => {})[docId] = dataJson;
            }
          }
        }
      }

      AppLogger.i('Web Local Database initialized with IndexedDB backend (${_inMemoryStore.length} collections loaded).');
    } catch (e, stack) {
      AppLogger.e('Error initializing Web Local Database (IndexedDB)', e, stack);
    }
  }

  static Stream<void> watchBox(String boxName) {
    _watchers.putIfAbsent(boxName, () => StreamController<void>.broadcast());
    return _watchers[boxName]!.stream;
  }

  static void _notifyWatchers(String boxName) {
    if (_watchers.containsKey(boxName)) {
      _watchers[boxName]!.add(null);
    }
  }

  static String _recordId(String boxName, String id) => '${boxName}___$id';

  static Future<void> save(String boxName, String id, Map<String, dynamic> data) async {
    final jsonStr = jsonEncode(data);
    _inMemoryStore.putIfAbsent(boxName, () => {})[id] = jsonStr;

    if (_db != null) {
      try {
        final txn = _db!.transaction(_storeName, idbModeReadWrite);
        final store = txn.objectStore(_storeName);
        await store.put({
          'id': _recordId(boxName, id),
          'collectionName': boxName,
          'docId': id,
          'dataJson': jsonStr,
        });
      } catch (e) {
        AppLogger.e('IndexedDB save failed for $boxName/$id', e);
      }
    }

    _notifyWatchers(boxName);
  }

  static Map<String, dynamic>? get(String boxName, String id) {
    final jsonStr = _inMemoryStore[boxName]?[id];
    if (jsonStr == null) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getAll(String boxName) {
    final boxMap = _inMemoryStore[boxName];
    if (boxMap == null) return [];
    final list = <Map<String, dynamic>>[];
    for (final jsonStr in boxMap.values) {
      try {
        list.add(jsonDecode(jsonStr) as Map<String, dynamic>);
      } catch (_) {}
    }
    return list;
  }

  static Future<void> delete(String boxName, String id) async {
    _inMemoryStore[boxName]?.remove(id);

    if (_db != null) {
      try {
        final txn = _db!.transaction(_storeName, idbModeReadWrite);
        final store = txn.objectStore(_storeName);
        await store.delete(_recordId(boxName, id));
      } catch (e) {
        AppLogger.e('IndexedDB delete failed for $boxName/$id', e);
      }
    }

    _notifyWatchers(boxName);
  }

  static Future<void> clearAllBoxes() async {
    _inMemoryStore.clear();

    if (_db != null) {
      try {
        final txn = _db!.transaction(_storeName, idbModeReadWrite);
        final store = txn.objectStore(_storeName);
        await store.clear();
      } catch (e) {
        AppLogger.e('IndexedDB clearAllBoxes failed', e);
      }
    }

    for (final controller in _watchers.values) {
      controller.add(null);
    }
  }

  static Future<void> clearBox(String boxName) async {
    final boxMap = _inMemoryStore[boxName];
    final idsToDelete = boxMap != null ? boxMap.keys.toList() : [];
    _inMemoryStore[boxName]?.clear();

    if (_db != null && idsToDelete.isNotEmpty) {
      try {
        final txn = _db!.transaction(_storeName, idbModeReadWrite);
        final store = txn.objectStore(_storeName);
        for (final id in idsToDelete) {
          await store.delete(_recordId(boxName, id));
        }
      } catch (e) {
        AppLogger.e('IndexedDB clearBox failed for $boxName', e);
      }
    }

    _notifyWatchers(boxName);
  }

  // --- Sync Queue Helper methods ---
  static List<Map<String, dynamic>> getQueue() {
    return getAll(boxSyncQueue);
  }

  static Future<void> addToQueue(String id, String collection, String action, Map<String, dynamic>? payload) async {
    final key = '${collection}_${id}_${DateTime.now().millisecondsSinceEpoch}';
    final task = {
      'key': key,
      'id': id,
      'collection': collection,
      'action': action,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await save(boxSyncQueue, key, task);
    AppLogger.d('Added task to Sync Queue: $key');
  }

  static Future<void> removeFromQueue(String key) async {
    await delete(boxSyncQueue, key);
    AppLogger.d('Removed task from Sync Queue: $key');
  }
}
