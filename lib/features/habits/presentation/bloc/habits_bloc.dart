import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/utils/date_utils.dart';
import 'habits_event.dart';
import 'habits_state.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  final GoalsRepository _goalsRepository;
  final GamificationService _gamificationService;

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _goalsSubscription;

  HabitsBloc({
    required GoalsRepository goalsRepository,
    required GamificationService gamificationService,
  })  : _goalsRepository = goalsRepository,
        _gamificationService = gamificationService,
        super(HabitsInitial()) {
    on<SubscribeToHabits>(_onSubscribeToHabits);
    on<_HabitsDataChanged>(_onHabitsDataChanged);
    on<ToggleHabitCompletionEvent>(_onToggleHabitCompletion);
    on<UpdateHabitProgressEvent>(_onUpdateHabitProgress);
    on<CreateStandAloneHabitEvent>(_onCreateStandAloneHabit);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<SearchHabitsEvent>(_onSearchHabits);
  }

  void _onSubscribeToHabits(SubscribeToHabits event, Emitter<HabitsState> emit) {
    emit(HabitsLoading());
    _habitsSubscription?.cancel();
    _goalsSubscription?.cancel();

    _habitsSubscription = _goalsRepository.watchAllHabits().skip(1).listen((_) {
      if (!isClosed) add(const _HabitsDataChanged());
    });

    _goalsSubscription = _goalsRepository.watchGoals().skip(1).listen((_) {
      if (!isClosed) add(const _HabitsDataChanged());
    });

    _recalculateAndEmit(emit);
  }

  void _onHabitsDataChanged(_HabitsDataChanged event, Emitter<HabitsState> emit) {
    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<HabitsState> emit) {
    try {
      final allHabits = _goalsRepository.getAllHabits();
      final goals = _goalsRepository.getGoals();

      final goalMap = <String, Goal>{};
      for (var goal in goals) {
        goalMap[goal.id] = goal;
      }

      final todayStr = AppDateUtils.getTodayString();
      final now = DateTime.now();
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final todayWeekday = weekdays[now.weekday - 1];

      final query = (state is HabitsLoaded) ? (state as HabitsLoaded).searchQuery.toLowerCase() : '';

      // Filter habits scheduled for today or daily
      final habitsToday = allHabits.where((habit) {
        final matchesDay = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(todayWeekday);
        final matchesQuery = query.isEmpty || habit.title.toLowerCase().contains(query);
        return matchesDay && matchesQuery;
      }).toList();

      final totalToday = habitsToday.length;
      final completedToday = habitsToday.where((h) => h.completedDates.contains(todayStr)).length;
      final focusPct = totalToday > 0 ? (completedToday / totalToday) * 100.0 : 100.0;

      emit(HabitsLoaded(
        habitsToday: habitsToday,
        allHabits: allHabits,
        totalTodayCount: totalToday,
        completedTodayCount: completedToday,
        focusPercentage: focusPct,
        goalMap: goalMap,
        searchQuery: query,
      ));
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> _onToggleHabitCompletion(ToggleHabitCompletionEvent event, Emitter<HabitsState> emit) async {
    try {
      await _goalsRepository.toggleHabitCompletion(event.habitId, event.dateStr);

      // Award +50 XP via GamificationService
      await _gamificationService.awardXp(50);
    } catch (e) {
      emit(HabitsError('Failed to toggle completion: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabitProgress(UpdateHabitProgressEvent event, Emitter<HabitsState> emit) async {
    try {
      await _goalsRepository.updateHabitProgress(
        event.habitId,
        timeSpent: event.timeSpent,
        currentCount: event.currentCount,
      );
    } catch (e) {
      emit(HabitsError('Failed to update progress: ${e.toString()}'));
    }
  }

  Future<void> _onCreateStandAloneHabit(CreateStandAloneHabitEvent event, Emitter<HabitsState> emit) async {
    try {
      await _goalsRepository.upsertHabit(event.habit);
    } catch (e) {
      emit(HabitsError('Failed to create habit: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteHabit(DeleteHabitEvent event, Emitter<HabitsState> emit) async {
    try {
      await _goalsRepository.deleteHabit(event.goalId, event.habitId);
    } catch (e) {
      emit(HabitsError('Failed to delete habit: ${e.toString()}'));
    }
  }

  void _onSearchHabits(SearchHabitsEvent event, Emitter<HabitsState> emit) {
    if (state is HabitsLoaded) {
      emit((state as HabitsLoaded).copyWith(searchQuery: event.query));
      _recalculateAndEmit(emit);
    }
  }

  @override
  Future<void> close() {
    _habitsSubscription?.cancel();
    _goalsSubscription?.cancel();
    return super.close();
  }
}

class _HabitsDataChanged extends HabitsEvent {
  const _HabitsDataChanged();
}
