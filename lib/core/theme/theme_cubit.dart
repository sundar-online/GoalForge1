import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/local_database_service.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.dark) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    try {
      final savedData = LocalDatabaseService.get(LocalDatabaseService.boxSettings, 'theme_mode');
      if (savedData != null && savedData.containsKey('mode')) {
        final modeIndex = savedData['mode'] as int;
        if (modeIndex >= 0 && modeIndex < ThemeMode.values.length) {
          emit(ThemeMode.values[modeIndex]);
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    try {
      await LocalDatabaseService.save(
        LocalDatabaseService.boxSettings,
        'theme_mode',
        {'mode': mode.index},
      );
    } catch (_) {}
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
