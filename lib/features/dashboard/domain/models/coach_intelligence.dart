import 'package:equatable/equatable.dart';

class HeroNextAction extends Equatable {
  final String title;
  final String category;
  final String type; // 'task', 'habit', 'goal'
  final int durationMins;
  final String targetId;
  final String goalId;

  const HeroNextAction({
    required this.title,
    required this.category,
    required this.type,
    this.durationMins = 25,
    required this.targetId,
    this.goalId = '',
  });

  @override
  List<Object?> get props => [title, category, type, durationMins, targetId, goalId];
}

class AtRiskHabitInfo extends Equatable {
  final String habitId;
  final String habitTitle;
  final int streakDays;
  final int riskPercent;
  final int daysMissed;
  final String explanationWhy;
  final String consequenceText;
  final String recoveryActionText;

  const AtRiskHabitInfo({
    required this.habitId,
    required this.habitTitle,
    required this.streakDays,
    required this.riskPercent,
    required this.daysMissed,
    required this.explanationWhy,
    required this.consequenceText,
    required this.recoveryActionText,
  });

  @override
  List<Object?> get props => [
        habitId,
        habitTitle,
        streakDays,
        riskPercent,
        daysMissed,
        explanationWhy,
        consequenceText,
        recoveryActionText,
      ];
}

class GoalAttentionInfo extends Equatable {
  final String goalId;
  final String goalTitle;
  final String status; // 'healthy', 'at_risk', 'critical'
  final int completionPercent;
  final String explanationWhy;
  final String nextActionText;

  const GoalAttentionInfo({
    required this.goalId,
    required this.goalTitle,
    required this.status,
    required this.completionPercent,
    required this.explanationWhy,
    required this.nextActionText,
  });

  @override
  List<Object?> get props => [
        goalId,
        goalTitle,
        status,
        completionPercent,
        explanationWhy,
        nextActionText,
      ];
}

class RecoveryProtocolInfo extends Equatable {
  final String title;
  final String explanation;
  final String microActionText;
  final int durationMins;

  const RecoveryProtocolInfo({
    required this.title,
    required this.explanation,
    required this.microActionText,
    this.durationMins = 10,
  });

  @override
  List<Object?> get props => [title, explanation, microActionText, durationMins];
}
