import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/local/isar_doc.dart';
import '../utils/logger.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static late Isar _isar;

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

  static Future<void> init() async {
    try {
      AppLogger.i('Initializing Isar Local Database...');
      final dir = await getApplicationDocumentsDirectory();
      _isar = await Isar.open(
        [IsarDocSchema],
        directory: dir.path,
      );
      AppLogger.i('Isar Local Database initialized.');
    } catch (e, stack) {
      AppLogger.e('Error initializing Isar Local Database', e, stack);
      rethrow;
    }
  }

  // Watch collection box changes reactively
  static Stream<void> watchBox(String boxName) {
    return _isar.isarDocs.filter().collectionNameEqualTo(boxName).watchLazy();
  }

  static Future<void> save(String boxName, String id, Map<String, dynamic> data) async {
    await _isar.writeTxn(() async {
      final existing = await _isar.isarDocs.filter().docIdEqualTo(id).and().collectionNameEqualTo(boxName).findFirst();
      final doc = IsarDoc()
        ..docId = id
        ..collectionName = boxName
        ..dataJson = jsonEncode(data);
      if (existing != null) {
        doc.id = existing.id;
      }
      await _isar.isarDocs.put(doc);
    });
  }

  static Map<String, dynamic>? get(String boxName, String id) {
    final doc = _isar.isarDocs.filter().docIdEqualTo(id).and().collectionNameEqualTo(boxName).findFirstSync();
    if (doc == null) return null;
    return jsonDecode(doc.dataJson) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> getAll(String boxName) {
    final docs = _isar.isarDocs.filter().collectionNameEqualTo(boxName).findAllSync();
    return docs.map((doc) => jsonDecode(doc.dataJson) as Map<String, dynamic>).toList();
  }

  static Future<void> delete(String boxName, String id) async {
    await _isar.writeTxn(() async {
      final doc = await _isar.isarDocs.filter().docIdEqualTo(id).and().collectionNameEqualTo(boxName).findFirst();
      if (doc != null) {
        await _isar.isarDocs.delete(doc.id);
      }
    });
  }

  static Future<void> clearAllBoxes() async {
    await _isar.writeTxn(() async {
      await _isar.isarDocs.clear();
    });
  }

  static Future<void> clearBox(String boxName) async {
    await _isar.writeTxn(() async {
      final ids = await _isar.isarDocs.filter().collectionNameEqualTo(boxName).idProperty().findAll();
      await _isar.isarDocs.deleteAll(ids);
    });
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
