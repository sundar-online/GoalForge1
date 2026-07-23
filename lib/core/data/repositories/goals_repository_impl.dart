import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/goal.dart';
import '../../domain/models/habit.dart';
import '../../domain/repositories/goals_repository.dart';
import '../../services/local_database_service.dart';
import '../../services/sync_engine.dart';
import '../../utils/logger.dart';

import '../../services/streak_service.dart';
import '../../services/progress_service.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SyncEngine _syncEngine;
  final StreakService _streakService;
  final ProgressService _progressService;

  GoalsRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    required SyncEngine syncEngine,
    StreakService streakService = const StreakService(),
    ProgressService progressService = const ProgressService(),
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _syncEngine = syncEngine,
        _streakService = streakService,
        _progressService = progressService;

  List<Goal> _mapGoals() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxGoals)
        .map((json) => Goal.fromJson(json))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Habit> _mapHabits(String goalId) {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxHabits)
        .map((json) => Habit.fromJson(json))
        .where((habit) => habit.goalId == goalId)
        .toList();
  }

  List<Habit> _mapAllHabits() {
    return LocalDatabaseService.getAll(LocalDatabaseService.boxHabits)
        .map((json) => Habit.fromJson(json))
        .toList();
  }

  @override
  Stream<List<Goal>> watchGoals() async* {
    yield _mapGoals();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxGoals)) {
      yield _mapGoals();
    }
  }

  @override
  List<Goal> getGoals() => _mapGoals();

  @override
  Stream<List<Habit>> watchHabits(String goalId) async* {
    yield _mapHabits(goalId);
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxHabits)) {
      yield _mapHabits(goalId);
    }
  }

  @override
  Stream<List<Habit>> watchAllHabits() async* {
    yield _mapAllHabits();
    await for (var _ in LocalDatabaseService.watchBox(LocalDatabaseService.boxHabits)) {
      yield _mapAllHabits();
    }
  }

  @override
  List<Habit> getHabits(String goalId) => _mapHabits(goalId);

  @override
  List<Habit> getAllHabits() => _mapAllHabits();

  @override
  Future<void> upsertGoal(Goal goal) async {
    await LocalDatabaseService.save(
      LocalDatabaseService.boxGoals,
      goal.id,
      goal.toJson(),
    );

    await LocalDatabaseService.addToQueue(
      goal.id,
      'goals',
      'upsert',
      goal.toJson(),
    );

    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await LocalDatabaseService.delete(LocalDatabaseService.boxGoals, goalId);

    final habits = _mapHabits(goalId);
    for (var habit in habits) {
      await LocalDatabaseService.delete(LocalDatabaseService.boxHabits, habit.id);
      await LocalDatabaseService.addToQueue(habit.id, 'habits', 'delete', habit.toJson());
    }

    await LocalDatabaseService.addToQueue(goalId, 'goals', 'delete', null);
    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    await LocalDatabaseService.save(
      LocalDatabaseService.boxHabits,
      habit.id,
      habit.toJson(),
    );

    await LocalDatabaseService.addToQueue(
      habit.id,
      'habits',
      'upsert',
      habit.toJson(),
    );

    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> toggleHabitCompletion(String habitId, String dateStr) async {
    final rawHabit = LocalDatabaseService.get(LocalDatabaseService.boxHabits, habitId);
    if (rawHabit == null) return;

    final habit = Habit.fromJson(rawHabit);
    final dates = List<String>.from(habit.completedDates);
    final isAlreadyCompleted = dates.contains(dateStr);

    if (isAlreadyCompleted) {
      dates.remove(dateStr);
    } else {
      dates.add(dateStr);
    }

    final newStreak = _streakService.calculateStreak(dates);
    final bestStreak = _streakService.calculateBestStreak(dates, habit.bestStreak);
    final updatedHabit = habit.copyWith(
      completedDates: dates,
      completed: !isAlreadyCompleted,
      streak: newStreak,
      bestStreak: bestStreak,
      lastCompletedDate: isAlreadyCompleted ? habit.lastCompletedDate : dateStr,
    );

    await upsertHabit(updatedHabit);

    // Recalculate parent goal progress via ProgressService
    if (habit.goalId.isNotEmpty) {
      final parentGoalJson = LocalDatabaseService.get(LocalDatabaseService.boxGoals, habit.goalId);
      if (parentGoalJson != null) {
        final parentGoal = Goal.fromJson(parentGoalJson);
        final siblingHabits = _mapHabits(habit.goalId);
        final progress = _progressService.calculateGoalProgress(
          mode: parentGoal.mode,
          habits: siblingHabits,
          todayDateStr: dateStr,
        );
        final updatedGoal = parentGoal.copyWith(progress: progress);
        await upsertGoal(updatedGoal);
      }
    }
  }

  @override
  Future<void> updateHabitProgress(String habitId, {int? timeSpent, int? currentCount}) async {
    final rawHabit = LocalDatabaseService.get(LocalDatabaseService.boxHabits, habitId);
    if (rawHabit == null) return;

    final habit = Habit.fromJson(rawHabit);
    final updatedHabit = habit.copyWith(
      timeSpent: timeSpent ?? habit.timeSpent,
      currentCount: currentCount ?? habit.currentCount,
    );

    await upsertHabit(updatedHabit);
  }

  @override
  Future<void> deleteHabit(String goalId, String habitId) async {
    final habit = LocalDatabaseService.get(LocalDatabaseService.boxHabits, habitId);

    await LocalDatabaseService.delete(LocalDatabaseService.boxHabits, habitId);

    await LocalDatabaseService.addToQueue(
      habitId,
      'habits',
      'delete',
      habit,
    );

    _syncEngine.processSyncQueue();
  }

  @override
  Future<void> fetchRemoteGoalsAndHabits() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    try {
      AppLogger.i('Fetching goals from Firestore...');
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('goals')
          .get();

      await LocalDatabaseService.clearBox(LocalDatabaseService.boxGoals);
      await LocalDatabaseService.clearBox(LocalDatabaseService.boxHabits);

      for (var goalDoc in goalsSnapshot.docs) {
        final goalData = goalDoc.data();
        await LocalDatabaseService.save(LocalDatabaseService.boxGoals, goalDoc.id, goalData);

        final habitsSnapshot = await goalDoc.reference.collection('habits').get();
        for (var habitDoc in habitsSnapshot.docs) {
          await LocalDatabaseService.save(LocalDatabaseService.boxHabits, habitDoc.id, habitDoc.data());
        }
      }
      AppLogger.i('Goals and habits synced from remote successfully.');
    } catch (e, stack) {
      AppLogger.e('Failed to fetch remote goals and habits', e, stack);
    }
  }
}
