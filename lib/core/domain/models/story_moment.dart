import 'package:equatable/equatable.dart';

class StoryMoment extends Equatable {
  final String id;
  final String goalId;
  final String goalTitle;
  final String reflectionText;
  final String unlockedAt;

  const StoryMoment({
    required this.id,
    required this.goalId,
    required this.goalTitle,
    required this.reflectionText,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goalId': goalId,
        'goalTitle': goalTitle,
        'reflectionText': reflectionText,
        'unlockedAt': unlockedAt,
      };

  factory StoryMoment.fromJson(Map<String, dynamic> json) => StoryMoment(
        id: json['id'] as String? ?? '',
        goalId: json['goalId'] as String? ?? '',
        goalTitle: json['goalTitle'] as String? ?? '',
        reflectionText: json['reflectionText'] as String? ?? '',
        unlockedAt: json['unlockedAt'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, goalId, goalTitle, reflectionText, unlockedAt];
}
