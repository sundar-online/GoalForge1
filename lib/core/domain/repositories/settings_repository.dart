import '../models/settings_model.dart';

abstract class SettingsRepository {
  /// Stream settings updates.
  Stream<AppSettings> watchSettings();

  /// Get cached settings.
  AppSettings getSettings();

  /// Save or update application settings.
  Future<void> updateSettings(AppSettings settings);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteSettings();
}
