import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String mode; // 'ALL', 'ANY', 'CUSTOM'
  final int minHabits;
  final String? tag;
  final String? deadline; // YYYY-MM-DD
  final bool isFocusGoal;
  final double progress; // 0.0 to 100.0
  final int streak;
  final int bestStreak;
  final int missedDays;
  final List<String> completedDates; // ["YYYY-MM-DD"]
  final List<String> dependencies; // Parent goal IDs
  final int order;
  final String createdAt;

  const Goal({
    required this.id,
    required this.title,
    this.description,
    required this.mode,
    this.minHabits = 1,
    this.tag,
    this.deadline,
    this.isFocusGoal = false,
    this.progress = 0.0,
    this.streak = 0,
    this.bestStreak = 0,
    this.missedDays = 0,
    required this.completedDates,
    required this.dependencies,
    this.order = 0,
    required this.createdAt,
  });

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    String? mode,
    int? minHabits,
    String? tag,
    String? deadline,
    bool? isFocusGoal,
    double? progress,
    int? streak,
    int? bestStreak,
    int? missedDays,
    List<String>? completedDates,
    List<String>? dependencies,
    int? order,
    String? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      minHabits: minHabits ?? this.minHabits,
      tag: tag ?? this.tag,
      deadline: deadline ?? this.deadline,
      isFocusGoal: isFocusGoal ?? this.isFocusGoal,
      progress: progress ?? this.progress,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      missedDays: missedDays ?? this.missedDays,
      completedDates: completedDates ?? this.completedDates,
      dependencies: dependencies ?? this.dependencies,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mode': mode,
      'minHabits': minHabits,
      'tag': tag,
      'deadline': deadline,
      'isFocusGoal': isFocusGoal,
      'progress': progress,
      'streak': streak,
      'bestStreak': bestStreak,
      'missedDays': missedDays,
      'completedDates': completedDates,
      'dependencies': dependencies,
      'order': order,
      'createdAt': createdAt,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      mode: json['mode'] as String? ?? 'ALL',
      minHabits: json['minHabits'] as int? ?? 1,
      tag: json['tag'] as String?,
      deadline: json['deadline'] as String?,
      isFocusGoal: json['isFocusGoal'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      streak: json['streak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      missedDays: json['missedDays'] as int? ?? 0,
      completedDates: List<String>.from(json['completedDates'] ?? []),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      order: json['order'] as int? ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory Goal.fromFirestore(Map<String, dynamic> data) => Goal.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        mode,
        minHabits,
        tag,
        deadline,
        isFocusGoal,
        progress,
        streak,
        bestStreak,
        missedDays,
        completedDates,
        dependencies,
        order,
        createdAt,
      ];
}
