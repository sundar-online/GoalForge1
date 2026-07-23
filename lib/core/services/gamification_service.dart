import '../constants/app_constants.dart';
import '../domain/models/xp_profile.dart';
import '../domain/repositories/gamification_repository.dart';
import '../utils/date_utils.dart';

class LevelProgress {
  final int currentLevel;
  final int totalXP;
  final int xpInCurrentLevel;
  final int xpNeededForNextLevel;
  final double progressRatio;

  const LevelProgress({
    required this.currentLevel,
    required this.totalXP,
    required this.xpInCurrentLevel,
    required this.xpNeededForNextLevel,
    required this.progressRatio,
  });
}

class GamificationService {
  final GamificationRepository _gamificationRepository;

  const GamificationService({
    required GamificationRepository gamificationRepository,
  }) : _gamificationRepository = gamificationRepository;

  /// Calculates current level for a given total XP based on AppConstants.levelXpMap
  int calculateLevel(int totalXP) {
    int level = 1;
    AppConstants.levelXpMap.forEach((lvl, requiredXp) {
      if (totalXP >= requiredXp) {
        level = lvl;
      }
    });
    return level;
  }

  /// Calculates detailed level progress metrics (ratio, level, xp within level, needed xp)
  LevelProgress calculateLevelProgress(int totalXP) {
    final level = calculateLevel(totalXP);
    final currentLevelBaseXp = AppConstants.levelXpMap[level] ?? 0;
    final nextLevelBaseXp = AppConstants.levelXpMap[level + 1] ?? (currentLevelBaseXp + 2000);

    final xpInCurrentLevel = totalXP - currentLevelBaseXp;
    final xpNeededForNextLevel = nextLevelBaseXp - currentLevelBaseXp;
    final progressRatio = xpNeededForNextLevel > 0
        ? (xpInCurrentLevel / xpNeededForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    return LevelProgress(
      currentLevel: level,
      totalXP: totalXP,
      xpInCurrentLevel: xpInCurrentLevel,
      xpNeededForNextLevel: xpNeededForNextLevel,
      progressRatio: progressRatio,
    );
  }

  /// Evaluates and unlocks badges based on streak and total XP criteria
  List<String> evaluateBadges(XPProfile profile, {int streakDays = 0}) {
    final badges = Set<String>.from(profile.earnedBadges);

    if (profile.totalXP > 0) badges.add('recruit_initiate');
    if (streakDays >= 3) badges.add('streak_apprentice');
    if (streakDays >= 7) badges.add('streak_warrior');
    if (profile.totalXP >= 500) badges.add('focus_master');
    if (profile.level >= 5 || profile.totalXP >= 800) badges.add('forge_master');

    return badges.toList();
  }

  /// Awards XP, updates level, records daily history in `xpHistory`, and unlocks badges
  Future<XPProfile> awardXp(int amount, {int streakDays = 0}) async {
    final currentProfile = _gamificationRepository.getXPProfile() ??
        const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');

    final newTotalXp = currentProfile.totalXP + amount;
    final newLevel = calculateLevel(newTotalXp);
    final todayStr = AppDateUtils.getTodayString();

    // Update daily XP history map (YYYY-MM-DD -> totalXpEarnedToday)
    final updatedHistory = Map<String, int>.from(currentProfile.xpHistory);
    updatedHistory[todayStr] = (updatedHistory[todayStr] ?? 0) + amount;

    final tempProfile = currentProfile.copyWith(
      totalXP: newTotalXp,
      level: newLevel,
      xpHistory: updatedHistory,
    );

    final updatedBadges = evaluateBadges(tempProfile, streakDays: streakDays);
    final nowStr = DateTime.now().toIso8601String();

    final updatedProfile = tempProfile.copyWith(
      earnedBadges: updatedBadges,
      updatedAt: nowStr,
    );

    await _gamificationRepository.updateXPProfile(updatedProfile);
    return updatedProfile;
  }
}
