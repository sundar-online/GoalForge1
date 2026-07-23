class AppConstants {
  AppConstants._();

  // Storage Keys
  static const String keyUserToken = 'gf_user_token';
  static const String keySettings = 'gf_settings';
  static const String keyXpProfile = 'gf_xp_profile';
  static const String keyDeletedGoalIds = 'gf_deleted_goal_ids';
  static const String keyLastResetDate = 'gf_last_reset_date';

  // Gamification & XP Matrix Constants
  static const int xpHabitComplete = 15;
  static const int xpTaskComplete = 10;
  static const int xpPerfectDay = 25;
  static const int xpFocusSession = 20;
  static const int xpStreakMilestone = 30; // Every 5 days streak milestone
  static const int xpFirstAction = 5;

  // Level Progression XP Requirements
  static const Map<int, int> levelXpMap = {
    1: 0,
    2: 100,
    3: 250,
    4: 500,
    5: 800,
    6: 1200,
    7: 1700,
    8: 2400,
    9: 3300,
    10: 4500,
    11: 6000,
    12: 8000,
  };
}
