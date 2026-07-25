import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/habit.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/domain/models/task_log.dart';
import '../../../../core/domain/models/focus_session.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import '../../../../core/domain/repositories/tasks_repository.dart';
import '../../../../core/domain/repositories/notes_repository.dart';
import '../../../../core/domain/repositories/focus_repository.dart';
import '../../../../core/domain/repositories/gamification_repository.dart';
import '../../../../core/domain/repositories/events_repository.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/services/ai_insights_service.dart';
import '../../../../core/services/streak_service.dart';
import '../../../../core/utils/logger.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GoalsRepository _goalsRepository;
  final TasksRepository _tasksRepository;
  final NotesRepository _notesRepository;
  final FocusRepository _focusRepository;
  final GamificationRepository _gamificationRepository;
  final EventsRepository _eventsRepository;
  final AiInsightsService _aiInsightsService;
  final StreakService _streakService;

  StreamSubscription? _goalsSubscription;
  StreamSubscription? _habitsSubscription;
  StreamSubscription? _taskLogsSubscription;
  StreamSubscription? _quickThoughtsSubscription;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _xpSubscription;
  StreamSubscription? _focusSubscription;

  DashboardBloc({
    required GoalsRepository goalsRepository,
    required TasksRepository tasksRepository,
    required NotesRepository notesRepository,
    required FocusRepository focusRepository,
    required GamificationRepository gamificationRepository,
    required EventsRepository eventsRepository,
    AiInsightsService aiInsightsService = const AiInsightsService(),
    StreakService streakService = const StreakService(),
  })  : _goalsRepository = goalsRepository,
        _tasksRepository = tasksRepository,
        _notesRepository = notesRepository,
        _focusRepository = focusRepository,
        _gamificationRepository = gamificationRepository,
        _eventsRepository = eventsRepository,
        _aiInsightsService = aiInsightsService,
        _streakService = streakService,
        super(DashboardInitial()) {
    on<SubscribeToStreams>(_onSubscribeToStreams);
    on<UpdateDashboardData>(_onUpdateDashboardData);
  }

  void _onSubscribeToStreams(SubscribeToStreams event, Emitter<DashboardState> emit) {
    emit(DashboardLoading());

    // Cancel old subscriptions if any
    _cancelSubscriptions();

    // Setup reactive subscriptions to all repositories
    _goalsSubscription = _goalsRepository.watchGoals().listen((_) => _recalculateData());
    _taskLogsSubscription = _tasksRepository.watchTaskLogs().listen((_) => _recalculateData());
    _quickThoughtsSubscription = _notesRepository.watchQuickThoughts().listen((_) => _recalculateData());
    _eventsSubscription = _eventsRepository.watchEvents().listen((_) => _recalculateData());
    _xpSubscription = _gamificationRepository.watchXPProfile().listen((_) => _recalculateData());
    _focusSubscription = _focusRepository.watchFocusSessions().listen((_) => _recalculateData());

    // Trigger initial calculation immediately so state transitions from DashboardLoading to DashboardLoaded
    _recalculateData();
  }

  void _onUpdateDashboardData(UpdateDashboardData event, Emitter<DashboardState> emit) {
    emit(DashboardLoaded(
      focusGoal: event.focusGoal,
      habitsLeftToday: event.habitsLeftToday,
      xpProfile: event.xpProfile,
      quickThoughtsCount: event.quickThoughtsCount,
      upcomingEvents: event.upcomingEvents,
      weeklyAccuracy: event.weeklyAccuracy,
      weeklyFocusDuration: event.weeklyFocusDuration,
      bestDay: event.bestDay,
    ));
  }

  void _recalculateData() {
    try {
      final goals = _goalsRepository.getGoals();
      Goal? focusGoal;
      if (goals.isNotEmpty) {
        focusGoal = goals.firstWhere(
          (g) => g.isFocusGoal,
          orElse: () => goals.first,
        );
      }

      int habitsLeft = 0;
      if (focusGoal != null) {
        final habits = _goalsRepository.getHabits(focusGoal.id);
        habitsLeft = _calculateUncompletedHabits(focusGoal.id, habits);
      }

      final xp = _gamificationRepository.getXPProfile() ??
          const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');

      final quickThoughts = _notesRepository.getQuickThoughts();
      final events = _eventsRepository.getEvents();
      final taskLogs = _tasksRepository.getTaskLogs();
      final focusSessions = _focusRepository.getFocusSessions();

      final accuracy = _calculateWeeklyAccuracy(taskLogs);
      final focusDuration = _calculateWeeklyFocusDuration(focusSessions);
      final bestDay = _calculateBestDay(taskLogs);

      final habits = _goalsRepository.getAllHabits();
      final tasks = _tasksRepository.getTasks();
      final allDateLists = <List<String>>[
        ...habits.map((h) => h.completedDates),
        ...tasks.map((t) => t.completedDates),
      ];
      final globalStreak = _streakService.calculateMaxGlobalStreak(allDateLists);

      final insights = _aiInsightsService.generateInsights(
        goals: goals,
        tasks: tasks,
        focusSessions: focusSessions,
        streakDays: globalStreak,
      );

      add(UpdateDashboardData(
        focusGoal: focusGoal,
        habitsLeftToday: habitsLeft,
        xpProfile: xp,
        quickThoughtsCount: quickThoughts.length,
        upcomingEvents: events,
        weeklyAccuracy: accuracy,
        weeklyFocusDuration: focusDuration,
        bestDay: bestDay,
        insights: insights,
      ));
    } catch (e, stack) {
      AppLogger.e('Error recalculating dashboard data', e, stack);
      add(UpdateDashboardData(
        xpProfile: const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: ''),
        upcomingEvents: const [],
      ));
    }
  }

  int _calculateUncompletedHabits(String goalId, List<Habit> habits) {
    final todayStr = AppDateUtils.toLocalYYYYMMDD(DateTime.now());
    final weekdayStr = _getWeekdayString(DateTime.now());

    int count = 0;
    for (var habit in habits) {
      final activeToday = habit.scheduleDays.contains(weekdayStr);
      final completedToday = habit.completedDates.contains(todayStr) || habit.completed;
      if (activeToday && !completedToday) {
        count++;
      }
    }
    return count;
  }

  String _getWeekdayString(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return '';
    }
  }

  double _calculateWeeklyAccuracy(Map<String, TaskLog> logs) {
    double total = 0.0;
    int count = 0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = AppDateUtils.toLocalYYYYMMDD(date);
      final log = logs[dateStr];
      if (log != null) {
        total += log.accuracyPercent;
        count++;
      }
    }
    return count > 0 ? (total / count) : 0.0;
  }

  String _calculateWeeklyFocusDuration(List<FocusSession> sessions) {
    int totalSeconds = 0;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    for (var session in sessions) {
      try {
        final created = DateTime.parse(session.createdAt);
        if (created.isAfter(sevenDaysAgo)) {
          totalSeconds += session.timeSpentSeconds;
        }
      } catch (_) {}
    }

    if (totalSeconds == 0) {
      return '0h 0m';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String _calculateBestDay(Map<String, TaskLog> logs) {
    String best = 'N/A';
    double highest = -1.0;
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = AppDateUtils.toLocalYYYYMMDD(date);
      final log = logs[dateStr];
      if (log != null && log.accuracyPercent > highest) {
        highest = log.accuracyPercent;
        best = dateStr;
      }
    }
    return best;
  }

  void _cancelSubscriptions() {
    _goalsSubscription?.cancel();
    _habitsSubscription?.cancel();
    _taskLogsSubscription?.cancel();
    _quickThoughtsSubscription?.cancel();
    _eventsSubscription?.cancel();
    _xpSubscription?.cancel();
    _focusSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
