import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/logger.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;

  SettingsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine;

  AppSettings _mapSettings() {
    final Map<String, dynamic>? data = LocalDatabaseService.get(
      LocalDatabaseService.boxSettings,
      'general',
    );
    return data != null ? AppSettings.fromJson(data) : const AppSettings();
  }

  @override
  Stream<AppSettings> watchSettings() async* {
    yield _mapSettings();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxSettings)) {
      yield _mapSettings();
    }
  }

  @override
  AppSettings getSettings() => _mapSettings();

  @override
  Future<void> updateSettings(AppSettings settings) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxSettings,
      'general',
      settings.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      'general',
      'settings',
      'upsert',
      settings.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteSettings() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching settings from Firestore...');
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('general')
          .get();

      if (doc.exists && doc.data() != null) {
        await LocalDatabaseService.save(LocalDatabaseService.boxSettings, 'general', doc.data()!);
        AppLogger.i('Settings synced from remote successfully.');
      }
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote settings', e, stack);
    }
  }
}
