import 'package:equatable/equatable.dart';

enum BadgeCategory {
  consistency,
  learning,
  focus,
  accuracy,
  mastery,
}

enum BadgeRequirementType {
  streak,
  completedTasks,
  completedHabits,
  focusMinutes,
  perfectDays,
  totalXP,
  completedGoals,
}

class BadgeDefinition extends Equatable {
  final String id;
  final String title;
  final String description;
  final BadgeCategory category;
  final BadgeRequirementType requirementType;
  final int targetValue;
  final String iconName;

  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.requirementType,
    required this.targetValue,
    required this.iconName,
  });

  @override
  List<Object?> get props => [id, title, description, category, requirementType, targetValue, iconName];
}

class UnlockedBadge extends Equatable {
  final String badgeId;
  final String unlockedAt;

  const UnlockedBadge({
    required this.badgeId,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
        'badgeId': badgeId,
        'unlockedAt': unlockedAt,
      };

  factory UnlockedBadge.fromJson(Map<String, dynamic> json) => UnlockedBadge(
        badgeId: json['badgeId'] as String? ?? '',
        unlockedAt: json['unlockedAt'] as String? ?? '',
      );

  @override
  List<Object?> get props => [badgeId, unlockedAt];
}
