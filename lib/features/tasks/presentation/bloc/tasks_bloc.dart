import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/repositories/tasks_repository.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/utils/date_utils.dart';
import 'tasks_event.dart';
import 'tasks_state.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TasksRepository _tasksRepository;
  final GamificationService _gamificationService;

  StreamSubscription? _tasksSubscription;
  StreamSubscription? _logsSubscription;

  TasksBloc({
    required TasksRepository tasksRepository,
    required GamificationService gamificationService,
  })  : _tasksRepository = tasksRepository,
        _gamificationService = gamificationService,
        super(TasksInitial()) {
    on<SubscribeToTasks>(_onSubscribeToTasks);
    on<_TasksDataChanged>(_onTasksDataChanged);
    on<CreateTaskEvent>(_onCreateTask);
    on<ToggleTaskCompletionEvent>(_onToggleTaskCompletion);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<FilterTasksEvent>(_onFilterTasks);
  }

  void _onSubscribeToTasks(SubscribeToTasks event, Emitter<TasksState> emit) {
    emit(TasksLoading());
    _tasksSubscription?.cancel();
    _logsSubscription?.cancel();

    _tasksSubscription = _tasksRepository.watchTasks().skip(1).listen((_) {
      if (!isClosed) add(const _TasksDataChanged());
    });

    _logsSubscription = _tasksRepository.watchTaskLogs().skip(1).listen((_) {
      if (!isClosed) add(const _TasksDataChanged());
    });

    _recalculateAndEmit(emit);
  }

  void _onTasksDataChanged(_TasksDataChanged event, Emitter<TasksState> emit) {
    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<TasksState> emit) {
    try {
      final allTasks = _tasksRepository.getTasks();
      final taskLogs = _tasksRepository.getTaskLogs();
      final todayStr = AppDateUtils.getTodayString();

      final currentQuery = (state is TasksLoaded) ? (state as TasksLoaded).searchQuery.toLowerCase() : '';
      final currentPriority = (state is TasksLoaded) ? (state as TasksLoaded).selectedPriority : 'All';

      final filteredTasks = allTasks.where((task) {
        final matchesQuery = currentQuery.isEmpty || task.title.toLowerCase().contains(currentQuery);
        final matchesPriority = currentPriority == 'All' || task.priority.toLowerCase() == currentPriority.toLowerCase();
        return matchesQuery && matchesPriority;
      }).toList();

      final todayLog = taskLogs[todayStr];
      final completedCount = todayLog?.completedCount ?? allTasks.where((t) => t.completedDates.contains(todayStr)).length;
      final totalCount = allTasks.length;
      final accuracy = totalCount > 0 ? ((completedCount / totalCount) * 100.0).clamp(0.0, 100.0) : 100.0;

      emit(TasksLoaded(
        tasks: filteredTasks,
        taskLogs: taskLogs,
        totalCount: totalCount,
        completedCount: completedCount,
        accuracyPercent: accuracy,
        searchQuery: currentQuery,
        selectedPriority: currentPriority,
      ));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> _onCreateTask(CreateTaskEvent event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.upsertTask(event.task);
    } catch (e) {
      emit(TasksError('Failed to create task: ${e.toString()}'));
    }
  }

  Future<void> _onToggleTaskCompletion(ToggleTaskCompletionEvent event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.toggleTaskCompletion(event.taskId, event.dateStr);

      // Award +10 XP on standalone task completion
      await _gamificationService.awardXp(10);
    } catch (e) {
      emit(TasksError('Failed to toggle task completion: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteTask(DeleteTaskEvent event, Emitter<TasksState> emit) async {
    try {
      await _tasksRepository.deleteTask(event.taskId);
    } catch (e) {
      emit(TasksError('Failed to delete task: ${e.toString()}'));
    }
  }

  void _onFilterTasks(FilterTasksEvent event, Emitter<TasksState> emit) {
    if (state is TasksLoaded) {
      final current = state as TasksLoaded;
      emit(current.copyWith(
        searchQuery: event.query ?? current.searchQuery,
        selectedPriority: event.priority ?? current.selectedPriority,
      ));
      _recalculateAndEmit(emit);
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    _logsSubscription?.cancel();
    return super.close();
  }
}

class _TasksDataChanged extends TasksEvent {
  const _TasksDataChanged();
}
