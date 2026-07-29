import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../di/injection_container.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/main_navigation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String homeRoute = '/home';
  static const String authRoute = '/auth';
  static const String loginRoute = '/login';
  static const String goalsRoute = '/goals';
  static const String tasksRoute = '/tasks';
  static const String notesRoute = '/notes';
  static const String focusRoute = '/focus';
  static const String analyticsRoute = '/analytics';
  static const String profileRoute = '/profile';

  // SAST-13: navigatorKey is private to prevent external code from hijacking
  // the global navigation context.  Access is allowed only through AppRouter's
  // own navigation helper methods below.
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Read-only accessor — prefer AppRouter.pushNamed() and similar helpers
  /// instead of accessing the key directly.
  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// Returns true if the user is currently authenticated via Firebase Auth or AuthBloc.
  static bool _isUserAuthenticated() {
    try {
      if (sl.isRegistered<FirebaseAuth>() && sl<FirebaseAuth>().currentUser != null) {
        return true;
      }
    } catch (_) {}
    try {
      if (sl.isRegistered<AuthBloc>() && sl<AuthBloc>().state is Authenticated) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final authenticated = _isUserAuthenticated();

    // If unauthenticated and accessing auth/login route -> render AuthPage
    if (!authenticated) {
      return MaterialPageRoute(
        builder: (_) => const AuthPage(),
        settings: const RouteSettings(name: authRoute),
      );
    }

    // If authenticated and trying to access login/auth route -> redirect to home
    if (settings.name == authRoute || settings.name == loginRoute) {
      return MaterialPageRoute(
        builder: (_) => const MainNavigationPage(initialIndex: 0),
        settings: const RouteSettings(name: homeRoute),
      );
    }

    switch (settings.name) {
      case initialRoute:
      case homeRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 0),
          settings: settings,
        );
      case goalsRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 1),
          settings: settings,
        );
      case tasksRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 2),
          settings: settings,
        );
      case notesRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 3),
          settings: settings,
        );
      case focusRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 4),
          settings: settings,
        );
      case analyticsRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 5),
          settings: settings,
        );
      case profileRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(initialIndex: 0),
          settings: settings,
        );
    }
  }

  // Navigation Helper utilities
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  static void pop<T>([T? result]) {
    _navigatorKey.currentState!.pop<T>(result);
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return _navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }
}
