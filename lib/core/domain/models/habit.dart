import 'package:equatable/equatable.dart';

class Habit extends Equatable {
  final String id;
  final String goalId;
  final String title;
  final String type; // 'check', 'count', 'time'
  final int targetTime; // in minutes
  final int targetCount;
  final List<String> scheduleDays; // e.g. ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
  final bool reminderEnabled;
  final String? reminderTime; // "HH:MM"
  final int streak;
  final int bestStreak;
  final int missedDays;
  final List<String> completedDates; // ["YYYY-MM-DD"]
  final int timeSpent; // transient spent minutes today
  final int currentCount; // transient count today
  final bool completed; // transient completion status today
  final String? lastCompletedDate;
  final String createdAt;

  const Habit({
    required this.id,
    required this.goalId,
    required this.title,
    required this.type,
    required this.targetTime,
    required this.targetCount,
    required this.scheduleDays,
    required this.reminderEnabled,
    this.reminderTime,
    this.streak = 0,
    this.bestStreak = 0,
    this.missedDays = 0,
    required this.completedDates,
    this.timeSpent = 0,
    this.currentCount = 0,
    this.completed = false,
    this.lastCompletedDate,
    required this.createdAt,
  });

  Habit copyWith({
    String? id,
    String? goalId,
    String? title,
    String? type,
    int? targetTime,
    int? targetCount,
    List<String>? scheduleDays,
    bool? reminderEnabled,
    String? reminderTime,
    int? streak,
    int? bestStreak,
    int? missedDays,
    List<String>? completedDates,
    int? timeSpent,
    int? currentCount,
    bool? completed,
    String? lastCompletedDate,
    String? createdAt,
  }) {
    return Habit(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      type: type ?? this.type,
      targetTime: targetTime ?? this.targetTime,
      targetCount: targetCount ?? this.targetCount,
      scheduleDays: scheduleDays ?? this.scheduleDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      missedDays: missedDays ?? this.missedDays,
      completedDates: completedDates ?? this.completedDates,
      timeSpent: timeSpent ?? this.timeSpent,
      currentCount: currentCount ?? this.currentCount,
      completed: completed ?? this.completed,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'type': type,
      'targetTime': targetTime,
      'targetCount': targetCount,
      'scheduleDays': scheduleDays,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
      'streak': streak,
      'bestStreak': bestStreak,
      'missedDays': missedDays,
      'completedDates': completedDates,
      'timeSpent': timeSpent,
      'currentCount': currentCount,
      'completed': completed,
      'lastCompletedDate': lastCompletedDate,
      'createdAt': createdAt,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String? ?? '',
      goalId: json['goalId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'check',
      targetTime: json['targetTime'] as int? ?? 0,
      targetCount: json['targetCount'] as int? ?? 0,
      scheduleDays: List<String>.from(json['scheduleDays'] ?? []),
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] as String?,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      missedDays: json['missedDays'] as int? ?? 0,
      completedDates: List<String>.from(json['completedDates'] ?? []),
      timeSpent: json['timeSpent'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Habit.fromFirestore(Map<String, dynamic> data) => Habit.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && goalId.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        goalId,
        title,
        type,
        targetTime,
        targetCount,
        scheduleDays,
        reminderEnabled,
        reminderTime,
        streak,
        bestStreak,
        missedDays,
        completedDates,
        timeSpent,
        currentCount,
        completed,
        lastCompletedDate,
        createdAt,
      ];
}
