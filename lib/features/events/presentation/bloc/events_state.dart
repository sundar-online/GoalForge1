import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/scheduled_event.dart';

abstract class EventsState extends Equatable {
  const EventsState();

  @override
  List<Object?> get props => [];
}

class EventsInitial extends EventsState {}

class EventsLoading extends EventsState {}

class EventsLoaded extends EventsState {
  final List<ScheduledEvent> allEvents;
  final List<ScheduledEvent> selectedDateEvents;
  final List<ScheduledEvent> upcomingEvents;
  final String selectedDateStr;
  final int totalEventCount;

  const EventsLoaded({
    required this.allEvents,
    required this.selectedDateEvents,
    required this.upcomingEvents,
    required this.selectedDateStr,
    this.totalEventCount = 0,
  });

  EventsLoaded copyWith({
    List<ScheduledEvent>? allEvents,
    List<ScheduledEvent>? selectedDateEvents,
    List<ScheduledEvent>? upcomingEvents,
    String? selectedDateStr,
    int? totalEventCount,
  }) {
    return EventsLoaded(
      allEvents: allEvents ?? this.allEvents,
      selectedDateEvents: selectedDateEvents ?? this.selectedDateEvents,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      selectedDateStr: selectedDateStr ?? this.selectedDateStr,
      totalEventCount: totalEventCount ?? this.totalEventCount,
    );
  }

  @override
  List<Object?> get props => [
        allEvents,
        selectedDateEvents,
        upcomingEvents,
        selectedDateStr,
        totalEventCount,
      ];
}

class EventsError extends EventsState {
  final String message;
  const EventsError(this.message);

  @override
  List<Object?> get props => [message];
}
