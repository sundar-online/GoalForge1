import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../domain/models/badge_model.dart';
import '../domain/models/story_moment.dart';
import '../domain/models/xp_profile.dart';
import '../domain/models/xp_transaction.dart';
import '../domain/repositories/gamification_repository.dart';
import '../gamification/badges_catalog.dart';
import '../utils/date_utils.dart';
import '../utils/logger.dart';

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
  final GamificationRepository? _gamificationRepository;
  final FirebaseFunctions _functions;

  GamificationService({
    GamificationRepository? gamificationRepository,
    FirebaseFunctions? functions,
  })  : _gamificationRepository = gamificationRepository,
        _functions = functions ?? FirebaseFunctions.instance;

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

  /// Evaluates and unlocks badges from BadgesCatalog based on metrics
  Map<String, String> evaluateBadges(
    XPProfile profile, {
    int streakDays = 0,
    int completedTasksCount = 0,
    int completedHabitsCount = 0,
    int focusMinutes = 0,
    int perfectDaysCount = 0,
    int completedGoalsCount = 0,
  }) {
    final unlocked = Map<String, String>.from(profile.unlockedBadgesMap);
    final nowIso = DateTime.now().toIso8601String();

    for (final badge in BadgesCatalog.allBadges) {
      if (unlocked.containsKey(badge.id)) continue;

      bool isUnlocked = false;
      switch (badge.requirementType) {
        case BadgeRequirementType.streak:
          isUnlocked = streakDays >= badge.targetValue;
          break;
        case BadgeRequirementType.completedTasks:
          isUnlocked = completedTasksCount >= badge.targetValue;
          break;
        case BadgeRequirementType.completedHabits:
          isUnlocked = completedHabitsCount >= badge.targetValue;
          break;
        case BadgeRequirementType.focusMinutes:
          isUnlocked = focusMinutes >= badge.targetValue;
          break;
        case BadgeRequirementType.perfectDays:
          isUnlocked = perfectDaysCount >= badge.targetValue;
          break;
        case BadgeRequirementType.totalXP:
          isUnlocked = profile.totalXP >= badge.targetValue;
          break;
        case BadgeRequirementType.completedGoals:
          isUnlocked = completedGoalsCount >= badge.targetValue;
          break;
      }

      if (isUnlocked) {
        unlocked[badge.id] = nowIso;
      }
    }

    return unlocked;
  }

  /// Awards XP via the server-side `awardXp` Cloud Function.
  ///
  /// Security model (SAST-05):
  ///   - The Cloud Function verifies the caller's Firebase Auth UID and validates
  ///     the amount server-side — direct Firestore writes to the XP document are
  ///     no longer permitted from the client.
  ///   - The Function uses runTransaction() internally, eliminating the race
  ///     condition that existed in the previous client-side implementation.
  ///
  /// The local profile returned here is an **optimistic** projection built from
  /// the cached profile + [amount].  The authoritative values are committed by
  /// the Function; the repository's real-time listener will reconcile any drift.
  Future<XPProfile> awardXp(
    int amount, {
    String title = 'Activity Completed',
    String type = 'general',
    int streakDays = 0,
    int completedTasksCount = 0,
    int completedHabitsCount = 0,
    int focusMinutes = 0,
    int perfectDaysCount = 0,
    int completedGoalsCount = 0,
  }) async {
    final currentProfile = _gamificationRepository?.getXPProfile() ??
        const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');

    // Build optimistic profile for immediate UI feedback.
    final optimisticProfile = _buildUpdatedProfile(
      currentProfile,
      amount,
      title: title,
      type: type,
      streakDays: streakDays,
      completedTasksCount: completedTasksCount,
      completedHabitsCount: completedHabitsCount,
      focusMinutes: focusMinutes,
      perfectDaysCount: perfectDaysCount,
      completedGoalsCount: completedGoalsCount,
    );

    // Delegate the authoritative write to the server-side Cloud Function.
    // The Function performs atomic read-modify-write via runTransaction().
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw StateError('awardXp: cannot award XP — user is not authenticated.');
      }
      final callable = _functions.httpsCallable('awardXp');
      await callable.call<Map<String, dynamic>>({
        'uid': uid,
        'amount': amount,
        'reason': title,
      });
    } on FirebaseFunctionsException catch (e) {
      AppLogger.e('awardXp Cloud Function error: [${e.code}]');
      // Surface the error so callers can handle it; do not silently swallow.
      rethrow;
    } catch (e) {
      AppLogger.e('awardXp: unexpected error calling Cloud Function');
      rethrow;
    }

    return optimisticProfile;
  }

  /// Pure function: builds an updated [XPProfile] from [current] + [amount].
  /// Extracted so it can be called from both the Firestore transaction
  /// and the local fallback without duplicating logic.
  XPProfile _buildUpdatedProfile(
    XPProfile currentProfile,
    int amount, {
    required String title,
    required String type,
    required int streakDays,
    required int completedTasksCount,
    required int completedHabitsCount,
    required int focusMinutes,
    required int perfectDaysCount,
    required int completedGoalsCount,
  }) {
    final newTotalXp = currentProfile.totalXP + amount;
    final newLevel = calculateLevel(newTotalXp);
    final todayStr = AppDateUtils.getTodayString();
    final nowIso = DateTime.now().toIso8601String();

    final updatedHistory = Map<String, int>.from(currentProfile.xpHistory);
    updatedHistory[todayStr] = (updatedHistory[todayStr] ?? 0) + amount;

    final newTx = XpTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      timestamp: nowIso,
      type: type,
    );
    final updatedTransactions = [newTx, ...currentProfile.transactions].take(50).toList();

    final tempProfile = currentProfile.copyWith(
      totalXP: newTotalXp,
      level: newLevel,
      xpHistory: updatedHistory,
      transactions: updatedTransactions,
    );

    final unlockedBadges = evaluateBadges(
      tempProfile,
      streakDays: streakDays,
      completedTasksCount: completedTasksCount,
      completedHabitsCount: completedHabitsCount,
      focusMinutes: focusMinutes,
      perfectDaysCount: perfectDaysCount,
      completedGoalsCount: completedGoalsCount,
    );

    return tempProfile.copyWith(
      earnedBadges: unlockedBadges.keys.toList(),
      unlockedBadgesMap: unlockedBadges,
      updatedAt: nowIso,
    );
  }

  /// Auto-generates a Story Moment reflection when a goal reaches 100% completion
  Future<XPProfile> recordGoalCompletion(String goalId, String goalTitle) async {
    final currentProfile = _gamificationRepository?.getXPProfile() ??
        const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');

    // Check if moment already recorded for this goal
    if (currentProfile.storyMoments.any((s) => s.goalId == goalId)) {
      return currentProfile;
    }

    final nowIso = DateTime.now().toIso8601String();
    final newMoment = StoryMoment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      goalId: goalId,
      goalTitle: goalTitle,
      reflectionText: 'Mastered target "$goalTitle" with 100% completion! A milestone preserved in your GoalForge history.',
      unlockedAt: nowIso,
    );

    final updatedMoments = [newMoment, ...currentProfile.storyMoments];
    final updatedProfile = currentProfile.copyWith(
      storyMoments: updatedMoments,
      updatedAt: nowIso,
    );

    if (_gamificationRepository != null) {
      await _gamificationRepository!.updateXPProfile(updatedProfile);
    }
    // Award Goal completion XP (+50 XP)
    return awardXp(
      50,
      title: 'Completed Goal: $goalTitle',
      type: 'goal',
      completedGoalsCount: updatedMoments.length,
    );
  }
}
