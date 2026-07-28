import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/domain/repositories/goals_repository.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_event.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_state.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Fake in-memory GoalsRepository for unit testing
// ──────────────────────────────────────────────────────────────────────────────
class FakeGoalsRepository implements GoalsRepository {
  final List<Goal> _goals = [];
  final List<Habit> _habits = [];

  final _goalsController = StreamController<List<Goal>>.broadcast();
  final _habitsController = StreamController<List<Habit>>.broadcast();

  // Push an updated list to the streams (simulates Isar box change)
  void emitGoalsChanged() => _goalsController.add(_goals);
  void emitHabitsChanged() => _habitsController.add(_habits);

  void addGoal(Goal goal) {
    _goals.add(goal);
    emitGoalsChanged();
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    emitHabitsChanged();
  }

  @override
  Stream<List<Goal>> watchGoals() async* {
    yield _goals;
    yield* _goalsController.stream;
  }

  @override
  Stream<List<Habit>> watchAllHabits() async* {
    yield _habits;
    yield* _habitsController.stream;
  }

  @override
  Stream<List<Habit>> watchHabits(String goalId) async* {
    yield _habits.where((h) => h.goalId == goalId).toList();
    yield* _habitsController.stream
        .map((list) => list.where((h) => h.goalId == goalId).toList());
  }

  @override
  List<Goal> getGoals() => List.from(_goals);

  @override
  List<Habit> getHabits(String goalId) =>
      _habits.where((h) => h.goalId == goalId).toList();

  @override
  List<Habit> getAllHabits() => List.from(_habits);

  @override
  Future<void> upsertGoal(Goal goal) async {
    final idx = _goals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _goals[idx] = goal;
    } else {
      _goals.add(goal);
    }
    emitGoalsChanged();
  }

  @override
  Future<void> upsertHabit(Habit habit) async {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx >= 0) {
      _habits[idx] = habit;
    } else {
      _habits.add(habit);
    }
    emitHabitsChanged();
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    _goals.removeWhere((g) => g.id == goalId);
    _habits.removeWhere((h) => h.goalId == goalId);
    emitGoalsChanged();
    emitHabitsChanged();
  }

  @override
  Future<void> deleteHabit(String goalId, String habitId) async {
    _habits.removeWhere((h) => h.id == habitId);
    emitHabitsChanged();
  }

  @override
  Future<void> toggleHabitCompletion(String habitId, String dateStr) async {}

  @override
  Future<void> updateHabitProgress(String habitId,
      {int? timeSpent, int? currentCount}) async {}

  @override
  Future<void> fetchRemoteGoalsAndHabits() async {}

  void dispose() {
    _goalsController.close();
    _habitsController.close();
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────
Goal _goal(String id, String title) => Goal(
      id: id,
      title: title,
      mode: 'ALL',
      createdAt: '2026-07-27T10:00:00.000',
      deadline: '2026-07-31',
      dependencies: const [],
      completedDates: const [],
    );

Habit _habit(String id, String goalId, String title) => Habit(
      id: id,
      goalId: goalId,
      title: title,
      type: 'check',
      targetTime: 0,
      targetCount: 1,
      scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      reminderEnabled: false,
      completedDates: const [],
      createdAt: '2026-07-27T10:00:00.000',
    );

void main() {
  group('GoalsBloc Unit Tests', () {
    late FakeGoalsRepository repo;
    late GoalsBloc bloc;

    setUp(() {
      repo = FakeGoalsRepository();
      bloc = GoalsBloc(goalsRepository: repo);
    });

    tearDown(() {
      bloc.close();
      repo.dispose();
    });

    // ── Basic subscription ────────────────────────────────────────────────────
    test('emits GoalsLoading then GoalsLoaded on SubscribeToGoals', () async {
      await repo.upsertGoal(_goal('g1', 'My Goal'));

      final states = <GoalsState>[];
      bloc.stream.listen(states.add);

      bloc.add(SubscribeToGoals());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(states.first, isA<GoalsLoading>());
      expect(states.last, isA<GoalsLoaded>());
      expect((states.last as GoalsLoaded).goals.length, 1);
    });

    // ── Bug 2 Regression ─────────────────────────────────────────────────────
    // Verifies that GoalsBloc now subscribes to watchAllHabits(), so adding a
    // habit to boxHabits triggers a rebuild WITHOUT requiring SubscribeToGoals().
    group('Bug 2 – GoalsBloc rebuilds when boxHabits changes', () {
      test('adding a habit to an existing goal triggers GoalsLoaded rebuild', () async {
        final goal = _goal('g1', 'My Goal');
        await repo.upsertGoal(goal);

        bloc.add(SubscribeToGoals());
        await Future.delayed(const Duration(milliseconds: 50));

        // Capture state stream AFTER initial subscription
        final states = <GoalsState>[];
        final sub = bloc.stream.listen(states.add);

        // Simulate adding a habit directly to boxHabits (no SubscribeToGoals)
        final habit = _habit('h1', 'g1', 'Daily Read');
        await repo.upsertHabit(habit);
        await Future.delayed(const Duration(milliseconds: 100));

        await sub.cancel();

        // GoalsBloc must have emitted a new GoalsLoaded state
        final loadedStates = states.whereType<GoalsLoaded>().toList();
        expect(
          loadedStates,
          isNotEmpty,
          reason: 'GoalsBloc must auto-refresh when a habit is added to boxHabits',
        );

        // The new state must include the habit in habitsByGoalId
        final lastLoaded = loadedStates.last;
        expect(
          lastLoaded.habitsByGoalId['g1'],
          isNotNull,
          reason: 'habitsByGoalId should include goal g1',
        );
        expect(
          lastLoaded.habitsByGoalId['g1']!.any((h) => h.id == 'h1'),
          isTrue,
          reason: 'The newly added habit must appear in the GoalsLoaded state',
        );
      });

      test('adding a habit does NOT require a SubscribeToGoals re-subscription', () async {
        final goal = _goal('g1', 'Goal Without Re-Sub');
        await repo.upsertGoal(goal);

        bloc.add(SubscribeToGoals());
        await Future.delayed(const Duration(milliseconds: 50));

        // Verify initial empty habitsByGoalId
        expect(
          (bloc.state as GoalsLoaded).habitsByGoalId['g1'],
          anyOf(isNull, isEmpty),
          reason: 'No habits yet — habitsByGoalId[g1] should be empty',
        );

        // Add habit WITHOUT calling SubscribeToGoals
        await repo.upsertHabit(_habit('h1', 'g1', 'Morning Run'));
        await Future.delayed(const Duration(milliseconds: 100));

        // State should now reflect the new habit
        expect(bloc.state, isA<GoalsLoaded>());
        final loaded = bloc.state as GoalsLoaded;
        expect(
          loaded.habitsByGoalId['g1']?.any((h) => h.title == 'Morning Run'),
          isTrue,
          reason: 'Habit must appear without re-subscribing to GoalsBloc',
        );
      });
    });
  });
}
