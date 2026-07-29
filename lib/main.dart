import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import 'core/utils/logger.dart';

import 'core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase Core
  try {
    await FirebaseService.init();
  } catch (e, stack) {
    AppLogger.e('Firebase Service initialization warning', e, stack);
  }

  // Initialize Local Database
  try {
    await LocalDatabaseService.init();
  } catch (e, stack) {
    AppLogger.e('Local Database Service initialization warning', e, stack);
  }

  // Initialize dependency injection
  try {
    await initDependencies();
  } catch (e, stack) {
    AppLogger.e('Dependency Injection initialization warning', e, stack);
  }

  // Register LifecycleWatcher observer
  try {
    WidgetsBinding.instance.addObserver(sl<LifecycleWatcher>());
  } catch (_) {}

  runApp(const GoalForgeApp());
}

class GoalForgeApp extends StatelessWidget {
  const GoalForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()..add(AuthCheckRequested())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: 'GoalForge',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            home: const AuthGate(),
          );
        },
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
        } else if (state is Unauthenticated || state is AuthError || state is PasswordResetSent) {
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
                  LucideIcons.target,
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
