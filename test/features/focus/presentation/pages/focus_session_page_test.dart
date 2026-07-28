import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/theme/theme_cubit.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_state.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_state.dart';
import 'package:goalforge/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:goalforge/features/habits/presentation/bloc/habits_state.dart';
import 'package:goalforge/features/focus/presentation/pages/focus_session_page.dart';

class MockFocusBloc extends Cubit<FocusState> implements FocusBloc {
  MockFocusBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoalsBloc extends Cubit<GoalsState> implements GoalsBloc {
  MockGoalsBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHabitsBloc extends Cubit<HabitsState> implements HabitsBloc {
  MockHabitsBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ──────────────────────────────────────────────────────────────────────────────
// Minimal test helpers
// ──────────────────────────────────────────────────────────────────────────────
Goal _testGoal({String id = 'g1', String title = 'Test Goal'}) => Goal(
      id: id,
      title: title,
      mode: 'ALL',
      createdAt: '2026-07-27T10:00:00.000',
      deadline: '2026-07-31',
      dependencies: const [],
      completedDates: const [],
    );

Habit _timeHabit({
  String id = 'h1',
  String title = 'Reading',
  int targetTime = 30,
  int timeSpent = 5,
}) =>
    Habit(
      id: id,
      goalId: 'g1',
      title: title,
      type: 'time',
      targetTime: targetTime,
      targetCount: 0,
      scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      reminderEnabled: false,
      completedDates: const [],
      createdAt: '2026-07-27T10:00:00.000',
      timeSpent: timeSpent,
    );

Widget _buildPage(
    MockFocusBloc focusBloc, MockGoalsBloc goalsBloc, MockHabitsBloc habitsBloc) {
  return MediaQuery(
    data: const MediaQueryData(size: Size(1400, 900)),
    child: MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<FocusBloc>.value(value: focusBloc),
          BlocProvider<GoalsBloc>.value(value: goalsBloc),
          BlocProvider<HabitsBloc>.value(value: habitsBloc),
          BlocProvider<ThemeCubit>.value(value: ThemeCubit()),
        ],
        child: const FocusSessionPage(),
      ),
    ),
  );
}

void main() {
  tester_setup() {
    // 1400×900 desktop viewport
  }

  group('FocusSessionPage Widget Tests', () {
    // ── Existing: Empty State ────────────────────────────────────────────────
    testWidgets('Empty State - no mock strings or fallback headers appear on Focus page',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final focusState = const FocusLoaded(
        selectedDurationMinutes: 15,
        remainingSeconds: 900,
        isRunning: false,
        isCompleted: false,
        selectedSound: 'ALARM',
        volume: 0.75,
        sessions: [],
        totalFocusMinutesToday: 0,
        totalSessionsCount: 0,
      );

      final goalsState = const GoalsLoaded(
        goals: [],
        habitsByGoalId: {},
        avgMastery: 0.0,
        finishedCount: 0,
        inProgressCount: 0,
        missingCount: 0,
        activeTab: 'ACTIVE',
      );

      final habitsState = const HabitsLoaded(
        habitsToday: [],
        allHabits: [],
        totalTodayCount: 0,
        completedTodayCount: 0,
        focusPercentage: 100.0,
        goalMap: {},
        searchQuery: '',
      );

      final mockFocusBloc = MockFocusBloc(focusState);
      final mockGoalsBloc = MockGoalsBloc(goalsState);
      final mockHabitsBloc = MockHabitsBloc(habitsState);

      await tester.pumpWidget(
        _buildPage(mockFocusBloc, mockGoalsBloc, mockHabitsBloc),
      );

      await tester.pumpAndSettle();

      final mockStrings = [
        'Eloquent English',
        'Tech Forge',
        'Quiet Growth',
        'Alpha Build',
        'Mind Fit',
        'Logical Thinking',
        'Reading',
        'Grammar Practice',
        'Writing & Notes',
        'Primary Objectives',
        'System Routines',
        'Daily Forge',
      ];

      for (final mockStr in mockStrings) {
        expect(
          find.text(mockStr),
          findsNothing,
          reason: 'Mock string "$mockStr" was found on Focus page during 0-goals empty state!',
        );
      }

      expect(find.text('No goals yet — create one to start a focus session'), findsOneWidget);
      expect(find.text('No habits available'), findsOneWidget);
      expect(find.text('+ CREATE GOAL FIRST'), findsOneWidget);
    });

    // ── Bug 3: Focus page shows real goal + habit from GoalsBloc ────────────
    testWidgets(
        'Bug 3 – Focus page uses real GoalsBloc data, not hardcoded strings',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final goal = _testGoal(title: 'My Real Goal');
      final habit = _timeHabit(title: 'Real Habit', targetTime: 30);

      final focusState = const FocusLoaded(
        selectedDurationMinutes: 15,
        remainingSeconds: 900,
        isRunning: false,
        isCompleted: false,
        selectedSound: 'ALARM',
        volume: 0.75,
        sessions: [],
        totalFocusMinutesToday: 0,
        totalSessionsCount: 0,
      );

      final goalsState = GoalsLoaded(
        goals: [goal],
        habitsByGoalId: {
          'g1': [habit]
        },
        avgMastery: 0.0,
        finishedCount: 0,
        inProgressCount: 1,
        missingCount: 0,
        activeTab: 'ACTIVE',
      );

      final habitsState = HabitsLoaded(
        habitsToday: [habit],
        allHabits: [habit],
        totalTodayCount: 1,
        completedTodayCount: 0,
        focusPercentage: 0.0,
        goalMap: {'g1': goal},
        searchQuery: '',
      );

      await tester.pumpWidget(
        _buildPage(
          MockFocusBloc(focusState),
          MockGoalsBloc(goalsState),
          MockHabitsBloc(habitsState),
        ),
      );
      await tester.pumpAndSettle();

      // Real goal appears in dropdown
      expect(find.text('My Real Goal'), findsWidgets);
      // Real habit appears in activity dropdown (format: "Real Habit [5m/30m]")
      expect(find.textContaining('Real Habit'), findsWidgets);

      // No hardcoded legacy strings
      expect(find.text('Eloquent English'), findsNothing);
      expect(find.text('Tech Forge'), findsNothing);
      expect(find.text('Primary Objectives'), findsNothing);
    });
  });
}
