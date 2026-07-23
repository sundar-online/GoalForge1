import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import 'goals_event.dart';
import 'goals_state.dart';

class GoalsBloc extends Bloc<GoalsEvent, GoalsState> {
  final GoalsRepository _goalsRepository;
  StreamSubscription? _goalsSubscription;

  GoalsBloc({
    required GoalsRepository goalsRepository,
  })  : _goalsRepository = goalsRepository,
        super(GoalsInitial()) {
    on<SubscribeToGoals>(_onSubscribeToGoals);
    on<_GoalsDataChanged>(_onGoalsDataChanged);
    on<CreateGoalEvent>(_onCreateGoal);
    on<UpdateGoalEvent>(_onUpdateGoal);
    on<DeleteGoalEvent>(_onDeleteGoal);
    on<ToggleFocusGoalEvent>(_onToggleFocusGoal);
    on<SwitchActiveTabEvent>(_onSwitchActiveTab);
  }

  void _onSubscribeToGoals(SubscribeToGoals event, Emitter<GoalsState> emit) {
    emit(GoalsLoading());
    _goalsSubscription?.cancel();
    _goalsSubscription = _goalsRepository.watchGoals().skip(1).listen((_) {
      if (!isClosed) add(const _GoalsDataChanged());
    });
    _recalculateAndEmit(emit);
  }

  void _onGoalsDataChanged(_GoalsDataChanged event, Emitter<GoalsState> emit) {
    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<GoalsState> emit) {
    try {
      final goals = _goalsRepository.getGoals();
      final habitsMap = <String, List<Habit>>{};
      double totalMastery = 0.0;
      int finished = 0;
      int inProgress = 0;

      for (var goal in goals) {
        habitsMap[goal.id] = _goalsRepository.getHabits(goal.id);
        totalMastery += goal.progress;
        if (goal.progress >= 100.0) {
          finished++;
        } else {
          inProgress++;
        }
      }

      final avgMastery = goals.isNotEmpty ? (totalMastery / goals.length) : 0.0;
      final currentTab = (state is GoalsLoaded) ? (state as GoalsLoaded).activeTab : 'ACTIVE';

      emit(GoalsLoaded(
        goals: goals,
        habitsByGoalId: habitsMap,
        avgMastery: avgMastery,
        finishedCount: finished,
        inProgressCount: inProgress,
        activeTab: currentTab,
      ));
    } catch (e) {
      emit(GoalsError(e.toString()));
    }
  }

  Future<void> _onCreateGoal(CreateGoalEvent event, Emitter<GoalsState> emit) async {
    try {
      await _goalsRepository.upsertGoal(event.goal);
      for (var habit in event.habits) {
        await _goalsRepository.upsertHabit(habit);
      }
    } catch (e) {
      emit(GoalsError('Failed to forge goal system: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateGoal(UpdateGoalEvent event, Emitter<GoalsState> emit) async {
    try {
      await _goalsRepository.upsertGoal(event.goal);
    } catch (e) {
      emit(GoalsError('Failed to update goal: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteGoal(DeleteGoalEvent event, Emitter<GoalsState> emit) async {
    try {
      await _goalsRepository.deleteGoal(event.goalId);
    } catch (e) {
      emit(GoalsError('Failed to delete goal: ${e.toString()}'));
    }
  }

  Future<void> _onToggleFocusGoal(ToggleFocusGoalEvent event, Emitter<GoalsState> emit) async {
    try {
      final goals = _goalsRepository.getGoals();
      for (var goal in goals) {
        final isTarget = (goal.id == event.goalId);
        final updatedGoal = goal.copyWith(isFocusGoal: isTarget ? !goal.isFocusGoal : false);
        await _goalsRepository.upsertGoal(updatedGoal);
      }
    } catch (e) {
      emit(GoalsError('Failed to toggle focus goal: ${e.toString()}'));
    }
  }

  void _onSwitchActiveTab(SwitchActiveTabEvent event, Emitter<GoalsState> emit) {
    if (state is GoalsLoaded) {
      emit((state as GoalsLoaded).copyWith(activeTab: event.activeTab));
    }
  }

  @override
  Future<void> close() {
    _goalsSubscription?.cancel();
    return super.close();
  }
}

class _GoalsDataChanged extends GoalsEvent {
  const _GoalsDataChanged();
}
