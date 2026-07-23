import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/lifecycle/lifecycle_watcher.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/main_navigation_page.dart';

import 'core/services/firebase_service.dart';
import 'core/services/local_database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and Local Hive database
  await FirebaseService.init();
  await LocalDatabaseService.init();

  // Initialize dependency injection
  await initDependencies();

  // Register LifecycleWatcher observer
  WidgetsBinding.instance.addObserver(sl<LifecycleWatcher>());

  runApp(const GoalForgeApp());
}

class GoalForgeApp extends StatelessWidget {
  const GoalForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
      child: MaterialApp(
        title: 'GoalForge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: AppRouter.navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const MainNavigationPage();
        } else if (state is Unauthenticated || state is AuthError) {
          return const AuthPage();
        }
        
        // Show brand loading splash screen for AuthInitial & AuthLoading
        return const Scaffold(
          backgroundColor: Color(0xFF0F1017),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes,
                  color: AppColors.primary,
                  size: 64.0,
                ),
                SizedBox(height: 24.0),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
