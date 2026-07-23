import '../domain/models/goal.dart';
import '../domain/models/task.dart';
import '../domain/models/focus_session.dart';

class AiInsight {
  final String title;
  final String description;
  final String category; // 'STREAK', 'FOCUS', 'GOAL', 'GENERAL'
  final String tag;

  const AiInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.tag,
  });
}

class AiInsightsService {
  const AiInsightsService();

  /// Generates dynamic, data-driven AI productivity insights based on user activity
  List<AiInsight> generateInsights({
    required List<Goal> goals,
    required List<Task> tasks,
    required List<FocusSession> focusSessions,
    required int streakDays,
  }) {
    final List<AiInsight> insights = [];

    // 1. Streak Insight
    if (streakDays >= 3) {
      insights.add(AiInsight(
        title: '🔥 High Velocity Streak',
        description: 'You are on a $streakDays-day streak! Maintaining consistent momentum accelerates habit formation.',
        category: 'STREAK',
        tag: 'HOT STREAK',
      ));
    } else {
      insights.add(const AiInsight(
        title: '⚡ Daily Momentum',
        description: 'Complete at least 1 habit or task today to build your streak.',
        category: 'STREAK',
        tag: 'BUILD STREAK',
      ));
    }

    // 2. Focus Time Insight
    final totalFocusSeconds = focusSessions.fold<int>(0, (sum, s) => sum + s.timeSpentSeconds);
    final focusMinutes = (totalFocusSeconds / 60).round();
    if (focusMinutes >= 60) {
      insights.add(AiInsight(
        title: '🧠 Deep Work Master',
        description: 'You have completed $focusMinutes minutes of deep focus! Great job minimizing distractions.',
        category: 'FOCUS',
        tag: 'DEEP WORK',
      ));
    } else {
      insights.add(const AiInsight(
        title: '⏱ Focus Recommendation',
        description: 'Try running a 25-minute Pomodoro session today to boost productivity.',
        category: 'FOCUS',
        tag: 'POMODORO',
      ));
    }

    // 3. Goal Mastery Insight
    if (goals.isNotEmpty) {
      final lowestGoal = goals.reduce((a, b) => a.progress < b.progress ? a : b);
      if (lowestGoal.progress < 50.0) {
        insights.add(AiInsight(
          title: '🎯 Goal Boost: ${lowestGoal.title}',
          description: 'Mastery is currently at ${lowestGoal.progress.toInt()}%. Schedule 1-2 daily habits to increase progress.',
          category: 'GOAL',
          tag: 'ACTION NEEDED',
        ));
      } else {
        insights.add(const AiInsight(
          title: '🏆 Solid Goal Mastery',
          description: 'Your goals are progressing nicely! Keep executing daily operations.',
          category: 'GOAL',
          tag: 'ON TRACK',
        ));
      }
    }

    return insights;
  }
}
