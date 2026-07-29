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

class LogHabitTimeEvent extends HabitsEvent {
  final String habitId;
  final int minutes;

  const LogHabitTimeEvent({required this.habitId, required this.minutes});

  @override
  List<Object?> get props => [habitId, minutes];
}

class UpdateHabitCountEvent extends HabitsEvent {
  final String habitId;
  final int delta; // +1 or -1

  const UpdateHabitCountEvent({required this.habitId, required this.delta});

  @override
  List<Object?> get props => [habitId, delta];
}

/// Fired at midnight (via an internal Timer) and on app resume after a date
/// change, so the BLoC re-evaluates today's completion state from fresh data.
class DayRolloverEvent extends HabitsEvent {
  const DayRolloverEvent();
}
