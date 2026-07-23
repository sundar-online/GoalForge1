import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/task.dart';
import '../../domain/models/task_log.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_engine.dart';
import '../../services/streak_service.dart';
import '../../utils/logger.dart';

class TasksRepositoryImpl implements TasksRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;
  final StreakService _streakService;

  TasksRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
    StreakService streakService = const StreakService(),
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine,
        _streakService = streakService;

  List<Task> _mapTasks() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxTasks)
        .map((json) => Task.fromJson(json))
        .toList();
  }

  Map<String, TaskLog> _mapTaskLogs() {
    final logs = LocalDatabaseService.getAll(LocalDatabaseService.boxTaskLogs)
        .map((json) => TaskLog.fromJson(json));
    
    final Map<String, TaskLog> logsMap = {};
    for (var log in logs) {
      logsMap[log.date] = log;
    }
    return logsMap;
  }

  @override
  Stream<List<Task>> watchTasks() async* {
    yield _mapTasks();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxTasks)) {
      yield _mapTasks();
    }
  }

  @override
  List<Task> getTasks() => _mapTasks();

  @override
  Future<void> upsertTask(Task task) async {
    await LocalDatabaseService.save(
      LocalDatabaseService.boxTasks,
      task.id,
      task.toJson(),
    );

    await LocalDatabaseService.addToQueue(
      task.id,
      'tasks',
      'upsert',
      task.toJson(),
    );

    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> toggleTaskCompletion(String taskId, String dateStr) async {
    final rawTask = LocalDatabaseService.get(LocalDatabaseService.boxTasks, taskId);
    if (rawTask == null) return;

    final task = Task.fromJson(rawTask);
    final dates = List<String>.from(task.completedDates);
    final isCompleted = dates.contains(dateStr);

    if (isCompleted) {
      dates.remove(dateStr);
    } else {
      dates.add(dateStr);
    }

    final newStreak = _streakService.calculateStreak(dates);
    final bestStreak = _streakService.calculateBestStreak(dates, task.bestStreak);

    final updatedTask = task.copyWith(
      completedDates: dates,
      completed: !isCompleted,
      streak: newStreak,
      bestStreak: bestStreak,
    );

    await upsertTask(updatedTask);

    // Update TaskLog entry for dateStr
    final rawLog = LocalDatabaseService.get(LocalDatabaseService.boxTaskLogs, dateStr);
    TaskLog existingLog;
    if (rawLog != null) {
      existingLog = TaskLog.fromJson(rawLog);
    } else {
      existingLog = TaskLog(
        date: dateStr,
        completedCount: 0,
        accuracyPercent: 0.0,
        completions: const [],
        updatedAt: DateTime.now().toIso8601String(),
      );
    }

    final completionsList = List<String>.from(existingLog.completions);
    if (!isCompleted) {
      if (!completionsList.contains(taskId)) completionsList.add(taskId);
    } else {
      completionsList.remove(taskId);
    }

    final allTasks = _mapTasks();
    final completedCount = completionsList.length;
    final accuracyPercent = allTasks.isNotEmpty ? ((completedCount / allTasks.length) * 100.0).clamp(0.0, 100.0) : 100.0;

    final updatedLog = existingLog.copyWith(
      completedCount: completedCount,
      accuracyPercent: accuracyPercent,
      completions: completionsList,
      updatedAt: DateTime.now().toIso8601String(),
    );

    await upsertTaskLog(updatedLog);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await LocalDatabaseService.delete(LocalDatabaseService.boxTasks, taskId);
    await LocalDatabaseService.addToQueue(taskId, 'tasks', 'delete', null);
    _syncEngine.processSyncQueue();
  }

  @override
  Stream<Map<String, TaskLog>> watchTaskLogs() async* {
    yield _mapTaskLogs();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxTaskLogs)) {
      yield _mapTaskLogs();
    }
  }

  @override
  Map<String, TaskLog> getTaskLogs() => _mapTaskLogs();

  @override
  Future<void> upsertTaskLog(TaskLog log) async {
    await LocalDatabaseService.save(
      LocalDatabaseService.boxTaskLogs,
      log.date,
      log.toJson(),
    );

    await LocalDatabaseService.addToQueue(
      log.date,
      'task_logs',
      'upsert',
      log.toJson(),
    );

    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteTasksAndLogs() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching tasks from Firestore...');
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxTasks);

      for (var doc in tasksSnapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxTasks, doc.id, doc.data());
      }

      AppLogger.i('Fetching task logs from Firestore...');
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('task_logs')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxTaskLogs);

      for (var doc in logsSnapshot.docs) {
        await LocalDatabaseService.save(LocalDatabaseService.boxTaskLogs, doc.id, doc.data());
      }

      AppLogger.i('Tasks and task logs synced from remote successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote tasks and logs', e, stack);
    }
  }
}
