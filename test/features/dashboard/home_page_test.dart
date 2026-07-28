import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/domain/models/xp_profile.dart';
import 'package:goalforge/core/theme/theme_cubit.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_state.dart' as auth;
import 'package:goalforge/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:goalforge/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:goalforge/features/dashboard/presentation/pages/home_page.dart';
import 'package:goalforge/features/events/presentation/bloc/events_bloc.dart';
import 'package:goalforge/features/events/presentation/bloc/events_state.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_state.dart';
import 'package:goalforge/features/logs/presentation/bloc/notes_bloc.dart';
import 'package:goalforge/features/logs/presentation/bloc/notes_state.dart';
import 'package:goalforge/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:goalforge/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:goalforge/core/domain/models/task.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/utils/date_utils.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_state.dart';

class MockDashboardBloc extends Cubit<DashboardState> implements DashboardBloc {
  MockDashboardBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoalsBloc extends Cubit<GoalsState> implements GoalsBloc {
  MockGoalsBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTasksBloc extends Cubit<TasksState> implements TasksBloc {
  MockTasksBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthBloc extends Cubit<auth.AuthState> implements AuthBloc {
  MockAuthBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockEventsBloc extends Cubit<EventsState> implements EventsBloc {
  MockEventsBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotesBloc extends Cubit<NotesState> implements NotesBloc {
  MockNotesBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFocusBloc extends Cubit<FocusState> implements FocusBloc {
  MockFocusBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('Empty State - no mock or stale data strings appear on dashboard', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dashboardState = DashboardLoaded(
        focusGoal: null,
        habitsLeftToday: 0,
        xpProfile: const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '', totalXP: 0, level: 1),
        quickThoughtsCount: 0,
        upcomingEvents: const [],
        weeklyAccuracy: 0.0,
        weeklyFocusDuration: '0h 0m',
        bestDay: 'N/A',
        disciplineScore: 0,
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

      final tasksState = const TasksLoaded(
        tasks: [],
        taskLogs: {},
        totalCount: 0,
        completedCount: 0,
        accuracyPercent: 0.0,
      );

      final eventsState = const EventsLoaded(
        allEvents: [],
        selectedDateEvents: [],
        upcomingEvents: [],
        selectedDateStr: '2026-07-28',
        totalEventCount: 0,
      );

      final notesState = const NotesLoaded(
        notes: [],
        pinnedNotes: [],
        quickThoughts: [],
        selectedCategory: 'ALL LOGS',
        searchQuery: '',
      );

      final mockDashboardBloc = MockDashboardBloc(dashboardState);
      final mockGoalsBloc = MockGoalsBloc(goalsState);
      final mockTasksBloc = MockTasksBloc(tasksState);
      final mockAuthBloc = MockAuthBloc(auth.Unauthenticated());
      final mockEventsBloc = MockEventsBloc(eventsState);
      final mockNotesBloc = MockNotesBloc(notesState);
      final mockFocusBloc = MockFocusBloc(FocusInitial());
      final themeCubit = ThemeCubit();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
                BlocProvider<GoalsBloc>.value(value: mockGoalsBloc),
                BlocProvider<TasksBloc>.value(value: mockTasksBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<EventsBloc>.value(value: mockEventsBloc),
                BlocProvider<NotesBloc>.value(value: mockNotesBloc),
                BlocProvider<FocusBloc>.value(value: mockFocusBloc),
                BlocProvider<ThemeCubit>.value(value: themeCubit),
              ],
              child: const HomePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final mockStrings = [
        'Eloquent English',
        'Tech Forge',
        'Quiet Growth',
        'Alpha Build',
        'Mind Fit',
        '480',
        '43d',
        '21d',
        '28d',
        '45d',
        '53%',
        '65%',
        '88',
        'Exercise Tracking',
        'Saving',
      ];

      for (final mockStr in mockStrings) {
        expect(
          find.text(mockStr),
          findsNothing,
          reason: 'Mock string "$mockStr" was found on the Home dashboard during empty state!',
        );
      }

      expect(find.text('No Focus Goal Set'), findsOneWidget);
      expect(find.text('TOTAL XP'), findsOneWidget);
      expect(find.textContaining('CREATIVE CALENDAR'), findsAtLeast(1));
    });

    testWidgets('Populated State - renders real goal mastery, XP, and streaks correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final goal1 = const Goal(
        id: 'g1',
        title: 'Quantum Physics',
        mode: 'ALL',
        progress: 0.75,
        streak: 5,
        bestStreak: 10,
        isFocusGoal: true,
        completedDates: [],
        dependencies: [],
        createdAt: '2026-01-01',
      );

      final goal2 = const Goal(
        id: 'g2',
        title: 'Master Rust',
        mode: 'ALL',
        progress: 0.40,
        streak: 12,
        bestStreak: 15,
        completedDates: [],
        dependencies: [],
        createdAt: '2026-01-01',
      );

      final dashboardState = DashboardLoaded(
        focusGoal: goal1,
        habitsLeftToday: 2,
        xpProfile: const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '', totalXP: 1500, level: 2),
        quickThoughtsCount: 1,
        upcomingEvents: const [],
        weeklyAccuracy: 0.8,
        weeklyFocusDuration: '3h 30m',
        bestDay: 'Monday',
        disciplineScore: 80,
      );

      final goalsState = GoalsLoaded(
        goals: [goal1, goal2],
        habitsByGoalId: const {},
        avgMastery: 57.5,
        finishedCount: 0,
        inProgressCount: 2,
        missingCount: 0,
        activeTab: 'ACTIVE',
      );

      final tasksState = const TasksLoaded(
        tasks: [],
        taskLogs: {},
        totalCount: 0,
        completedCount: 0,
        accuracyPercent: 0.0,
      );

      final eventsState = const EventsLoaded(
        allEvents: [],
        selectedDateEvents: [],
        upcomingEvents: [],
        selectedDateStr: '2026-07-28',
        totalEventCount: 0,
      );

      final notesState = const NotesLoaded(
        notes: [],
        pinnedNotes: [],
        quickThoughts: [],
        selectedCategory: 'ALL LOGS',
        searchQuery: '',
      );

      final mockDashboardBloc = MockDashboardBloc(dashboardState);
      final mockGoalsBloc = MockGoalsBloc(goalsState);
      final mockTasksBloc = MockTasksBloc(tasksState);
      final mockAuthBloc = MockAuthBloc(auth.Unauthenticated());
      final mockEventsBloc = MockEventsBloc(eventsState);
      final mockNotesBloc = MockNotesBloc(notesState);
      final mockFocusBloc = MockFocusBloc(FocusInitial());
      final themeCubit = ThemeCubit();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
                BlocProvider<GoalsBloc>.value(value: mockGoalsBloc),
                BlocProvider<TasksBloc>.value(value: mockTasksBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<EventsBloc>.value(value: mockEventsBloc),
                BlocProvider<NotesBloc>.value(value: mockNotesBloc),
                BlocProvider<FocusBloc>.value(value: mockFocusBloc),
                BlocProvider<ThemeCubit>.value(value: themeCubit),
              ],
              child: const HomePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Quantum Physics'), findsAtLeast(1));
      expect(find.text('75%'), findsAtLeast(1));
      expect(find.text('1500'), findsOneWidget);
    });

    testWidgets('2 Tasks Completed Today - renders 100% accuracy, 0 active, 0 pending, 1d streak', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final todayStr = AppDateUtils.getTodayString();

      final task1 = Task(
        id: 't1',
        title: 'Task 1',
        type: 'single',
        priority: 'High',
        completed: true,
        completedDates: [todayStr],
        streak: 1,
        bestStreak: 1,
        createdAt: todayStr,
      );

      final task2 = Task(
        id: 't2',
        title: 'Task 2',
        type: 'single',
        priority: 'Medium',
        completed: true,
        completedDates: [todayStr],
        streak: 1,
        bestStreak: 1,
        createdAt: todayStr,
      );

      final dashboardState = DashboardLoaded(
        focusGoal: null,
        habitsLeftToday: 0,
        xpProfile: const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '', totalXP: 10, level: 1),
        quickThoughtsCount: 0,
        upcomingEvents: const [],
        weeklyAccuracy: 1.0,
        weeklyFocusDuration: '0h 0m',
        bestDay: 'Tuesday',
        disciplineScore: 100,
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

      final tasksState = TasksLoaded(
        tasks: [task1, task2],
        taskLogs: const {},
        totalCount: 2,
        completedCount: 2,
        accuracyPercent: 100.0,
      );

      final eventsState = const EventsLoaded(
        allEvents: [],
        selectedDateEvents: [],
        upcomingEvents: [],
        selectedDateStr: '2026-07-28',
        totalEventCount: 0,
      );

      final notesState = const NotesLoaded(
        notes: [],
        pinnedNotes: [],
        quickThoughts: [],
        selectedCategory: 'ALL LOGS',
        searchQuery: '',
      );

      final mockDashboardBloc = MockDashboardBloc(dashboardState);
      final mockGoalsBloc = MockGoalsBloc(goalsState);
      final mockTasksBloc = MockTasksBloc(tasksState);
      final mockAuthBloc = MockAuthBloc(auth.Unauthenticated());
      final mockEventsBloc = MockEventsBloc(eventsState);
      final mockNotesBloc = MockNotesBloc(notesState);
      final mockFocusBloc = MockFocusBloc(FocusInitial());
      final themeCubit = ThemeCubit();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
                BlocProvider<GoalsBloc>.value(value: mockGoalsBloc),
                BlocProvider<TasksBloc>.value(value: mockTasksBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<EventsBloc>.value(value: mockEventsBloc),
                BlocProvider<NotesBloc>.value(value: mockNotesBloc),
                BlocProvider<FocusBloc>.value(value: mockFocusBloc),
                BlocProvider<ThemeCubit>.value(value: themeCubit),
              ],
              child: const HomePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assertions for 2 tasks completed today
      expect(find.text('100%'), findsAtLeast(1));
      expect(find.text('Elite Performance'), findsOneWidget);
      expect(find.text('OPTIMAL DISCIPLINE'), findsOneWidget);
      expect(find.text('0'), findsAtLeast(1)); // 0 PENDING
      expect(find.text('2'), findsAtLeast(2)); // 2 TOTAL ACTIVE, 2 DONE TODAY
      expect(find.text('1d'), findsAtLeast(2)); // 1d CURRENT STREAK, 1d BEST STREAK
    });

    testWidgets('Bug A & B Sync Test - Deep Work shows 16m logged habits and Task Analytics shows 2 total / 1 done / 1 pending', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final todayStr = AppDateUtils.getTodayString();

      // Seed 2 time-based habits logged today: 15m and 1m = 16m total
      final habit1 = Habit(
        id: 'h1',
        goalId: 'g1',
        title: 'New Content',
        type: 'time',
        targetTime: 15,
        targetCount: 1,
        scheduleDays: const ['Mon', 'Tue', 'Wed'],
        reminderEnabled: false,
        timeSpent: 15,
        completedDates: [todayStr],
        createdAt: todayStr,
      );
      final habit2 = Habit(
        id: 'h2',
        goalId: 'g1',
        title: 'nothing',
        type: 'time',
        targetTime: 1,
        targetCount: 1,
        scheduleDays: const ['Mon', 'Tue', 'Wed'],
        reminderEnabled: false,
        timeSpent: 1,
        completedDates: [todayStr],
        createdAt: todayStr,
      );

      final goal = Goal(
        id: 'g1',
        title: 'Tech Goal',
        mode: 'ALL',
        createdAt: todayStr,
        completedDates: [todayStr],
        dependencies: const [],
      );

      final goalsState = GoalsLoaded(
        goals: [goal],
        habitsByGoalId: {
          'g1': [habit1, habit2]
        },
        avgMastery: 100.0,
        finishedCount: 1,
        inProgressCount: 0,
        missingCount: 0,
        activeTab: 'ACTIVE',
      );

      // Seed 2 tasks: 1 done, 1 pending
      final task1 = Task(
        id: 't1',
        title: 'Done Task',
        type: 'single',
        priority: 'High',
        completed: true,
        completedDates: [todayStr],
        streak: 1,
        bestStreak: 1,
        createdAt: todayStr,
      );

      final task2 = Task(
        id: 't2',
        title: 'Pending Task',
        type: 'single',
        priority: 'Medium',
        completed: false,
        completedDates: const [],
        streak: 0,
        bestStreak: 0,
        createdAt: todayStr,
      );

      final tasksState = TasksLoaded(
        tasks: [task1, task2],
        allTasks: [task1, task2],
        taskLogs: const {},
        totalCount: 2,
        completedCount: 1,
        accuracyPercent: 50.0,
      );

      final dashboardState = DashboardLoaded(
        focusGoal: goal,
        habitsLeftToday: 0,
        xpProfile: const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '', totalXP: 10, level: 1),
        quickThoughtsCount: 0,
        upcomingEvents: const [],
        weeklyAccuracy: 0.5,
        weeklyFocusDuration: '0h 16m',
        bestDay: 'Tuesday',
        disciplineScore: 50,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1400, 900)),
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardBloc>.value(value: MockDashboardBloc(dashboardState)),
                BlocProvider<GoalsBloc>.value(value: MockGoalsBloc(goalsState)),
                BlocProvider<TasksBloc>.value(value: MockTasksBloc(tasksState)),
                BlocProvider<AuthBloc>.value(value: MockAuthBloc(auth.Unauthenticated())),
                BlocProvider<EventsBloc>.value(value: MockEventsBloc(const EventsLoaded(allEvents: [], selectedDateEvents: [], upcomingEvents: [], selectedDateStr: '2026-07-28', totalEventCount: 0))),
                BlocProvider<NotesBloc>.value(value: MockNotesBloc(const NotesLoaded(notes: [], pinnedNotes: [], quickThoughts: [], selectedCategory: 'ALL LOGS', searchQuery: ''))),
                BlocProvider<FocusBloc>.value(value: MockFocusBloc(FocusInitial())),
                BlocProvider<ThemeCubit>.value(value: ThemeCubit()),
              ],
              child: const HomePage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Deep Work card: 15m + 1m = 16m -> 00:16 HRS
      expect(find.text('00:16'), findsOneWidget);
      expect(find.text('🔥 16m deep focus today'), findsOneWidget);

      // Task Analytics: 2 TOTAL ACTIVE, 1 DONE TODAY, 1 PENDING
      expect(find.text('2'), findsAtLeast(1)); // 2 TOTAL ACTIVE
      expect(find.text('1'), findsAtLeast(2)); // 1 DONE TODAY, 1 PENDING
    });
  });
}
