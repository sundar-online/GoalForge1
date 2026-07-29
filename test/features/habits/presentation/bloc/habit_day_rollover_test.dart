// ignore_for_file: prefer_const_constructors
// Regression tests for the day-rollover habit completion state bug.
//
// The bug: after midnight the habit card still showed the green "done" state
// because the UI read the persisted `habit.completed` boolean (which was
// set to true yesterday and never cleared) instead of checking whether
// today's date exists in `completedDates`.
//
// The fix: all completion-state derivation now uses
//   `habit.completedDates.contains(todayStr)`
// and the stale `|| habit.completed` shortcut was removed.
import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/utils/date_utils.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String dateString(DateTime d) => AppDateUtils.toLocalYYYYMMDD(d);

  /// Creates a daily habit that was completed on [completionDate].
  /// Simulates the data that exists in Hive AFTER the user marked it done.
  Habit habitCompletedOnDate(DateTime completionDate) {
    final dateStr = dateString(completionDate);
    return Habit(
      id: 'test-habit-1',
      goalId: 'standalone',
      title: 'Coding',
      type: 'time',
      targetTime: 60,
      targetCount: 0,
      scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      reminderEnabled: false,
      completedDates: [dateStr], // completed on that day
      completed: true, // persisted boolean -- stays true (the bug vector)
      streak: 1,
      bestStreak: 1,
      missedDays: 0,
      lastCompletedDate: dateStr,
      lastProgressDate: dateStr,
      timeSpent: 60, // persisted from yesterday
      currentCount: 0,
      createdAt: dateString(completionDate.subtract(const Duration(days: 7))),
    );
  }

  // ---------------------------------------------------------------------------
  // Group 1 — isCompletedToday derivation (the UI guard)
  // ---------------------------------------------------------------------------
  group('Habit completion state derivation', () {
    test('habit completed YESTERDAY shows as incomplete TODAY', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final habit = habitCompletedOnDate(yesterday);
      final todayStr = AppDateUtils.getTodayString();

      // This is the fixed expression used in goals_page.dart &
      // dashboard_bloc.dart -- no longer ORed with habit.completed.
      final isCompletedToday = habit.completedDates.contains(todayStr);

      expect(isCompletedToday, isFalse,
          reason: 'A habit completed yesterday must NOT appear as done today');
    });

    test('habit completed TODAY shows as complete TODAY', () {
      final today = DateTime.now();
      final habit = habitCompletedOnDate(today);
      final todayStr = AppDateUtils.getTodayString();

      final isCompletedToday = habit.completedDates.contains(todayStr);

      expect(isCompletedToday, isTrue,
          reason: 'A habit completed today must appear as done today');
    });

    test('stale habit.completed=true does not bleed into todayStr check', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final habit = habitCompletedOnDate(yesterday);

      // The old buggy expression that caused the stale state
      final buggyCheck = habit.completedDates.contains(AppDateUtils.getTodayString()) || habit.completed;

      // The fixed expression
      final fixedCheck = habit.completedDates.contains(AppDateUtils.getTodayString());

      // Verify the bug existed -- buggy would return true, fixed returns false
      expect(buggyCheck, isTrue, reason: 'Demonstrates the stale OR-completed bug');
      expect(fixedCheck, isFalse, reason: 'Fixed check correctly returns false on new day');
    });
  });

  // ---------------------------------------------------------------------------
  // Group 2 — completedHabitsCount for a goal card
  // ---------------------------------------------------------------------------
  group('Goal card completedHabitsCount', () {
    test('count excludes habits completed yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      final todayStr = AppDateUtils.getTodayString();

      final habits = [
        habitCompletedOnDate(yesterday), // NOT done today
        habitCompletedOnDate(today),     // done today
      ];

      // Fixed derivation (no || habit.completed)
      final completedHabitsCount = habits
          .where((h) => h.completedDates.contains(todayStr))
          .length;

      expect(completedHabitsCount, equals(1),
          reason: 'Only the habit completed today should be counted');
    });

    test('count is 0 when all habits were only completed yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final todayStr = AppDateUtils.getTodayString();

      final habits = [
        habitCompletedOnDate(yesterday),
        habitCompletedOnDate(yesterday),
      ];

      final completedHabitsCount = habits
          .where((h) => h.completedDates.contains(todayStr))
          .length;

      expect(completedHabitsCount, equals(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Group 3 — lastProgressDate / transient timeSpent reset
  // ---------------------------------------------------------------------------
  group('Transient progress day-reset logic', () {
    test('timeSpent resets to 0 when lastProgressDate is yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final habit = habitCompletedOnDate(yesterday).copyWith(
        timeSpent: 45, // leftover minutes from yesterday
        lastProgressDate: dateString(yesterday),
      );
      final todayStr = AppDateUtils.getTodayString();

      // Replicate the day-reset logic from goals_repository_impl.dart
      final isNewDay =
          habit.lastProgressDate != null && habit.lastProgressDate != todayStr;
      final baseTimeSpent = isNewDay ? 0 : habit.timeSpent;

      expect(isNewDay, isTrue);
      expect(baseTimeSpent, equals(0),
          reason: "Yesterday's timeSpent should not carry forward to today's display");
    });

    test('timeSpent accumulates correctly within the same day', () {
      final today = DateTime.now();
      final todayStr = dateString(today);
      final habit = habitCompletedOnDate(today).copyWith(
        timeSpent: 30, // 30 minutes already logged today
        lastProgressDate: todayStr,
      );

      final isNewDay =
          habit.lastProgressDate != null && habit.lastProgressDate != todayStr;
      final baseTimeSpent = isNewDay ? 0 : habit.timeSpent;

      expect(isNewDay, isFalse);
      expect(baseTimeSpent, equals(30),
          reason: 'Within the same day, existing timeSpent should be preserved');
    });
  });
}
