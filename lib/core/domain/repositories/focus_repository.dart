import '../models/focus_session.dart';

abstract class FocusRepository {
  /// Stream focus sessions list.
  Stream<List<FocusSession>> watchFocusSessions();

  /// Get cached focus sessions.
  List<FocusSession> getFocusSessions();

  /// Log a deep focus session.
  Future<void> logFocusSession(FocusSession session);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteFocusSessions();
}
