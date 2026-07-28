import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/domain/models/scheduled_event.dart';
import '../../../../core/services/ai_insights_service.dart';
import '../../domain/models/coach_intelligence.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final Goal? focusGoal;
  final int habitsLeftToday;
  final XPProfile xpProfile;
  final int quickThoughtsCount;
  final List<ScheduledEvent> upcomingEvents;
  final double weeklyAccuracy;
  final String weeklyFocusDuration;
  final String bestDay;
  final List<AiInsight> insights;

  final HeroNextAction? nextBestAction;
  final AtRiskHabitInfo? atRiskHabit;
  final GoalAttentionInfo? goalAttention;
  final RecoveryProtocolInfo? recoveryProtocol;
  final int disciplineScore;

  const DashboardLoaded({
    this.focusGoal,
    this.habitsLeftToday = 0,
    required this.xpProfile,
    this.quickThoughtsCount = 0,
    required this.upcomingEvents,
    this.weeklyAccuracy = 0.0,
    this.weeklyFocusDuration = '0h 0m',
    this.bestDay = 'N/A',
    this.insights = const [],
    this.nextBestAction,
    this.atRiskHabit,
    this.goalAttention,
    this.recoveryProtocol,
    this.disciplineScore = 85,
  });

  @override
  List<Object?> get props => [
        focusGoal,
        habitsLeftToday,
        xpProfile,
        quickThoughtsCount,
        upcomingEvents,
        weeklyAccuracy,
        weeklyFocusDuration,
        bestDay,
        insights,
        nextBestAction,
        atRiskHabit,
        goalAttention,
        recoveryProtocol,
        disciplineScore,
      ];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

