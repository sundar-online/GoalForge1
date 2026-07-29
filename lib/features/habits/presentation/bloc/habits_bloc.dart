import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import '../../../../core/lifecycle/lifecycle_watcher.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/utils/date_utils.dart';
import 'habits_event.dart';
import 'habits_state.dart';

class HabitsBloc extends Bloc<HabitsEvent, HabitsState> implements AppLifecycleListener {
  final GoalsRepository _goalsRepository;
  final GamificationService _gamificationService;
  final LifecycleWatcher? _lifecycleWatcher;

  StreamSubscription? _habitsSubscription;
  StreamSubscription? _goalsSubscription;

  /// Fires once just after the next calendar midnight to trigger a
  /// DayRolloverEvent. Re-schedules itself for the following midnight.
  Timer? _midnightTimer;

  /// Tracks the last date string seen so the resume hook only fires an event
  /// when an actual date change has occurred (not just a foreground/background
  /// cycle within the same day).
  String _lastKnownDate = '';

  HabitsBloc({
    required GoalsRepository goalsRepository,
    required GamificationService gamificationService,
    LifecycleWatcher? lifecycleWatcher,
  })  : _goalsRepository = goalsRepository,
        _gamificationService = gamificationService,
        _lifecycleWatcher = lifecycleWatcher,
        super(HabitsInitial()) {
    _lifecycleWatcher?.addListener(this);
    on<SubscribeToHabits>(_onSubscribeToHabits);
    on<_HabitsDataChanged>(_onHabitsDataChanged);
    on<ToggleHabitCompletionEvent>(_onToggleHabitCompletion);
    on<UpdateHabitProgressEvent>(_onUpdateHabitProgress);
    on<LogHabitTimeEvent>(_onLogHabitTime);
    on<UpdateHabitCountEvent>(_onUpdateHabitCount);
    on<CreateStandAloneHabitEvent>(_onCreateStandAloneHabit);
    on<DeleteHabitEvent>(_onDeleteHabit);
    on<SearchHabitsEvent>(_onSearchHabits);
    on<DayRolloverEvent>(_onDayRollover);
  }

  // ---------------------------------------------------------------------------
  // Midnight Timer helpers
  // ---------------------------------------------------------------------------

  /// Schedules a one-shot Timer to fire immediately after the next calendar
  /// midnight. When it fires it adds a DayRolloverEvent and re-schedules
  /// itself for the following midnight.
  Timer _scheduleMidnightTimer() {
    final now = DateTime.now();
    // Add 1-second buffer so we do not land exactly on 00:00:00.000
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    final delay = nextMidnight.difference(now);
    return Timer(delay, () {
      if (!isClosed) {
        add(const DayRolloverEvent());
        // Re-schedule for the following midnight
        _midnightTimer = _scheduleMidnightTimer();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // AppLifecycleListener -- called when the app returns to the foreground
  // ---------------------------------------------------------------------------

  @override
  void onResumed() {
    final today = AppDateUtils.getTodayString();
    // Only fire if the date has actually changed since the last seen date.
    if (_lastKnownDate.isNotEmpty && today != _lastKnownDate && !isClosed) {
      add(const DayRolloverEvent());
    }
    _lastKnownDate = today;
  }

  @override
  void onPaused() {}

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  void _onSubscribeToHabits(SubscribeToHabits event, Emitter<HabitsState> emit) {
    emit(HabitsLoading());
    _habitsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _midnightTimer?.cancel();

    _habitsSubscription = _goalsRepository.watchAllHabits().skip(1).listen((_) {
      if (!isClosed) add(const _HabitsDataChanged());
    });

    _goalsSubscription = _goalsRepository.watchGoals().skip(1).listen((_) {
      if (!isClosed) add(const _HabitsDataChanged());
    });

    _lastKnownDate = AppDateUtils.getTodayString();
    _midnightTimer = _scheduleMidnightTimer();

    _recalculateAndEmit(emit);
  }

  void _onHabitsDataChanged(_HabitsDataChanged event, Emitter<HabitsState> emit) {
    _recalculateAndEmit(emit);
  }

  void _onDayRollover(DayRolloverEvent event, Emitter<HabitsState> emit) {
    _lastKnownDate = AppDateUtils.getTodayString();
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

      // Filter habits scheduled for today (Goal Isolation: exclude goal habits from Tasks page)
      final habitsToday = allHabits.where((habit) {
        final isStandalone = habit.goalId.isEmpty || habit.goalId == 'standalone';
        if (!isStandalone) return false;
        final matchesDay = habit.scheduleDays.isEmpty || habit.scheduleDays.contains(todayWeekday);
        final matchesQuery = query.isEmpty || habit.title.toLowerCase().contains(query);
        return matchesDay && matchesQuery;
      }).toList();

      final totalToday = habitsToday.length;
      // Completion is determined solely by whether todayStr appears in
      // completedDates -- never by the stale `habit.completed` boolean.
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

      // Award +20 XP via GamificationService
      await _gamificationService.awardXp(20);
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

  Future<void> _onLogHabitTime(LogHabitTimeEvent event, Emitter<HabitsState> emit) async {
    try {
      final habit = _goalsRepository.getAllHabits().firstWhere((h) => h.id == event.habitId);
      final todayStr = AppDateUtils.getTodayString();

      // Account for day rollover: if the habit was last logged on a previous
      // day, start accumulation from 0 rather than adding to yesterday's total.
      final isNewDay = habit.lastProgressDate != null && habit.lastProgressDate != todayStr;
      final baseTime = isNewDay ? 0 : habit.timeSpent;
      final newTime = baseTime + event.minutes;

      await _goalsRepository.updateHabitProgress(
        event.habitId,
        timeSpent: newTime,
      );
      // Auto-complete if target reached
      if (newTime >= habit.targetTime && habit.targetTime > 0) {
        if (!habit.completedDates.contains(todayStr)) {
          await _goalsRepository.toggleHabitCompletion(event.habitId, todayStr);
          await _gamificationService.awardXp(50);
        }
      }
    } catch (e) {
      emit(HabitsError('Failed to log time: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateHabitCount(UpdateHabitCountEvent event, Emitter<HabitsState> emit) async {
    try {
      final habit = _goalsRepository.getAllHabits().firstWhere((h) => h.id == event.habitId);
      final todayStr = AppDateUtils.getTodayString();

      // Account for day rollover in the accumulated count.
      final isNewDay = habit.lastProgressDate != null && habit.lastProgressDate != todayStr;
      final baseCount = isNewDay ? 0 : habit.currentCount;
      final newCount = (baseCount + event.delta).clamp(0, 9999);

      await _goalsRepository.updateHabitProgress(
        event.habitId,
        currentCount: newCount,
      );
      // Auto-complete if target reached
      if (newCount >= habit.targetCount && habit.targetCount > 0) {
        if (!habit.completedDates.contains(todayStr)) {
          await _goalsRepository.toggleHabitCompletion(event.habitId, todayStr);
          await _gamificationService.awardXp(50);
        }
      }
    } catch (e) {
      emit(HabitsError('Failed to update count: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _lifecycleWatcher?.removeListener(this);
    _habitsSubscription?.cancel();
    _goalsSubscription?.cancel();
    _midnightTimer?.cancel();
    return super.close();
  }
}

class _HabitsDataChanged extends HabitsEvent {
  const _HabitsDataChanged();
}
