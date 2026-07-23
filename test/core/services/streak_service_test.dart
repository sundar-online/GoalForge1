import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/services/streak_service.dart';

void main() {
  group('StreakService Tests', () {
    const service = StreakService();

    test('calculateStreak returns correct consecutive days count', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final dates = [todayStr, yesterdayStr];
      final streak = service.calculateStreak(dates);
      expect(streak, equals(2));
    });

    test('calculateStreak returns 0 when no dates completed', () {
      final streak = service.calculateStreak([]);
      expect(streak, equals(0));
    });

    test('calculateMaxGlobalStreak merges multiple sets of completion dates', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      final set1 = [todayStr];
      final set2 = [yesterdayStr];
      final maxStreak = service.calculateMaxGlobalStreak([set1, set2]);
      expect(maxStreak, equals(2));
    });
  });
}
