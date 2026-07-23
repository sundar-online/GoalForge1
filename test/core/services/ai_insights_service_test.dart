import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/goal.dart';
import 'package:goalforge/core/services/ai_insights_service.dart';

void main() {
  group('AiInsightsService Tests', () {
    const service = AiInsightsService();

    test('generateInsights produces high velocity streak insight when streak >= 3', () {
      final insights = service.generateInsights(
        goals: [],
        tasks: [],
        focusSessions: [],
        streakDays: 5,
      );

      expect(insights.any((i) => i.category == 'STREAK' && i.tag == 'HOT STREAK'), isTrue);
    });

    test('generateInsights recommends goal boost when goal progress < 50%', () {
      const goal = Goal(
        id: 'g1',
        title: 'Master Architecture',
        mode: 'ALL',
        tag: 'Engineering',
        progress: 25.0,
        completedDates: [],
        dependencies: [],
        createdAt: '2026-01-01',
      );

      final insights = service.generateInsights(
        goals: [goal],
        tasks: [],
        focusSessions: [],
        streakDays: 1,
      );

      expect(insights.any((i) => i.category == 'GOAL' && i.tag == 'ACTION NEEDED'), isTrue);
    });
  });
}
