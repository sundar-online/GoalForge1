import 'package:equatable/equatable.dart';

class TaskLog extends Equatable {
  final String date; // YYYY-MM-DD
  final int completedCount;
  final double accuracyPercent;
  final List<String> completions; // List of task/habit IDs completed on this day
  final String updatedAt;

  const TaskLog({
    required this.date,
    this.completedCount = 0,
    this.accuracyPercent = 0.0,
    required this.completions,
    required this.updatedAt,
  });

  TaskLog copyWith({
    String? date,
    int? completedCount,
    double? accuracyPercent,
    List<String>? completions,
    String? updatedAt,
  }) {
    return TaskLog(
      date: date ?? this.date,
      completedCount: completedCount ?? this.completedCount,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      completions: completions ?? this.completions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'completedCount': completedCount,
      'accuracyPercent': accuracyPercent,
      'completions': completions,
      'updatedAt': updatedAt,
    };
  }

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    return TaskLog(
      date: json['date'] as String? ?? '',
      completedCount: json['completedCount'] as int? ?? 0,
      accuracyPercent: (json['accuracyPercent'] as num?)?.toDouble() ?? 0.0,
      completions: List<String>.from(json['completions'] ?? []),
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory TaskLog.fromFirestore(Map<String, dynamic> data) => TaskLog.fromJson(data);

  bool isValid() {
    return date.isNotEmpty && completedCount >= 0 && accuracyPercent >= 0.0;
  }

  @override
  List<Object?> get props => [date, completedCount, accuracyPercent, completions, updatedAt];
}
