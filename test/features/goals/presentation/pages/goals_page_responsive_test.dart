import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goalforge/core/theme/theme_cubit.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_bloc.dart';
import 'package:goalforge/features/goals/presentation/bloc/goals_state.dart';
import 'package:goalforge/features/goals/presentation/pages/goals_page.dart';
import 'package:goalforge/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:goalforge/features/habits/presentation/bloc/habits_state.dart';

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

void main() {
  final sl = GetIt.instance;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget buildTestableWidget(GoalsBloc goalsBloc, HabitsBloc habitsBloc) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<GoalsBloc>(create: (_) => goalsBloc),
        BlocProvider<HabitsBloc>(create: (_) => habitsBloc),
      ],
      child: const MaterialApp(
        home: GoalsPage(),
      ),
    );
  }

  group('GoalsPage Responsive Header Tests (No Layout Overflow)', () {
    testWidgets('Header renders cleanly at phone width (360x800) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      final goalsBloc = MockGoalsBloc(const GoalsLoaded(goals: [], habitsByGoalId: {}));
      final habitsBloc = MockHabitsBloc(const HabitsLoaded(habitsToday: [], allHabits: [], goalMap: {}));

      await tester.pumpWidget(buildTestableWidget(goalsBloc, habitsBloc));
      await tester.pumpAndSettle();

      expect(find.text('Goals System'), findsOneWidget);
      expect(find.text('OVERVIEW STATS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Header renders cleanly at tablet width (768x1024) without overflow', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;

      final goalsBloc = MockGoalsBloc(const GoalsLoaded(goals: [], habitsByGoalId: {}));
      final habitsBloc = MockHabitsBloc(const HabitsLoaded(habitsToday: [], allHabits: [], goalMap: {}));

      await tester.pumpWidget(buildTestableWidget(goalsBloc, habitsBloc));
      await tester.pumpAndSettle();

      expect(find.text('Goals System'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Header renders cleanly at desktop width (1200x900) without overflow', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;

      final goalsBloc = MockGoalsBloc(const GoalsLoaded(goals: [], habitsByGoalId: {}));
      final habitsBloc = MockHabitsBloc(const HabitsLoaded(habitsToday: [], allHabits: [], goalMap: {}));

      await tester.pumpWidget(buildTestableWidget(goalsBloc, habitsBloc));
      await tester.pumpAndSettle();

      expect(find.text('Goals System'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
