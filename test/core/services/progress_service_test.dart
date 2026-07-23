import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/habit.dart';
import 'package:goalforge/core/services/progress_service.dart';

void main() {
  group('ProgressService Tests', () {
    const service = ProgressService();
    const todayStr = '2026-07-23';

    test('calculateGoalProgress returns correct percentage based on habit completions', () {
      final List<Habit> habits = [
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

      final progress = service.calculateGoalProgress(
        mode: 'ALL',
        habits: habits,
        todayDateStr: todayStr,
      );
      expect(progress, equals(50.0));
    });

    test('calculateGoalProgress returns 0.0 when goal has no habits', () {
      final progress = service.calculateGoalProgress(
        mode: 'ALL',
        habits: const <Habit>[],
        todayDateStr: todayStr,
      );
      expect(progress, equals(0.0));
    });
  });
}
