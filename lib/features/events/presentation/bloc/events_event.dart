import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/scheduled_event.dart';

abstract class EventsEvent extends Equatable {
  const EventsEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToEvents extends EventsEvent {}

class CreateEvent extends EventsEvent {
  final ScheduledEvent event;

  const CreateEvent(this.event);

  @override
  List<Object?> get props => [event];
}

class UpdateEvent extends EventsEvent {
  final ScheduledEvent event;

  const UpdateEvent(this.event);

  @override
  List<Object?> get props => [event];
}

class ToggleEventCompletion extends EventsEvent {
  final String eventId;

  const ToggleEventCompletion(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class DeleteEvent extends EventsEvent {
  final String eventId;

  const DeleteEvent(this.eventId);

  @override
  List<Object?> get props => [eventId];
}

class SelectEventDate extends EventsEvent {
  final String dateStr;

  const SelectEventDate(this.dateStr);

  @override
  List<Object?> get props => [dateStr];
}
