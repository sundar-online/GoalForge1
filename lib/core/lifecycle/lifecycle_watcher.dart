import 'package:flutter/widgets.dart';
import '../utils/logger.dart';

abstract class AppLifecycleListener {
  void onResumed();
  void onPaused();
  void onDetached();
  void onInactive();
}

class LifecycleWatcher extends WidgetsBindingObserver {
  final List<AppLifecycleListener> _listeners = [];

  void addListener(AppLifecycleListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(AppLifecycleListener listener) {
    _listeners.remove(listener);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.i('AppLifecycleState changed to: $state');
    switch (state) {
      case AppLifecycleState.resumed:
        for (var listener in _listeners) {
          listener.onResumed();
        }
        break;
      case AppLifecycleState.paused:
        for (var listener in _listeners) {
          listener.onPaused();
        }
        break;
      case AppLifecycleState.detached:
        for (var listener in _listeners) {
          listener.onDetached();
        }
        break;
      case AppLifecycleState.inactive:
        for (var listener in _listeners) {
          listener.onInactive();
        }
        break;
      case AppLifecycleState.hidden:
        // No-op or treat similarly to inactive
        break;
    }
  }
}
