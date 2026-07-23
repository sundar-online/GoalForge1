import 'package:equatable/equatable.dart';

abstract class FocusEvent extends Equatable {
  const FocusEvent();

  @override
  List<Object?> get props => [];
}

class SubscribeToFocus extends FocusEvent {}

class StartTimerEvent extends FocusEvent {}

class PauseTimerEvent extends FocusEvent {}

class ResetTimerEvent extends FocusEvent {}

class TickTimerEvent extends FocusEvent {}

class CompleteFocusSessionEvent extends FocusEvent {
  final String? goalId;
  final String? itemId;

  const CompleteFocusSessionEvent({this.goalId, this.itemId});

  @override
  List<Object?> get props => [goalId, itemId];
}

class SelectDurationEvent extends FocusEvent {
  final int minutes;

  const SelectDurationEvent(this.minutes);

  @override
  List<Object?> get props => [minutes];
}

class SelectSoundscapeEvent extends FocusEvent {
  final String sound;

  const SelectSoundscapeEvent(this.sound);

  @override
  List<Object?> get props => [sound];
}

class ChangeVolumeEvent extends FocusEvent {
  final double volume;

  const ChangeVolumeEvent(this.volume);

  @override
  List<Object?> get props => [volume];
}
