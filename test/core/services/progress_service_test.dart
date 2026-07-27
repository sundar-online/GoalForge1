import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/services/progress_service.dart';

void main() {
  group('ProgressService Tests', () {
    const service = ProgressService();
    const todayStr = '2026-07-23';

    // Helper to build a minimal Goal for testing
    Goal makeGoal({
      String mode = 'ALL',
      int minHabits = 1,
      String createdAt = '2026-07-20',
      String? deadline = '2026-07-29',
      List<String> completedDates = const [],
    }) {
      return Goal(
        id: 'g1',
        title: 'Test Goal',
        mode: mode,
        minHabits: minHabits,
        createdAt: createdAt,
        deadline: deadline,
        completedDates: completedDates,
        dependencies: const [],
      );
    }

    // Helper habits — h1 completed today, h2 not
    final habits = [
      const Habit(
        id: 'h1',
        goalId: 'g1',
        title: 'Read Docs',
        type: 'check',
        targetTime: 0,
        targetCount: 1,
        scheduleDays: ['Mon', 'Tue'],
        reminderEnabled: false,
        completedDates: ['2026-07-23'],
        streak: 1,
        bestStreak: 1,
        createdAt: '2026-01-01',
      ),
      const Habit(
        id: 'h2',
        goalId: 'g1',
        title: 'Write Code',
        type: 'check',
        targetTime: 0,
        targetCount: 1,
        scheduleDays: ['Mon', 'Tue'],
        reminderEnabled: false,
        completedDates: [],
        streak: 0,
        bestStreak: 0,
        createdAt: '2026-01-01',
      ),
    ];

    test('isDailyGoalMet returns false for ALL mode with only 1/2 habits done', () {
      final met = service.isDailyGoalMet(
        mode: 'ALL',
        minHabits: 1,
        habits: habits,
        todayDateStr: todayStr,
      );
      expect(met, isFalse);
    });

    test('isDailyGoalMet returns true for ANY mode with 1/2 habits done', () {
      final met = service.isDailyGoalMet(
        mode: 'ANY',
        minHabits: 1,
        habits: habits,
        todayDateStr: todayStr,
      );
      expect(met, isTrue);
    });

    test('calculateGoalProgress returns 0% for new goal with no completed dates', () {
      final goal = makeGoal(mode: 'ALL', completedDates: const []);
      // 0 completed days, goal spans 20→29 July = 10 days
      final progress = service.calculateGoalProgress(
        goal: goal,
        habits: habits, // only 1/2 done today → does not count
        todayDateStr: todayStr,
      );
      // today's habits don't satisfy ALL → 0 completed dates → 0%
      expect(progress, equals(0.0));
    });

    test('calculateGoalProgress counts today when ALL habits done', () {
      final allDoneHabits = [
        habits[0], // completed today
        habits[0].copyWith(id: 'h2', completedDates: [todayStr]), // also done
      ];
      final goal = makeGoal(mode: 'ALL', completedDates: const []);
      // goal: 20→29 July = 10 days. 1 completed day = 10%
      final progress = service.calculateGoalProgress(
        goal: goal,
        habits: allDoneHabits,
        todayDateStr: todayStr,
      );
      expect(progress, equals(10.0));
    });

    test('calculateGoalProgress returns 0.0 when goal has no habits', () {
      final goal = makeGoal();
      final progress = service.calculateGoalProgress(
        goal: goal,
        habits: const <Habit>[],
        todayDateStr: todayStr,
      );
      expect(progress, equals(0.0));
    });
  });
}
