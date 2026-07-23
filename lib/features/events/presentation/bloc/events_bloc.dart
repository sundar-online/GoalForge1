import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/repositories/events_repository.dart';
import '../../../../core/utils/date_utils.dart';
import 'events_event.dart';
import 'events_state.dart';

class EventsBloc extends Bloc<EventsEvent, EventsState> {
  final EventsRepository _eventsRepository;
  StreamSubscription? _eventsSubscription;

  EventsBloc({
    required EventsRepository eventsRepository,
  })  : _eventsRepository = eventsRepository,
        super(EventsInitial()) {
    on<SubscribeToEvents>(_onSubscribeToEvents);
    on<CreateEvent>(_onCreateEvent);
    on<UpdateEvent>(_onUpdateEvent);
    on<ToggleEventCompletion>(_onToggleEventCompletion);
    on<DeleteEvent>(_onDeleteEvent);
    on<SelectEventDate>(_onSelectEventDate);
  }

  Future<void> _onSubscribeToEvents(SubscribeToEvents event, Emitter<EventsState> emit) async {
    emit(EventsLoading());
    await _eventsSubscription?.cancel();

    _eventsSubscription = _eventsRepository.watchEvents().listen((_) {
      if (!isClosed) {
        add(SubscribeToEvents());
      }
    });

    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(Emitter<EventsState> emit) {
    try {
      final allEvents = _eventsRepository.getEvents();
      final todayStr = AppDateUtils.getTodayString();

      final selectedDate = (state is EventsLoaded)
          ? (state as EventsLoaded).selectedDateStr
          : todayStr;

      final selectedEvents = allEvents.where((e) => e.eventDate == selectedDate).toList();
      final upcoming = allEvents.where((e) => e.eventDate.compareTo(todayStr) >= 0).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      emit(EventsLoaded(
        allEvents: allEvents,
        selectedDateEvents: selectedEvents,
        upcomingEvents: upcoming,
        selectedDateStr: selectedDate,
        totalEventCount: allEvents.length,
      ));
    } catch (e) {
      emit(EventsError(e.toString()));
    }
  }

  Future<void> _onCreateEvent(CreateEvent event, Emitter<EventsState> emit) async {
    try {
      await _eventsRepository.upsertEvent(event.event);
    } catch (e) {
      emit(EventsError('Failed to create event: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateEvent(UpdateEvent event, Emitter<EventsState> emit) async {
    try {
      await _eventsRepository.upsertEvent(event.event);
    } catch (e) {
      emit(EventsError('Failed to update event: ${e.toString()}'));
    }
  }

  Future<void> _onToggleEventCompletion(ToggleEventCompletion event, Emitter<EventsState> emit) async {
    try {
      final allEvents = _eventsRepository.getEvents();
      final target = allEvents.firstWhere((e) => e.id == event.eventId);
      final updated = target.copyWith(completed: !target.completed);
      await _eventsRepository.upsertEvent(updated);
    } catch (e) {
      emit(EventsError('Failed to toggle event: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteEvent(DeleteEvent event, Emitter<EventsState> emit) async {
    try {
      await _eventsRepository.deleteEvent(event.eventId);
    } catch (e) {
      emit(EventsError('Failed to delete event: ${e.toString()}'));
    }
  }

  void _onSelectEventDate(SelectEventDate event, Emitter<EventsState> emit) {
    if (state is EventsLoaded) {
      final current = state as EventsLoaded;
      emit(current.copyWith(selectedDateStr: event.dateStr));
      _recalculateAndEmit(emit);
    }
  }

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    return super.close();
  }
}
