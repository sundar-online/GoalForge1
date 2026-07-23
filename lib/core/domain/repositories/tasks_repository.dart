import '../models/task.dart';
import '../models/task_log.dart';

abstract class TasksRepository {
  /// Stream tasks list.
  Stream<List<Task>> watchTasks();

  /// Get cached tasks.
  List<Task> getTasks();

  /// Create or update a task.
  Future<void> upsertTask(Task task);

  /// Toggle task completion for a specific date (defaults to today YYYY-MM-DD).
  Future<void> toggleTaskCompletion(String taskId, String dateStr);

  /// Delete a task.
  Future<void> deleteTask(String taskId);

  /// Stream task completion logs map (dateStr -> TaskLog).
  Stream<Map<String, TaskLog>> watchTaskLogs();

  /// Get cached task logs.
  Map<String, TaskLog> getTaskLogs();

  /// Create or update a task log.
  Future<void> upsertTaskLog(TaskLog log);

  /// Force fetch from Firestore and refresh local cache.
  Future<void> fetchRemoteTasksAndLogs();
}
