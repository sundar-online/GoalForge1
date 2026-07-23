import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/main_navigation_page.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';
  static const String authRoute = '/auth';

  // Global key for context-free navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationPage(),
          settings: settings,
        );
      case authRoute:
        return MaterialPageRoute(
          builder: (_) => const AuthPage(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }

  // Navigation Helper utilities
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  static void pop<T>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }

  static Future<T?> pushNamedAndRemoveUntil<T>(
    String newRouteName,
    RoutePredicate predicate, {
    Object? arguments,
  }) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      newRouteName,
      predicate,
      arguments: arguments,
    );
  }
}
