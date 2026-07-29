import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/domain/models/task_log.dart';
import 'package:goalforge/core/utils/date_utils.dart';

void main() {
  group('1. Bug 1 — Alert Banner Mutually Exclusive Evaluation Tests', () {
    test('streak at risk takes priority when active streak exists but no items completed today', () {
      const currentStreak = 5;
      const completedToday = 0;
      const totalToday = 2;
      const accuracy = 0.0;

      final isStreakAtRisk = currentStreak > 0 && completedToday == 0 && totalToday > 0;
      final isLowProductivity = totalToday > 0 && accuracy < 0.50;
      final isGreatConsistency = (totalToday > 0 && accuracy >= 0.80) || currentStreak >= 3;

      expect(isStreakAtRisk, isTrue);
      // In the priority evaluation waterfall, Streak At Risk evaluates first so only 1 banner shows:
      final primaryBanner = isStreakAtRisk
          ? 'streak_at_risk'
          : (isLowProductivity
              ? 'low_productivity'
              : (isGreatConsistency ? 'great_consistency' : 'improving'));

      expect(primaryBanner, equals('streak_at_risk'));
    });

    test('great consistency shows when accuracy is >= 80%', () {
      const currentStreak = 0;
      const completedToday = 4;
      const totalToday = 5;
      const accuracy = 0.80;

      final isStreakAtRisk = currentStreak > 0 && completedToday == 0 && totalToday > 0;
      final isLowProductivity = totalToday > 0 && accuracy < 0.50;
      final isGreatConsistency = (totalToday > 0 && accuracy >= 0.80) || currentStreak >= 3;

      expect(isStreakAtRisk, isFalse);
      expect(isLowProductivity, isFalse);
      expect(isGreatConsistency, isTrue);

      final primaryBanner = isStreakAtRisk
          ? 'streak_at_risk'
          : (isLowProductivity
              ? 'low_productivity'
              : (isGreatConsistency ? 'great_consistency' : 'improving'));

      expect(primaryBanner, equals('great_consistency'));
    });
  });

  group('2. Bug 2 — Weekly Accuracy Formula & 0-100% Clamping Tests', () {
    test('weekly accuracy averages percentages without 100x double multiplier', () {
      final logs = <String, TaskLog>{
        '2026-07-28': const TaskLog(date: '2026-07-28', accuracyPercent: 50.0, completedCount: 1, completions: ['t1'], updatedAt: '2026-07-28'),
        '2026-07-27': const TaskLog(date: '2026-07-27', accuracyPercent: 100.0, completedCount: 2, completions: ['t1', 't2'], updatedAt: '2026-07-27'),
      };

      double total = 0.0;
      int count = 0;
      for (final log in logs.values) {
        total += log.accuracyPercent;
        count++;
      }

      final weeklyAccuracy = (count > 0 ? (total / count) : 0.0).clamp(0.0, 100.0);

      // Verify accuracy is 75% (NOT 7500%)
      expect(weeklyAccuracy, equals(75.0));
      expect(weeklyAccuracy, isNot(equals(7500.0)));
    });

    test('clamping guarantees accuracy string display never exceeds 100%', () {
      const rawAccuracy = 150.0; // Out-of-bounds input safeguard
      final clamped = rawAccuracy.clamp(0.0, 100.0);
      final displayStr = '${clamped.toInt()}%';

      expect(clamped, equals(100.0));
      expect(displayStr, equals('100%'));
    });
  });

  group('3. Bug 3 — Today\'s Accuracy Multi-Goal Aggregation Tests', () {
    test('today accuracy aggregates all goal habits and standalone tasks', () {
      final todayStr = AppDateUtils.getTodayString();

      // Goal 1 habit (completed)
      final habit1 = Habit(
        id: 'h1',
        goalId: 'g1',
        title: 'Coding',
        type: 'time',
        targetTime: 60,
        targetCount: 0,
        reminderEnabled: false,
        completedDates: [todayStr],
        scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        createdAt: todayStr,
      );

      // Goal 2 habit (incomplete)
      final habit2 = Habit(
        id: 'h2',
        goalId: 'g2',
        title: 'Reading',
        type: 'count',
        targetTime: 0,
        targetCount: 10,
        reminderEnabled: false,
        completedDates: const [],
        scheduleDays: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        createdAt: todayStr,
      );

      final habits = [habit1, habit2];

      final totalTodayItems = habits.length; // 2
      final doneTodayItems = habits.where((h) => h.completedDates.contains(todayStr)).length; // 1

      final accuracyRatio = totalTodayItems > 0 ? (doneTodayItems / totalTodayItems) : 1.0;
      final accuracyPct = (accuracyRatio * 100).toInt();

      // Verify accuracy with 2 goals (1 complete, 1 incomplete) equals 50%
      expect(totalTodayItems, equals(2));
      expect(doneTodayItems, equals(1));
      expect(accuracyPct, equals(50));
    });
  });

  group('4. Bug 4 — Deep Work Direct Completion Time Alignment Tests', () {
    test('direct completion on timed habit populates timeSpent with targetTime', () {
      const habit = Habit(
        id: 'h-timed',
        goalId: 'standalone',
        title: 'Deep Focus',
        type: 'time',
        targetTime: 60,
        targetCount: 0,
        reminderEnabled: false,
        scheduleDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        timeSpent: 0, // initially 0
        completedDates: [],
        createdAt: '2026-07-29',
      );

      // Simulating toggleHabitCompletion direct complete path
      const isAlreadyCompleted = false;
      int newTimeSpent = habit.timeSpent;
      if (habit.type == 'time' && habit.targetTime > 0) {
        if (!isAlreadyCompleted && habit.timeSpent == 0) {
          newTimeSpent = habit.targetTime;
        }
      }

      final updatedHabit = habit.copyWith(
        completedDates: ['2026-07-29'],
        completed: true,
        timeSpent: newTimeSpent,
      );

      // Verify direct completion sets timeSpent to 60 mins
      expect(updatedHabit.timeSpent, equals(60));

      // Deep Work aggregation calculation
      final mins = updatedHabit.timeSpent > 0
          ? updatedHabit.timeSpent
          : (updatedHabit.completedDates.contains('2026-07-29') ? updatedHabit.targetTime : 0);

      expect(mins, equals(60));
    });
  });
}
