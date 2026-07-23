import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/repositories/focus_repository.dart';
import '../../../../core/domain/repositories/gamification_repository.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import '../../../../core/domain/repositories/tasks_repository.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/utils/date_utils.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GoalsRepository _goalsRepository;
  final TasksRepository _tasksRepository;
  final FocusRepository _focusRepository;
  final GamificationRepository _gamificationRepository;
  final GamificationService _gamificationService;

  StreamSubscription? _goalsSubscription;
  StreamSubscription? _tasksSubscription;
  StreamSubscription? _focusSubscription;
  StreamSubscription? _xpSubscription;

  AnalyticsBloc({
    required GoalsRepository goalsRepository,
    required TasksRepository tasksRepository,
    required FocusRepository focusRepository,
    required GamificationRepository gamificationRepository,
    required GamificationService gamificationService,
  })  : _goalsRepository = goalsRepository,
        _tasksRepository = tasksRepository,
        _focusRepository = focusRepository,
        _gamificationRepository = gamificationRepository,
        _gamificationService = gamificationService,
        super(AnalyticsInitial()) {
    on<SubscribeToAnalytics>(_onSubscribeToAnalytics);
    on<SelectTimeframeEvent>(_onSelectTimeframe);
  }

  Future<void> _onSubscribeToAnalytics(SubscribeToAnalytics event, Emitter<AnalyticsState> emit) async {
    emit(AnalyticsLoading());
    await _goalsSubscription?.cancel();
    await _tasksSubscription?.cancel();
    await _focusSubscription?.cancel();
    await _xpSubscription?.cancel();

    _goalsSubscription = _goalsRepository.watchGoals().listen((_) {
      if (!isClosed) add(SubscribeToAnalytics());
    });

    _tasksSubscription = _tasksRepository.watchTasks().listen((_) {
      if (!isClosed) add(SubscribeToAnalytics());
    });

    _focusSubscription = _focusRepository.watchFocusSessions().listen((_) {
      if (!isClosed) add(SubscribeToAnalytics());
    });

    _xpSubscription = _gamificationRepository.watchXPProfile().listen((_) {
      if (!isClosed) add(SubscribeToAnalytics());
    });

    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<AnalyticsState> emit) {
    try {
      final goals = _goalsRepository.getGoals();
      final habits = _goalsRepository.getAllHabits();
      final tasks = _tasksRepository.getTasks();
      final taskLogs = _tasksRepository.getTaskLogs();
      final focusSessions = _focusRepository.getFocusSessions();
      final xpProfile = _gamificationRepository.getXPProfile();

      final totalXp = xpProfile?.totalXP ?? 0;
      final levelProg = _gamificationService.calculateLevelProgress(totalXp);
      final earnedBadges = xpProfile?.earnedBadges ?? const [];

      // Calculate Weekly Accuracy %
      final last7Days = List.generate(7, (i) {
        final date = DateTime.now().subtract(Duration(days: i));
        return AppDateUtils.toLocalYYYYMMDD(date);
      });

      double sumAccuracy = 0.0;
      int logCount = 0;
      for (var d in last7Days) {
        final log = taskLogs[d];
        if (log != null) {
          sumAccuracy += log.accuracyPercent;
          logCount++;
        }
      }
      final weeklyAccuracy = logCount > 0 ? (sumAccuracy / logCount).clamp(0.0, 100.0) : 100.0;

      // Calculate Total Focus Minutes this week
      final totalFocusSeconds = focusSessions.fold<int>(0, (sum, s) => sum + s.timeSpentSeconds);
      final totalFocusMinutes = (totalFocusSeconds / 60).round();

      // Weekly XP Bar Chart Data Map (MON -> XP)
      const dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
      final Map<String, int> weeklyXpMap = {};

      for (var i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = AppDateUtils.toLocalYYYYMMDD(date);
        final dayName = dayNames[date.weekday - 1];
        final dayXp = xpProfile?.xpHistory[dateStr] ?? 0;
        weeklyXpMap[dayName] = dayXp;
      }

      final timeframe = (state is AnalyticsLoaded)
          ? (state as AnalyticsLoaded).selectedTimeframe
          : 'Weekly';

      emit(AnalyticsLoaded(
        weeklyAccuracyPercent: weeklyAccuracy,
        totalFocusMinutesThisWeek: totalFocusMinutes,
        completedTasksCount: tasks.where((t) => t.completed).length,
        activeHabitsCount: habits.length,
        totalXP: totalXp,
        currentLevel: levelProg.currentLevel,
        levelProgressRatio: levelProg.progressRatio,
        earnedBadges: earnedBadges,
        weeklyXpData: weeklyXpMap,
        goalMasteryList: goals,
        selectedTimeframe: timeframe,
      ));
    } catch (e) {
      emit(AnalyticsError(e.toString()));
    }
  }

  void _onSelectTimeframe(SelectTimeframeEvent event, Emitter<AnalyticsState> emit) {
    if (state is AnalyticsLoaded) {
      final current = state as AnalyticsLoaded;
      emit(current.copyWith(selectedTimeframe: event.timeframe));
      _recalculateAndEmit(emit);
    }
  }

  @override
  Future<void> close() {
    _goalsSubscription?.cancel();
    _tasksSubscription?.cancel();
    _focusSubscription?.cancel();
    _xpSubscription?.cancel();
    return super.close();
  }
}
