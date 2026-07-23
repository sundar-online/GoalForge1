import 'package:equatable/equatable.dart';

class FocusSession extends Equatable {
  final String id;
  final String? goalId;
  final String? itemId;
  final int duration; // in minutes (preset)
  final int timeSpentSeconds; // actual focus time completed
  final String type; // 'pomodoro', 'stopwatch', 'custom'
  final String soundTrack; // 'ZEN', 'CYBER', 'BELL', 'ALARM', 'NONE'
  final String createdAt;

  const FocusSession({
    required this.id,
    this.goalId,
    this.itemId,
    required this.duration,
    required this.timeSpentSeconds,
    required this.type,
    required this.soundTrack,
    required this.createdAt,
  });

  FocusSession copyWith({
    String? id,
    String? goalId,
    String? itemId,
    int? duration,
    int? timeSpentSeconds,
    String? type,
    String? soundTrack,
    String? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      itemId: itemId ?? this.itemId,
      duration: duration ?? this.duration,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      type: type ?? this.type,
      soundTrack: soundTrack ?? this.soundTrack,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'itemId': itemId,
      'duration': duration,
      'timeSpentSeconds': timeSpentSeconds,
      'type': type,
      'soundTrack': soundTrack,
      'createdAt': createdAt,
    };
  }

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String? ?? '',
      goalId: json['goalId'] as String?,
      itemId: json['itemId'] as String?,
      duration: json['duration'] as int? ?? 0,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? 0,
      type: json['type'] as String? ?? 'pomodoro',
      soundTrack: json['soundTrack'] as String? ?? 'NONE',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory FocusSession.fromFirestore(Map<String, dynamic> data) => FocusSession.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && duration >= 0 && timeSpentSeconds >= 0;
  }

  @override
  List<Object?> get props => [
        id,
        goalId,
        itemId,
        duration,
        timeSpentSeconds,
        type,
        soundTrack,
        createdAt,
      ];
}
