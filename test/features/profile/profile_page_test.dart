import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/domain/models/task.dart';
import 'package:goalforge/core/domain/models/focus_session.dart';
import 'package:goalforge/core/domain/models/xp_profile.dart';
import 'package:goalforge/core/domain/repositories/focus_repository.dart';
import 'package:goalforge/core/domain/repositories/gamification_repository.dart';
import 'package:goalforge/core/domain/repositories/goals_repository.dart';
import 'package:goalforge/core/domain/repositories/tasks_repository.dart';
import 'package:goalforge/core/services/gamification_service.dart';
import 'package:goalforge/core/theme/theme_cubit.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_state.dart' as auth;
import 'package:goalforge/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:goalforge/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:goalforge/features/dashboard/presentation/pages/home_page.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_state.dart';
import 'package:goalforge/features/tasks/presentation/bloc/tasks_bloc.dart';
import 'package:goalforge/features/tasks/presentation/bloc/tasks_state.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_state.dart';
import 'package:goalforge/features/events/presentation/bloc/events_bloc.dart';
import 'package:goalforge/features/events/presentation/bloc/events_state.dart';
import 'package:goalforge/features/logs/presentation/bloc/notes_bloc.dart';
import 'package:goalforge/features/logs/presentation/bloc/notes_state.dart';
import 'package:goalforge/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:goalforge/features/profile/presentation/pages/profile_page.dart';

class MockGamificationRepository extends Cubit<XPProfile?> implements GamificationRepository {
  XPProfile? _current;

  MockGamificationRepository(super.initial) : _current = initial;

  @override
  XPProfile? getXPProfile() => _current;

  @override
  Stream<XPProfile?> watchXPProfile() => stream;

  @override
  Future<void> updateXPProfile(XPProfile profile) async {
    _current = profile;
    emit(profile);
  }

  @override
  Future<void> fetchRemoteXPProfile() async {}
}

class MockGoalsRepository implements GoalsRepository {
  @override
  List<Goal> getGoals() => [];

  @override
  Stream<List<Goal>> watchGoals() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTasksRepository implements TasksRepository {
  @override
  List<Task> getTasks() => [];

  @override
  Stream<List<Task>> watchTasks() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFocusRepository implements FocusRepository {
  @override
  List<FocusSession> getFocusSessions() => [];

  @override
  Stream<List<FocusSession>> watchFocusSessions() => Stream.value([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDashboardBloc extends Cubit<DashboardState> implements DashboardBloc {
  MockDashboardBloc(XPProfile profile) : super(DashboardLoaded(xpProfile: profile, upcomingEvents: const []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAuthBloc extends Cubit<auth.AuthState> implements AuthBloc {
  MockAuthBloc() : super(auth.Unauthenticated());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGoalsBloc extends Cubit<GoalsState> implements GoalsBloc {
  MockGoalsBloc() : super(const GoalsLoaded(goals: [], habitsByGoalId: {}));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTasksBloc extends Cubit<TasksState> implements TasksBloc {
  MockTasksBloc() : super(const TasksLoaded(tasks: [], taskLogs: {}));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockFocusBloc extends Cubit<FocusState> implements FocusBloc {
  MockFocusBloc() : super(const FocusLoaded(sessions: [], selectedDurationMinutes: 25, remainingSeconds: 1500));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockEventsBloc extends Cubit<EventsState> implements EventsBloc {
  MockEventsBloc() : super(EventsInitial());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockNotesBloc extends Cubit<NotesState> implements NotesBloc {
  MockNotesBloc() : super(const NotesLoaded(notes: [], pinnedNotes: [], quickThoughts: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sl = GetIt.instance;

  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  void setupContainer(XPProfile profile) {
    final mockGamificationRepo = MockGamificationRepository(profile);
    final mockGoalsRepo = MockGoalsRepository();
    final mockTasksRepo = MockTasksRepository();
    final mockFocusRepo = MockFocusRepository();

    sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
    sl.registerLazySingleton<GamificationRepository>(() => mockGamificationRepo);
    sl.registerLazySingleton<GoalsRepository>(() => mockGoalsRepo);
    sl.registerLazySingleton<TasksRepository>(() => mockTasksRepo);
    sl.registerLazySingleton<FocusRepository>(() => mockFocusRepo);
    sl.registerLazySingleton<GamificationService>(
      () => GamificationService(gamificationRepository: mockGamificationRepo),
    );

    sl.registerFactory<ProfileBloc>(
      () => ProfileBloc(
        gamificationRepository: mockGamificationRepo,
        gamificationService: sl<GamificationService>(),
        goalsRepository: mockGoalsRepo,
        tasksRepository: mockTasksRepo,
        focusRepository: mockFocusRepo,
      ),
    );
  }

  Widget buildTestableWidget(Widget child, XPProfile profile) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<DashboardBloc>(create: (_) => MockDashboardBloc(profile)),
        BlocProvider<AuthBloc>(create: (_) => MockAuthBloc()),
        BlocProvider<GoalsBloc>(create: (_) => MockGoalsBloc()),
        BlocProvider<TasksBloc>(create: (_) => MockTasksBloc()),
        BlocProvider<FocusBloc>(create: (_) => MockFocusBloc()),
        BlocProvider<EventsBloc>(create: (_) => MockEventsBloc()),
        BlocProvider<NotesBloc>(create: (_) => MockNotesBloc()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Data Consistency Tests (580 XP & 2 distinct badges)', () {
    testWidgets('Home and Profile both reflect Level 4 — Practitioner and 2/34 badges with no duplicates', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Seed 580 XP and duplicate entries ['streak_3', 'streak_3', 'task_1'] to test deduplication
      const testProfile = XPProfile(
        totalXP: 580,
        level: 4,
        earnedBadges: ['streak_3', 'streak_3', 'task_1'],
        unlockedBadgesMap: {'streak_3': '2026-07-28', 'task_1': '2026-07-28'},
        xpHistory: {},
        updatedAt: '2026-07-28',
      );
      setupContainer(testProfile);

      // 1. Verify Home Page
      await tester.pumpWidget(buildTestableWidget(const HomePage(), testProfile));
      await tester.pumpAndSettle();

      expect(find.text('LEVEL 4'), findsWidgets);
      expect(find.text('Practitioner'), findsOneWidget);
      expect(find.text('220/300 to next level'), findsOneWidget);

      // 2. Verify Profile Page
      await tester.pumpWidget(buildTestableWidget(const ProfilePage(), testProfile));
      await tester.pumpAndSettle();

      expect(find.text('Level 4 — Practitioner'), findsOneWidget);
      expect(find.text('EARNED BADGES (2)'), findsOneWidget);
      expect(find.text('All (2/34)'), findsOneWidget);
      expect(find.text('2 / 34'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
