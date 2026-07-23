import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/task.dart';
import '../../../../core/domain/models/task_log.dart';

abstract class TasksState extends Equatable {
  const TasksState();

  @override
  List<Object?> get props => [];
}

class TasksInitial extends TasksState {}

class TasksLoading extends TasksState {}

class TasksLoaded extends TasksState {
  final List<Task> tasks;
  final Map<String, TaskLog> taskLogs;
  final int totalCount;
  final int completedCount;
  final double accuracyPercent;
  final String searchQuery;
  final String selectedPriority; // 'All', 'High', 'Medium', 'Low'

  const TasksLoaded({
    required this.tasks,
    required this.taskLogs,
    this.totalCount = 0,
    this.completedCount = 0,
    this.accuracyPercent = 0.0,
    this.searchQuery = '',
    this.selectedPriority = 'All',
  });

  TasksLoaded copyWith({
    List<Task>? tasks,
    Map<String, TaskLog>? taskLogs,
    int? totalCount,
    int? completedCount,
    double? accuracyPercent,
    String? searchQuery,
    String? selectedPriority,
  }) {
    return TasksLoaded(
      tasks: tasks ?? this.tasks,
      taskLogs: taskLogs ?? this.taskLogs,
      totalCount: totalCount ?? this.totalCount,
      completedCount: completedCount ?? this.completedCount,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPriority: selectedPriority ?? this.selectedPriority,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        taskLogs,
        totalCount,
        completedCount,
        accuracyPercent,
        searchQuery,
        selectedPriority,
      ];
}

class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);

  @override
  List<Object?> get props => [message];
}
