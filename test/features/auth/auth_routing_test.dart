import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goalforge/core/router/app_router.dart';
import 'package:goalforge/core/theme/theme_cubit.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_state.dart';
import 'package:goalforge/features/auth/presentation/pages/auth_page.dart';
import 'package:goalforge/features/main_navigation_page.dart';
import 'package:goalforge/main.dart';

class FakeAuthBloc extends Cubit<AuthState> implements AuthBloc {
  FakeAuthBloc(super.initialState);

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

  testWidgets('(a) Cold launch with no auth session asserts visible screen is AuthPage (login)', (WidgetTester tester) async {
    final authBloc = FakeAuthBloc(Unauthenticated());
    sl.registerLazySingleton<AuthBloc>(() => authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
          BlocProvider<AuthBloc>(create: (_) => authBloc),
        ],
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
          home: const AuthGate(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert that AuthPage (login screen) is rendered and MainNavigationPage is NOT rendered
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('GoalForge'), findsOneWidget);
    expect(find.byType(MainNavigationPage), findsNothing);
  });

  testWidgets('(b) Direct navigation to /home while logged out redirects to AuthPage (login)', (WidgetTester tester) async {
    final authBloc = FakeAuthBloc(Unauthenticated());
    sl.registerLazySingleton<AuthBloc>(() => authBloc);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
          BlocProvider<AuthBloc>(create: (_) => authBloc),
        ],
        child: MaterialApp(
          navigatorKey: AppRouter.navigatorKey,
          onGenerateRoute: AppRouter.generateRoute,
          initialRoute: '/home',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert that direct navigation to /home redirects to AuthPage when unauthenticated
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.byType(MainNavigationPage), findsNothing);
  });
}
