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

    // ── Bug 1 Regression ─────────────────────────────────────────────────────
    // Goals stored with a full ISO timestamp (14:00, 23:59) should compute the
    // same totalDays as a goal stored with midnight — the time component must
    // be stripped before calling .difference().inDays.
    group('Bug 1 – date-only totalDays (no off-by-one from creation time)', () {
      test('goal created at 14:00 on Jul 27, deadline Jul 31 = 5 days total', () {
        // Before the fix, deadline(midnight)−createdAt(14:00) = 3.4 days → .inDays = 3 → total = 4
        // After the fix, both stripped to date-only → 4 days diff → total = 5
        final goal = makeGoal(
          createdAt: '2026-07-27T14:00:00.000',
          deadline: '2026-07-31',
          completedDates: const [],
        );
        final allDoneHabits = [
          habits[0].copyWith(completedDates: ['2026-07-27']),
          habits[1].copyWith(completedDates: ['2026-07-27']),
        ];
        // 1 completed day out of 5 total = 20%
        final progress = service.calculateGoalProgress(
          goal: goal,
          habits: allDoneHabits,
          todayDateStr: '2026-07-27',
        );
        expect(progress, equals(20.0));
      });

      test('goal created at 23:59 on Jul 27, deadline Jul 31 = 5 days total', () {
        final goal = makeGoal(
          createdAt: '2026-07-27T23:59:59.999',
          deadline: '2026-07-31',
          completedDates: ['2026-07-27'],
        );
        // 1 pre-existing completed date, no habits → isDailyGoalMet = false
        // so today (Jul 28) doesn't add to completedDates
        // result = 1/5 = 20%
        final progress = service.calculateGoalProgress(
          goal: goal,
          habits: const [],
          todayDateStr: '2026-07-28',
        );
        expect(progress, equals(20.0));
      });

      test('date-only totalDays: goal created midnight yields same result as mid-day', () {
        final goalMidnight = makeGoal(
          createdAt: '2026-07-27T00:00:00.000',
          deadline: '2026-07-31',
          completedDates: const [],
        );
        final goalMidDay = makeGoal(
          createdAt: '2026-07-27T14:30:00.000',
          deadline: '2026-07-31',
          completedDates: const [],
        );
        final allDone = [
          habits[0].copyWith(completedDates: ['2026-07-27']),
          habits[1].copyWith(completedDates: ['2026-07-27']),
        ];
        final p1 = service.calculateGoalProgress(
            goal: goalMidnight, habits: allDone, todayDateStr: '2026-07-27');
        final p2 = service.calculateGoalProgress(
            goal: goalMidDay, habits: allDone, todayDateStr: '2026-07-27');
        // Both must be equal (5-day goal, 1 day completed = 20%)
        expect(p1, equals(p2));
        expect(p1, equals(20.0));
      });
    });
  });
}
