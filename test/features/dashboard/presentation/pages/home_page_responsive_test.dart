import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
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

class MockFocusBloc extends Cubit<FocusState> implements FocusBloc {
  MockFocusBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotesBloc extends Cubit<NotesState> implements NotesBloc {
  MockNotesBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sl = GetIt.instance;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestableWidget({
    required DashboardBloc dashboardBloc,
    required GoalsBloc goalsBloc,
    required TasksBloc tasksBloc,
    required AuthBloc authBloc,
    required EventsBloc eventsBloc,
    required FocusBloc focusBloc,
    required NotesBloc notesBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<DashboardBloc>(create: (_) => dashboardBloc),
        BlocProvider<GoalsBloc>(create: (_) => goalsBloc),
        BlocProvider<TasksBloc>(create: (_) => tasksBloc),
        BlocProvider<AuthBloc>(create: (_) => authBloc),
        BlocProvider<EventsBloc>(create: (_) => eventsBloc),
        BlocProvider<FocusBloc>(create: (_) => focusBloc),
        BlocProvider<NotesBloc>(create: (_) => notesBloc),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    );
  }

  group('HomePage Responsive Mobile Layout Tests (360px - 414px)', () {
    const mobileWidths = [360.0, 375.0, 390.0, 414.0];

    for (final width in mobileWidths) {
      testWidgets('Home page renders without overflow at ${width.toInt()}px width', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        final dashboardBloc = MockDashboardBloc(
          const DashboardLoaded(
            focusGoal: null,
            habitsLeftToday: 0,
            xpProfile: XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '', totalXP: 0, level: 1),
            quickThoughtsCount: 0,
            upcomingEvents: [],
            weeklyAccuracy: 0.0,
            weeklyFocusDuration: '0h 0m',
            bestDay: 'N/A',
            disciplineScore: 0,
          ),
        );
        final goalsBloc = MockGoalsBloc(
          const GoalsLoaded(
            goals: [],
            habitsByGoalId: {},
            avgMastery: 0.0,
            finishedCount: 0,
            inProgressCount: 0,
            missingCount: 0,
            activeTab: 'ACTIVE',
          ),
        );
        final tasksBloc = MockTasksBloc(
          const TasksLoaded(
            tasks: [],
            taskLogs: {},
            totalCount: 0,
            completedCount: 0,
            accuracyPercent: 0.0,
          ),
        );
        final authBloc = MockAuthBloc(auth.Unauthenticated());
        final eventsBloc = MockEventsBloc(
          const EventsLoaded(
            allEvents: [],
            selectedDateEvents: [],
            upcomingEvents: [],
            selectedDateStr: '2026-07-28',
            totalEventCount: 0,
          ),
        );
        final focusBloc = MockFocusBloc(FocusInitial());
        final notesBloc = MockNotesBloc(
          const NotesLoaded(
            notes: [],
            pinnedNotes: [],
            quickThoughts: [],
            selectedCategory: 'ALL LOGS',
            searchQuery: '',
          ),
        );

        await tester.pumpWidget(buildTestableWidget(
          dashboardBloc: dashboardBloc,
          goalsBloc: goalsBloc,
          tasksBloc: tasksBloc,
          authBloc: authBloc,
          eventsBloc: eventsBloc,
          focusBloc: focusBloc,
          notesBloc: notesBloc,
        ));
        await tester.pumpAndSettle();

        expect(find.text("TODAY'S ACCURACY"), findsOneWidget);
        expect(find.text('DEEP WORK'), findsOneWidget);
        expect(find.text('Task Analytics'), findsOneWidget);
        expect(find.text('MONTHLY TRENDS'), findsOneWidget);
        expect(find.text('WEEKLY ACTIVITY'), findsOneWidget);

        // Verify no RenderFlex overflow exception was thrown
        expect(tester.takeException(), isNull);
      });
    }
  });
}
