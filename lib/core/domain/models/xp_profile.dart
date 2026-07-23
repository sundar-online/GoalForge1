import 'package:equatable/equatable.dart';

class XPProfile extends Equatable {
  final int totalXP;
  final int level;
  final List<String> earnedBadges; // ["streak_apprentice", etc.]
  final Map<String, int> xpHistory; // reason -> XP accumulated
  final String updatedAt;

  const XPProfile({
    this.totalXP = 0,
    this.level = 1,
    required this.earnedBadges,
    required this.xpHistory,
    required this.updatedAt,
  });

  XPProfile copyWith({
    int? totalXP,
    int? level,
    List<String>? earnedBadges,
    Map<String, int>? xpHistory,
    String? updatedAt,
  }) {
    return XPProfile(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      xpHistory: xpHistory ?? this.xpHistory,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'level': level,
      'earnedBadges': earnedBadges,
      'xpHistory': xpHistory,
      'updatedAt': updatedAt,
    };
  }

  factory XPProfile.fromJson(Map<String, dynamic> json) {
    return XPProfile(
      totalXP: json['totalXP'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      earnedBadges: List<String>.from(json['earnedBadges'] ?? []),
      xpHistory: Map<String, int>.from(json['xpHistory'] ?? {}),
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory XPProfile.fromFirestore(Map<String, dynamic> data) => XPProfile.fromJson(data);

  bool isValid() {
    return level >= 1 && totalXP >= 0;
  }

  @override
  List<Object?> get props => [totalXP, level, earnedBadges, xpHistory, updatedAt];
}
