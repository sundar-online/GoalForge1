import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/habit.dart';

abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToHabits extends HabitsEvent {}

class ToggleHabitCompletionEvent extends HabitsEvent {
  final String habitId;
  final String dateStr;

  const ToggleHabitCompletionEvent({
    required this.habitId,
    required this.dateStr,
  });

  @override
  List<Object?> get props => [habitId, dateStr];
}

class UpdateHabitProgressEvent extends HabitsEvent {
  final String habitId;
  final int? timeSpent;
  final int? currentCount;

  const UpdateHabitProgressEvent({
    required this.habitId,
    this.timeSpent,
    this.currentCount,
  });

  @override
  List<Object?> get props => [habitId, timeSpent, currentCount];
}

class CreateStandAloneHabitEvent extends HabitsEvent {
  final Habit habit;

  const CreateStandAloneHabitEvent(this.habit);

  @override
  List<Object?> get props => [habit];
}

class DeleteHabitEvent extends HabitsEvent {
  final String goalId;
  final String habitId;

  const DeleteHabitEvent({
    required this.goalId,
    required this.habitId,
  });

  @override
  List<Object?> get props => [goalId, habitId];
}

class SearchHabitsEvent extends HabitsEvent {
  final String query;

  const SearchHabitsEvent(this.query);

  @override
  List<Object?> get props => [query];
}
