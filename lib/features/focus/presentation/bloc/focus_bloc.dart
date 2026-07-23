import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/focus_session.dart';
import '../../../../core/domain/repositories/focus_repository.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import 'focus_event.dart';
import 'focus_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> {
  final FocusRepository _focusRepository;
  final GamificationService _gamificationService;

  StreamSubscription? _focusSubscription;
  Timer? _tickerTimer;

  FocusBloc({
    required FocusRepository focusRepository,
    required GamificationService gamificationService,
  })  : _focusRepository = focusRepository,
        _gamificationService = gamificationService,
        super(FocusInitial()) {
    on<SubscribeToFocus>(_onSubscribeToFocus);
    on<StartTimerEvent>(_onStartTimer);
    on<PauseTimerEvent>(_onPauseTimer);
    on<ResetTimerEvent>(_onResetTimer);
    on<TickTimerEvent>(_onTickTimer);
    on<CompleteFocusSessionEvent>(_onCompleteFocusSession);
    on<SelectDurationEvent>(_onSelectDuration);
    on<SelectSoundscapeEvent>(_onSelectSoundscape);
    on<ChangeVolumeEvent>(_onChangeVolume);
  }

  Future<void> _onSubscribeToFocus(SubscribeToFocus event, Emitter<FocusState> emit) async {
    emit(FocusLoading());
    await _focusSubscription?.cancel();

    _focusSubscription = _focusRepository.watchFocusSessions().listen((_) {
      if (!isClosed) {
        add(SubscribeToFocus());
      }
    });

    _recalculateAndEmit(emit, durationMinutes: 60);
  }

  void _recalculateAndEmit(
    Emitter<FocusState> emit, {
    int? durationMinutes,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    String? selectedSound,
    double? volume,
  }) {
    try {
      final sessions = _focusRepository.getFocusSessions();
      final todayStr = AppDateUtils.getTodayString();

      final todaySessions = sessions.where((s) => s.createdAt.startsWith(todayStr)).toList();
      final totalSecondsToday = todaySessions.fold<int>(0, (sum, s) => sum + s.timeSpentSeconds);
      final totalMinutesToday = (totalSecondsToday / 60).round();

      final currDuration = durationMinutes ??
          ((state is FocusLoaded) ? (state as FocusLoaded).selectedDurationMinutes : 60);
      final currRemaining = remainingSeconds ??
          ((state is FocusLoaded) ? (state as FocusLoaded).remainingSeconds : currDuration * 60);
      final currRunning = isRunning ??
          ((state is FocusLoaded) ? (state as FocusLoaded).isRunning : false);
      final currCompleted = isCompleted ??
          ((state is FocusLoaded) ? (state as FocusLoaded).isCompleted : false);
      final currSound = selectedSound ??
          ((state is FocusLoaded) ? (state as FocusLoaded).selectedSound : 'BELL');
      final currVol = volume ??
          ((state is FocusLoaded) ? (state as FocusLoaded).volume : 0.75);

      emit(FocusLoaded(
        selectedDurationMinutes: currDuration,
        remainingSeconds: currRemaining,
        isRunning: currRunning,
        isCompleted: currCompleted,
        selectedSound: currSound,
        volume: currVol,
        sessions: sessions,
        totalFocusMinutesToday: totalMinutesToday,
        totalSessionsCount: todaySessions.length,
      ));
    } catch (e) {
      emit(FocusError(e.toString()));
    }
  }

  void _onStartTimer(StartTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isClosed) add(TickTimerEvent());
      });
      emit(current.copyWith(isRunning: true, isCompleted: false));
    }
  }

  void _onPauseTimer(PauseTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();
      emit(current.copyWith(isRunning: false));
    }
  }

  void _onResetTimer(ResetTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();
      final resetSeconds = current.selectedDurationMinutes * 60;
      emit(current.copyWith(
        remainingSeconds: resetSeconds,
        isRunning: false,
        isCompleted: false,
      ));
    }
  }

  void _onTickTimer(TickTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      if (current.remainingSeconds <= 1) {
        _tickerTimer?.cancel();
        add(const CompleteFocusSessionEvent());
      } else {
        emit(current.copyWith(remainingSeconds: current.remainingSeconds - 1));
      }
    }
  }

  Future<void> _onCompleteFocusSession(
      CompleteFocusSessionEvent event, Emitter<FocusState> emit) async {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();

      final spentSeconds = (current.selectedDurationMinutes * 60) - current.remainingSeconds;
      final session = FocusSession(
        id: UuidGenerator.generate(),
        goalId: event.goalId,
        itemId: event.itemId,
        duration: current.selectedDurationMinutes,
        timeSpentSeconds: spentSeconds > 0 ? spentSeconds : current.selectedDurationMinutes * 60,
        type: 'pomodoro',
        soundTrack: current.selectedSound,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _focusRepository.logFocusSession(session);

      // Award +100 XP on completed focus session
      await _gamificationService.awardXp(100);

      _recalculateAndEmit(
        emit,
        remainingSeconds: 0,
        isRunning: false,
        isCompleted: true,
      );
    }
  }

  void _onSelectDuration(SelectDurationEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();
      emit(current.copyWith(
        selectedDurationMinutes: event.minutes,
        remainingSeconds: event.minutes * 60,
        isRunning: false,
        isCompleted: false,
      ));
    }
  }

  void _onSelectSoundscape(SelectSoundscapeEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      emit(current.copyWith(selectedSound: event.sound));
    }
  }

  void _onChangeVolume(ChangeVolumeEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      emit(current.copyWith(volume: event.volume));
    }
  }

  @override
  Future<void> close() {
    _focusSubscription?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}
