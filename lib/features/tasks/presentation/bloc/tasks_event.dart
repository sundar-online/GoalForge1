import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/task.dart';

abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToTasks extends TasksEvent {}

class CreateTaskEvent extends TasksEvent {
  final Task task;

  const CreateTaskEvent(this.task);

  @override
  List<Object?> get props => [task];
}

class ToggleTaskCompletionEvent extends TasksEvent {
  final String taskId;
  final String dateStr;

  const ToggleTaskCompletionEvent({
    required this.taskId,
    required this.dateStr,
  });

  @override
  List<Object?> get props => [taskId, dateStr];
}

class DeleteTaskEvent extends TasksEvent {
  final String taskId;

  const DeleteTaskEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class FilterTasksEvent extends TasksEvent {
  final String? query;
  final String? priority;

  const FilterTasksEvent({this.query, this.priority});

  @override
  List<Object?> get props => [query, priority];
}
