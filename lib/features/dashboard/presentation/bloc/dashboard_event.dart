import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/goal.dart';
import '../../../../core/domain/models/xp_profile.dart';
import '../../../../core/domain/models/scheduled_event.dart';
import '../../../../core/services/ai_insights_service.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToStreams extends DashboardEvent {}

class UpdateDashboardData extends DashboardEvent {
  final Goal? focusGoal;
  final int habitsLeftToday;
  final XPProfile xpProfile;
  final int quickThoughtsCount;
  final List<ScheduledEvent> upcomingEvents;
  final double weeklyAccuracy;
  final String weeklyFocusDuration;
  final String bestDay;
  final List<AiInsight> insights;

  const UpdateDashboardData({
    this.focusGoal,
    this.habitsLeftToday = 0,
    required this.xpProfile,
    this.quickThoughtsCount = 0,
    required this.upcomingEvents,
    this.weeklyAccuracy = 0.0,
    this.weeklyFocusDuration = '0h 0m',
    this.bestDay = 'N/A',
    this.insights = const [],
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
      ];
}
