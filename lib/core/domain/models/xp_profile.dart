import 'package:equatable/equatable.dart';
import 'story_moment.dart';
import 'xp_transaction.dart';

class XPProfile extends Equatable {
  final int totalXP;
  final int level;
  final List<String> earnedBadges; // ["streak_apprentice", etc.]
  final Map<String, String> unlockedBadgesMap; // badgeId -> unlockedDateIso
  final Map<String, int> xpHistory; // YYYY-MM-DD -> XP accumulated
  final List<XpTransaction> transactions;
  final List<StoryMoment> storyMoments;
  final String updatedAt;

  const XPProfile({
    this.totalXP = 0,
    this.level = 1,
    required this.earnedBadges,
    this.unlockedBadgesMap = const {},
    required this.xpHistory,
    this.transactions = const [],
    this.storyMoments = const [],
    required this.updatedAt,
  });

  Set<String> get earnedBadgesSet => Set<String>.from(earnedBadges)..addAll(unlockedBadgesMap.keys);
  int get earnedBadgesCount => earnedBadgesSet.length;

  XPProfile copyWith({
    int? totalXP,
    int? level,
    List<String>? earnedBadges,
    Map<String, String>? unlockedBadgesMap,
    Map<String, int>? xpHistory,
    List<XpTransaction>? transactions,
    List<StoryMoment>? storyMoments,
    String? updatedAt,
  }) {
    final newUnlockedMap = unlockedBadgesMap ?? this.unlockedBadgesMap;
    final newBadgesList = earnedBadges ?? this.earnedBadges;
    final combinedBadges = Set<String>.from(newBadgesList)..addAll(newUnlockedMap.keys);

    return XPProfile(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      earnedBadges: combinedBadges.toList(),
      unlockedBadgesMap: newUnlockedMap,
      xpHistory: xpHistory ?? this.xpHistory,
      transactions: transactions ?? this.transactions,
      storyMoments: storyMoments ?? this.storyMoments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'level': level,
      'earnedBadges': earnedBadgesSet.toList(),
      'unlockedBadgesMap': unlockedBadgesMap,
      'xpHistory': xpHistory,
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'storyMoments': storyMoments.map((s) => s.toJson()).toList(),
      'updatedAt': updatedAt,
    };
  }

  factory XPProfile.fromJson(Map<String, dynamic> json) {
    final rawBadges = List<String>.from(json['earnedBadges'] ?? []);
    final unlockedMap = Map<String, String>.from(json['unlockedBadgesMap'] ?? {});
    final combinedBadges = Set<String>.from(rawBadges)..addAll(unlockedMap.keys);

    return XPProfile(
      totalXP: json['totalXP'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      earnedBadges: combinedBadges.toList(),
      unlockedBadgesMap: unlockedMap,
      xpHistory: Map<String, int>.from(json['xpHistory'] ?? {}),
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => XpTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      storyMoments: (json['storyMoments'] as List<dynamic>?)
              ?.map((e) => StoryMoment.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory XPProfile.fromFirestore(Map<String, dynamic> data) => XPProfile.fromJson(data);

  bool isValid() {
    return level >= 1 && totalXP >= 0;
  }

  @override
  List<Object?> get props => [
        totalXP,
        level,
        earnedBadgesSet,
        unlockedBadgesMap,
        xpHistory,
        transactions,
        storyMoments,
        updatedAt,
      ];
}
