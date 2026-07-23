import 'package:equatable/equatable.dart';

class ScheduledEvent extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String eventDate; // YYYY-MM-DD
  final String? eventTime; // HH:MM
  final int? color; // Holds color value as integer, e.g. 0xFF4CAF50
  final int reminderMinutes; // e.g. 15, 30, 60
  final bool completed;
  final String createdAt;

  const ScheduledEvent({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.color,
    this.reminderMinutes = 15,
    this.completed = false,
    required this.createdAt,
  });

  ScheduledEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? eventDate,
    String? eventTime,
    int? color,
    int? reminderMinutes,
    bool? completed,
    String? createdAt,
  }) {
    return ScheduledEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      color: color ?? this.color,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'eventTime': eventTime,
      'color': color,
      'reminderMinutes': reminderMinutes,
      'completed': completed,
      'createdAt': createdAt,
    };
  }

  factory ScheduledEvent.fromJson(Map<String, dynamic> json) {
    return ScheduledEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      eventDate: json['eventDate'] as String? ?? '',
      eventTime: json['eventTime'] as String?,
      color: json['color'] as int?,
      reminderMinutes: json['reminderMinutes'] as int? ?? 15,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory ScheduledEvent.fromFirestore(Map<String, dynamic> data) => ScheduledEvent.fromJson(data);

  bool isValid() {
    return id.isNotEmpty && title.isNotEmpty && eventDate.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        eventDate,
        eventTime,
        color,
        reminderMinutes,
        completed,
        createdAt,
      ];
}
