import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/domain/models/badge_model.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/domain/repositories/gamification_repository.dart';
import '../../../../core/domain/repositories/goals_repository.dart';
import '../../../../core/domain/repositories/tasks_repository.dart';
import '../../../../core/domain/repositories/focus_repository.dart';
import '../../../../core/services/gamification_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GamificationRepository gamificationRepository;
  final GamificationService gamificationService;
  final GoalsRepository goalsRepository;
  final TasksRepository tasksRepository;
  final FocusRepository focusRepository;
  final FirebaseAuth? firebaseAuth;
  StreamSubscription? _xpSubscription;

  ProfileBloc({
    required this.gamificationRepository,
    required this.gamificationService,
    required this.goalsRepository,
    required this.tasksRepository,
    required this.focusRepository,
    this.firebaseAuth,
  }) : super(const ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SelectBadgeCategoryTab>(_onSelectBadgeCategoryTab);
    on<ToggleSmartNotificationsSetting>(_onToggleSmartNotificationsSetting);
    on<ClearAllProfileDataRequested>(_onClearAllProfileDataRequested);

    _xpSubscription = gamificationRepository.watchXPProfile().listen((_) {
      add(const LoadProfile());
    });
  }

  @override
  Future<void> close() {
    _xpSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    final xpProfile = gamificationRepository.getXPProfile() ??
        const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: '');

    final user = firebaseAuth?.currentUser;
    final displayName = user?.displayName ?? 'Sundaramoorthy.S';
    final email = user?.email ?? 'sundar@goalforge.app';

    // Calculate lifetime stats
    final goals = goalsRepository.getGoals();
    final tasks = tasksRepository.getTasks();
    final completedTasks = tasks.where((t) => t.completed).length;
    final completedGoals = goals.where((g) => g.progress >= 1.0).length;
    final focusSessions = focusRepository.getFocusSessions();
    final totalFocusMinutes = focusSessions.fold<int>(0, (sum, f) => sum + f.duration);

    BadgeCategory? currentCategory;
    bool currentNotificationsSetting = true;
    if (state is ProfileLoaded) {
      final currentLoaded = state as ProfileLoaded;
      currentCategory = currentLoaded.selectedCategory;
      currentNotificationsSetting = currentLoaded.smartNotificationsEnabled;
    }

    emit(ProfileLoaded(
      xpProfile: xpProfile,
      displayName: displayName,
      email: email,
      selectedCategory: currentCategory,
      smartNotificationsEnabled: currentNotificationsSetting,
      totalCompletions: completedTasks,
      totalFocusMinutes: totalFocusMinutes,
      longestStreak: xpProfile.level * 3,
      perfectDays: xpProfile.earnedBadgesCount,
      totalGoalsCompleted: completedGoals,
      disciplineScore: 100,
    ));
  }

  void _onSelectBadgeCategoryTab(SelectBadgeCategoryTab event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(
        selectedCategory: event.category,
        setCategoryToNull: event.category == null,
      ));
    }
  }

  void _onToggleSmartNotificationsSetting(ToggleSmartNotificationsSetting event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      emit(currentState.copyWith(smartNotificationsEnabled: event.enabled));
    }
  }

  Future<void> _onClearAllProfileDataRequested(ClearAllProfileDataRequested event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      // Reset XP Profile
      await gamificationRepository.updateXPProfile(
        const XPProfile(earnedBadges: [], xpHistory: {}, updatedAt: ''),
      );

      emit(const ProfileDataCleared());
    } catch (_) {
      add(const LoadProfile());
    }
  }
}
