import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String type; // 'daily', 'single', 'range'
  final String? targetDate; // YYYY-MM-DD for single
  final String? startDate; // YYYY-MM-DD for range
  final String? endDate; // YYYY-MM-DD for range
  final String priority; // 'High', 'Medium', 'Low'
  final bool completed;
  final List<String> completedDates; // ["YYYY-MM-DD"]
  final int streak;
  final int bestStreak;
  final String createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.type,
    this.targetDate,
    this.startDate,
    this.endDate,
    required this.priority,
    this.completed = false,
    required this.completedDates,
    this.streak = 0,
    this.bestStreak = 0,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? type,
    String? targetDate,
    String? startDate,
    String? endDate,
    String? priority,
    bool? completed,
    List<String>? completedDates,
    int? streak,
    int? bestStreak,
    String? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      targetDate: targetDate ?? this.targetDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      completedDates: completedDates ?? this.completedDates,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'targetDate': targetDate,
      'startDate': startDate,
      'endDate': endDate,
      'priority': priority,
      'completed': completed,
      'completedDates': completedDates,
      'streak': streak,
      'bestStreak': bestStreak,
      'createdAt': createdAt,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'single',
      targetDate: json['targetDate'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      priority: json['priority'] as String? ?? 'Medium',
      completed: json['completed'] as bool? ?? false,
      completedDates: List<String>.from(json['completedDates'] ?? []),
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Task.fromFirestore(Map<String, dynamic> data) => Task.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        targetDate,
        startDate,
        endDate,
        priority,
        completed,
        completedDates,
        streak,
        bestStreak,
        createdAt,
      ];
}
