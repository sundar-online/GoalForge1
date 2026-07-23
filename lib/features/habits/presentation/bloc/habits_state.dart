import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';

abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> habitsToday;
  final List<Habit> allHabits;
  final int totalTodayCount;
  final int completedTodayCount;
  final double focusPercentage;
  final Map<String, Goal> goalMap;
  final String searchQuery;

  const HabitsLoaded({
    required this.habitsToday,
    required this.allHabits,
    this.totalTodayCount = 0,
    this.completedTodayCount = 0,
    this.focusPercentage = 0.0,
    required this.goalMap,
    this.searchQuery = '',
  });

  HabitsLoaded copyWith({
    List<Habit>? habitsToday,
    List<Habit>? allHabits,
    int? totalTodayCount,
    int? completedTodayCount,
    double? focusPercentage,
    Map<String, Goal>? goalMap,
    String? searchQuery,
  }) {
    return HabitsLoaded(
      habitsToday: habitsToday ?? this.habitsToday,
      allHabits: allHabits ?? this.allHabits,
      totalTodayCount: totalTodayCount ?? this.totalTodayCount,
      completedTodayCount: completedTodayCount ?? this.completedTodayCount,
      focusPercentage: focusPercentage ?? this.focusPercentage,
      goalMap: goalMap ?? this.goalMap,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        habitsToday,
        allHabits,
        totalTodayCount,
        completedTodayCount,
        focusPercentage,
        goalMap,
        searchQuery,
      ];
}

class HabitsError extends HabitsState {
  final String message;
  const HabitsError(this.message);

  @override
  List<Object?> get props => [message];
}
