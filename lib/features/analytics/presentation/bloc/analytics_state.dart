import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final double weeklyAccuracyPercent;
  final int totalFocusMinutesThisWeek;
  final int completedTasksCount;
  final int activeHabitsCount;
  final int totalXP;
  final int currentLevel;
  final double levelProgressRatio;
  final List<String> earnedBadges;
  final Map<String, int> weeklyXpData; // "MON" -> XP
  final List<Goal> goalMasteryList;
  final String selectedTimeframe; // 'Weekly', 'Monthly'

  const AnalyticsLoaded({
    required this.weeklyAccuracyPercent,
    required this.totalFocusMinutesThisWeek,
    required this.completedTasksCount,
    required this.activeHabitsCount,
    required this.totalXP,
    required this.currentLevel,
    required this.levelProgressRatio,
    required this.earnedBadges,
    required this.weeklyXpData,
    required this.goalMasteryList,
    this.selectedTimeframe = 'Weekly',
  });

  AnalyticsLoaded copyWith({
    double? weeklyAccuracyPercent,
    int? totalFocusMinutesThisWeek,
    int? completedTasksCount,
    int? activeHabitsCount,
    int? totalXP,
    int? currentLevel,
    double? levelProgressRatio,
    List<String>? earnedBadges,
    Map<String, int>? weeklyXpData,
    List<Goal>? goalMasteryList,
    String? selectedTimeframe,
  }) {
    return AnalyticsLoaded(
      weeklyAccuracyPercent: weeklyAccuracyPercent ?? this.weeklyAccuracyPercent,
      totalFocusMinutesThisWeek: totalFocusMinutesThisWeek ?? this.totalFocusMinutesThisWeek,
      completedTasksCount: completedTasksCount ?? this.completedTasksCount,
      activeHabitsCount: activeHabitsCount ?? this.activeHabitsCount,
      totalXP: totalXP ?? this.totalXP,
      currentLevel: currentLevel ?? this.currentLevel,
      levelProgressRatio: levelProgressRatio ?? this.levelProgressRatio,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      weeklyXpData: weeklyXpData ?? this.weeklyXpData,
      goalMasteryList: goalMasteryList ?? this.goalMasteryList,
      selectedTimeframe: selectedTimeframe ?? this.selectedTimeframe,
    );
  }

  @override
  List<Object?> get props => [
        weeklyAccuracyPercent,
        totalFocusMinutesThisWeek,
        completedTasksCount,
        activeHabitsCount,
        totalXP,
        currentLevel,
        levelProgressRatio,
        earnedBadges,
        weeklyXpData,
        goalMasteryList,
        selectedTimeframe,
      ];
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}
