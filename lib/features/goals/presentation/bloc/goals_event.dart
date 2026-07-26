import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';

abstract class GoalsEvent extends Equatable {
  const GoalsEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToGoals extends GoalsEvent {}

class CreateGoalEvent extends GoalsEvent {
  final Goal goal;
  final List<Habit> habits;

  const CreateGoalEvent({
    required this.goal,
    required this.habits,
  });

  @override
  List<Object?> get props => [goal, habits];
}

class UpdateGoalEvent extends GoalsEvent {
  final Goal goal;

  const UpdateGoalEvent(this.goal);

  @override
  List<Object?> get props => [goal];
}

class DeleteGoalEvent extends GoalsEvent {
  final String goalId;

  const DeleteGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class ToggleFocusGoalEvent extends GoalsEvent {
  final String goalId;

  const ToggleFocusGoalEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class ToggleMissingDreamEvent extends GoalsEvent {
  final String goalId;

  const ToggleMissingDreamEvent(this.goalId);

  @override
  List<Object?> get props => [goalId];
}

class ReorderGoalEvent extends GoalsEvent {
  final String goalId;
  final String direction; // 'up' or 'down'

  const ReorderGoalEvent({required this.goalId, required this.direction});

  @override
  List<Object?> get props => [goalId, direction];
}

class ExtendDeadlineEvent extends GoalsEvent {
  final String goalId;
  final String newDeadline; // 'YYYY-MM-DD'

  const ExtendDeadlineEvent({required this.goalId, required this.newDeadline});

  @override
  List<Object?> get props => [goalId, newDeadline];
}

class SwitchActiveTabEvent extends GoalsEvent {
  final String activeTab;

  const SwitchActiveTabEvent(this.activeTab);

  @override
  List<Object?> get props => [activeTab];
}
