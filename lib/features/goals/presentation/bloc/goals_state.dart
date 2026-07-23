import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';

abstract class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

class GoalsInitial extends GoalsState {}

class GoalsLoading extends GoalsState {}

class GoalsLoaded extends GoalsState {
  final List<Goal> goals;
  final Map<String, List<Habit>> habitsByGoalId;
  final double avgMastery;
  final int finishedCount;
  final int inProgressCount;
  final String activeTab; // 'ACTIVE', 'MISSING'

  const GoalsLoaded({
    required this.goals,
    required this.habitsByGoalId,
    this.avgMastery = 0.0,
    this.finishedCount = 0,
    this.inProgressCount = 0,
    this.activeTab = 'ACTIVE',
  });

  GoalsLoaded copyWith({
    List<Goal>? goals,
    Map<String, List<Habit>>? habitsByGoalId,
    double? avgMastery,
    int? finishedCount,
    int? inProgressCount,
    String? activeTab,
  }) {
    return GoalsLoaded(
      goals: goals ?? this.goals,
      habitsByGoalId: habitsByGoalId ?? this.habitsByGoalId,
      avgMastery: avgMastery ?? this.avgMastery,
      finishedCount: finishedCount ?? this.finishedCount,
      inProgressCount: inProgressCount ?? this.inProgressCount,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [
        goals,
        habitsByGoalId,
        avgMastery,
        finishedCount,
        inProgressCount,
        activeTab,
      ];
}

class GoalsError extends GoalsState {
  final String message;
  const GoalsError(this.message);

  @override
  List<Object?> get props => [message];
}
