import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/xp_profile.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/logger.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;

  GamificationRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine;

  XPProfile? _mapXPProfile() {
    final Map<String, dynamic>? data = LocalDatabaseService.get(
      LocalDatabaseService.boxXp,
      'profile',
    );
    return data != null ? XPProfile.fromJson(data) : null;
  }

  @override
  Stream<XPProfile?> watchXPProfile() async* {
    yield _mapXPProfile();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxXp)) {
      yield _mapXPProfile();
    }
  }

  @override
  XPProfile? getXPProfile() => _mapXPProfile();

  @override
  Future<void> updateXPProfile(XPProfile profile) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxXp,
      'profile',
      profile.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      'profile',
      'xp',
      'upsert',
      profile.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteXPProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching XP Profile from Firestore...');
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('xp')
          .doc('profile')
          .get();

      if (doc.exists && doc.data() != null) {
        await LocalDatabaseService.save(LocalDatabaseService.boxXp, 'profile', doc.data()!);
        AppLogger.i('XP Profile synced from remote successfully.');
      }
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote XP Profile', e, stack);
    }
  }
}
