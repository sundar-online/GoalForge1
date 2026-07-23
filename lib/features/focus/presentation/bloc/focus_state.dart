import 'package:equatable/equatable.dart';
import '../../../../core/domain/models/focus_session.dart';

abstract class FocusState extends Equatable {
  const FocusState();

  @override
  List<Object?> get props => [];
}

class FocusInitial extends FocusState {}

class FocusLoading extends FocusState {}

class FocusLoaded extends FocusState {
  final int selectedDurationMinutes;
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;
  final String selectedSound; // 'ZEN', 'CYBER', 'BELL', 'ALARM', 'NONE'
  final double volume;
  final List<FocusSession> sessions;
  final int totalFocusMinutesToday;
  final int totalSessionsCount;

  const FocusLoaded({
    required this.selectedDurationMinutes,
    required this.remainingSeconds,
    this.isRunning = false,
    this.isCompleted = false,
    this.selectedSound = 'BELL',
    this.volume = 0.75,
    required this.sessions,
    this.totalFocusMinutesToday = 0,
    this.totalSessionsCount = 0,
  });

  String get formattedRemainingTime {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progressRatio {
    final totalSeconds = selectedDurationMinutes * 60;
    if (totalSeconds == 0) return 0.0;
    return (1.0 - (remainingSeconds / totalSeconds)).clamp(0.0, 1.0);
  }

  FocusLoaded copyWith({
    int? selectedDurationMinutes,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    String? selectedSound,
    double? volume,
    List<FocusSession>? sessions,
    int? totalFocusMinutesToday,
    int? totalSessionsCount,
  }) {
    return FocusLoaded(
      selectedDurationMinutes: selectedDurationMinutes ?? this.selectedDurationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isCompleted: isCompleted ?? this.isCompleted,
      selectedSound: selectedSound ?? this.selectedSound,
      volume: volume ?? this.volume,
      sessions: sessions ?? this.sessions,
      totalFocusMinutesToday: totalFocusMinutesToday ?? this.totalFocusMinutesToday,
      totalSessionsCount: totalSessionsCount ?? this.totalSessionsCount,
    );
  }

  @override
  List<Object?> get props => [
        selectedDurationMinutes,
        remainingSeconds,
        isRunning,
        isCompleted,
        selectedSound,
        volume,
        sessions,
        totalFocusMinutesToday,
        totalSessionsCount,
      ];
}

class FocusError extends FocusState {
  final String message;
  const FocusError(this.message);

  @override
  List<Object?> get props => [message];
}
