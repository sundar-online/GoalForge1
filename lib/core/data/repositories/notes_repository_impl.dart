import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/note.dart';
import '../../domain/models/quick_thought.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/logger.dart';

class NotesRepositoryImpl implements NotesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;

  NotesRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine;

  List<Note> _mapNotes() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxNotes)
        .map((json) => Note.fromJson(json))
        .toList();
  }

  List<QuickThought> _mapQuickThoughts() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxQuickThoughts)
        .map((json) => QuickThought.fromJson(json))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Stream<List<Note>> watchNotes() async* {
    yield _mapNotes();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxNotes)) {
      yield _mapNotes();
    }
  }

  @override
  List<Note> getNotes() => _mapNotes();

  @override
  Future<void> upsertNote(Note note) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxNotes,
      note.id,
      note.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      note.id,
      'notes',
      'upsert',
      note.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    // 1. Delete locally
    await LocalDatabaseService.delete(LocalDatabaseService.boxNotes, noteId);

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(noteId, 'notes', 'delete', null);

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Stream<List<QuickThought>> watchQuickThoughts() async* {
    yield _mapQuickThoughts();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxQuickThoughts)) {
      yield _mapQuickThoughts();
    }
  }

  @override
  List<QuickThought> getQuickThoughts() => _mapQuickThoughts();

  @override
  Future<void> upsertQuickThought(QuickThought thought) async {
    // 1. Save locally
    await LocalDatabaseService.save(
      LocalDatabaseService.boxQuickThoughts,
      thought.id,
      thought.toJson(),
    );

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      thought.id,
      'quick_thoughts',
      'upsert',
      thought.toJson(),
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> deleteQuickThought(String thoughtId) async {
    // 1. Delete locally
    await LocalDatabaseService.delete(LocalDatabaseService.boxQuickThoughts, thoughtId);

    // 2. Queue remote sync
    await LocalDatabaseService.addToQueue(
      thoughtId,
      'quick_thoughts',
      'delete',
      null,
    );

    // 3. Process sync
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteNotesAndThoughts() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching notes from Firestore...');
      final notesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxNotes);

      for (var doc in notesSnapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxNotes, doc.id, doc.data());
      }

      AppLogger.i('Fetching quick thoughts from Firestore...');
      final thoughtsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('quick_thoughts')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxQuickThoughts);

      for (var doc in thoughtsSnapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxQuickThoughts, doc.id, doc.data());
      }

      AppLogger.i('Notes and quick thoughts synced from remote successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote notes and quick thoughts', e, stack);
    }
  }
}
