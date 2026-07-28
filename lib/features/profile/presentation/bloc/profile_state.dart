import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/badge_model.dart';
import '../../../../core/domain/models/xp_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final XPProfile xpProfile;
  final String displayName;
  final String email;
  final BadgeCategory? selectedCategory;
  final bool smartNotificationsEnabled;

  // Lifetime Stats
  final int totalCompletions;
  final int totalFocusMinutes;
  final int longestStreak;
  final int perfectDays;
  final int totalGoalsCompleted;
  final int disciplineScore;

  const ProfileLoaded({
    required this.xpProfile,
    required this.displayName,
    required this.email,
    this.selectedCategory,
    this.smartNotificationsEnabled = true,
    this.totalCompletions = 0,
    this.totalFocusMinutes = 0,
    this.longestStreak = 0,
    this.perfectDays = 0,
    this.totalGoalsCompleted = 0,
    this.disciplineScore = 100,
  });

  ProfileLoaded copyWith({
    XPProfile? xpProfile,
    String? displayName,
    String? email,
    BadgeCategory? selectedCategory,
    bool setCategoryToNull = false,
    bool? smartNotificationsEnabled,
    int? totalCompletions,
    int? totalFocusMinutes,
    int? longestStreak,
    int? perfectDays,
    int? totalGoalsCompleted,
    int? disciplineScore,
  }) {
    return ProfileLoaded(
      xpProfile: xpProfile ?? this.xpProfile,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      selectedCategory: setCategoryToNull ? null : (selectedCategory ?? this.selectedCategory),
      smartNotificationsEnabled: smartNotificationsEnabled ?? this.smartNotificationsEnabled,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      longestStreak: longestStreak ?? this.longestStreak,
      perfectDays: perfectDays ?? this.perfectDays,
      totalGoalsCompleted: totalGoalsCompleted ?? this.totalGoalsCompleted,
      disciplineScore: disciplineScore ?? this.disciplineScore,
    );
  }

  @override
  List<Object?> get props => [
        xpProfile,
        displayName,
        email,
        selectedCategory,
        smartNotificationsEnabled,
        totalCompletions,
        totalFocusMinutes,
        longestStreak,
        perfectDays,
        totalGoalsCompleted,
        disciplineScore,
      ];
}

class ProfileDataCleared extends ProfileState {
  const ProfileDataCleared();
}
