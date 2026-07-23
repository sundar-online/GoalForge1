import '../models/xp_profile.dart';

abstract class GamificationRepository {
  /// Stream XP Profile updates.
  Stream<XPProfile?> watchXPProfile();

  /// Get cached XP Profile.
  XPProfile? getXPProfile();

  /// Save or update local/remote XP Profile.
  Future<void> updateXPProfile(XPProfile profile);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteXPProfile();
}
