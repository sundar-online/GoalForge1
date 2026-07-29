import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/domain/models/focus_session.dart';
import '../../../../core/domain/repositories/focus_repository.dart';
import '../../../../core/lifecycle/lifecycle_watcher.dart';
import '../../../../core/services/focus_audio_service.dart';
import '../../../../core/services/gamification_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import 'focus_event.dart';
import 'focus_state.dart';

class FocusBloc extends Bloc<FocusEvent, FocusState> implements AppLifecycleListener {
  final FocusRepository _focusRepository;
  final GamificationService _gamificationService;
  final LifecycleWatcher? _lifecycleWatcher;
  final NotificationService? _notificationService;
  final FocusAudioService? _audioService;

  StreamSubscription? _focusSubscription;
  Timer? _tickerTimer;

  FocusBloc({
    required FocusRepository focusRepository,
    required GamificationService gamificationService,
    LifecycleWatcher? lifecycleWatcher,
    NotificationService? notificationService,
    FocusAudioService? audioService,
  })  : _focusRepository = focusRepository,
        _gamificationService = gamificationService,
        _lifecycleWatcher = lifecycleWatcher,
        _notificationService = notificationService,
        _audioService = audioService,
        super(FocusInitial()) {
    _lifecycleWatcher?.addListener(this);

    on<SubscribeToFocus>(_onSubscribeToFocus);
    on<_FocusDataChanged>(_onFocusDataChanged);
    on<StartTimerEvent>(_onStartTimer);
    on<PauseTimerEvent>(_onPauseTimer);
    on<ResetTimerEvent>(_onResetTimer);
    on<TickTimerEvent>(_onTickTimer);
    on<RecalculateTimerEvent>(_onRecalculateTimer);
    on<CompleteFocusSessionEvent>(_onCompleteFocusSession);
    on<SelectDurationEvent>(_onSelectDuration);
    on<SelectSoundscapeEvent>(_onSelectSoundscape);
    on<ChangeVolumeEvent>(_onChangeVolume);
    on<PreviewSoundEvent>(_onPreviewSound);
  }

  @override
  void onResumed() {
    add(RecalculateTimerEvent());
  }

  @override
  void onPaused() {
    add(RecalculateTimerEvent());
  }

  @override
  void onInactive() {
    add(RecalculateTimerEvent());
  }

  @override
  void onDetached() {}

  void _onSubscribeToFocus(SubscribeToFocus event, Emitter<FocusState> emit) {
    emit(FocusLoading());
    _focusSubscription?.cancel();

    _focusSubscription = _focusRepository.watchFocusSessions().skip(1).listen((_) {
      if (!isClosed) add(const _FocusDataChanged());
    });

    _recalculateAndEmit(emit, durationMinutes: 60);
  }

  void _onFocusDataChanged(_FocusDataChanged event, Emitter<FocusState> emit) {
    _recalculateAndEmit(emit);
  }

  void _recalculateAndEmit(
    Emitter<FocusState> emit, {
    int? durationMinutes,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
    String? selectedSound,
    double? volume,
    DateTime? targetEndTime,
    bool? hasPlayedAlarm,
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
      final currTargetEndTime = targetEndTime ??
          ((state is FocusLoaded) ? (state as FocusLoaded).targetEndTime : null);
      final currHasPlayed = hasPlayedAlarm ??
          ((state is FocusLoaded) ? (state as FocusLoaded).hasPlayedAlarm : false);

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
        targetEndTime: currTargetEndTime,
        hasPlayedAlarm: currHasPlayed,
      ));
    } catch (e) {
      emit(FocusError(e.toString()));
    }
  }

  void _onStartTimer(StartTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();

      final targetEndTime = DateTime.now().add(Duration(seconds: current.remainingSeconds));

      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isClosed) add(TickTimerEvent());
      });

      _notificationService?.requestPermission();

      emit(current.copyWith(
        isRunning: true,
        isCompleted: false,
        targetEndTime: targetEndTime,
        hasPlayedAlarm: false,
      ));
    }
  }

  void _onPauseTimer(PauseTimerEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();

      final remaining = current.targetEndTime != null
          ? math.max(0, current.targetEndTime!.difference(DateTime.now()).inSeconds)
          : current.remainingSeconds;

      emit(current.copyWith(
        isRunning: false,
        remainingSeconds: remaining,
        targetEndTime: null,
      ));
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
        targetEndTime: null,
        hasPlayedAlarm: false,
      ));
    }
  }

  void _onTickTimer(TickTimerEvent event, Emitter<FocusState> emit) {
    _evaluateTimerState(emit);
  }

  void _onRecalculateTimer(RecalculateTimerEvent event, Emitter<FocusState> emit) {
    _evaluateTimerState(emit);
  }

  void _evaluateTimerState(Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      if (!current.isRunning || current.targetEndTime == null) return;

      final now = DateTime.now();
      final diff = current.targetEndTime!.difference(now).inSeconds;

      if (diff <= 0) {
        _tickerTimer?.cancel();
        emit(current.copyWith(
          remainingSeconds: 0,
          isRunning: false,
          targetEndTime: null,
        ));
        add(const CompleteFocusSessionEvent());
      } else {
        if (diff != current.remainingSeconds) {
          emit(current.copyWith(remainingSeconds: diff));
        }
      }
    }
  }

  Future<void> _onCompleteFocusSession(
      CompleteFocusSessionEvent event, Emitter<FocusState> emit) async {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _tickerTimer?.cancel();

      if (!current.hasPlayedAlarm) {
        _audioService?.playAlertSound(current.selectedSound, current.volume);
        _notificationService?.showFocusCompletedNotification(
          sessionType: 'pomodoro',
          minutes: current.selectedDurationMinutes,
        );
      }

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
      await _gamificationService.awardXp(100);

      _recalculateAndEmit(
        emit,
        remainingSeconds: 0,
        isRunning: false,
        isCompleted: true,
        hasPlayedAlarm: true,
        targetEndTime: null,
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
        targetEndTime: null,
        hasPlayedAlarm: false,
      ));
    }
  }

  void _onSelectSoundscape(SelectSoundscapeEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      emit(current.copyWith(selectedSound: event.sound));
      _audioService?.previewSound(event.sound, current.volume);
    }
  }

  void _onChangeVolume(ChangeVolumeEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      emit(current.copyWith(volume: event.volume));
    }
  }

  void _onPreviewSound(PreviewSoundEvent event, Emitter<FocusState> emit) {
    if (state is FocusLoaded) {
      final current = state as FocusLoaded;
      _audioService?.previewSound(event.sound, current.volume);
    }
  }

  @override
  Future<void> close() {
    _lifecycleWatcher?.removeListener(this);
    _focusSubscription?.cancel();
    _tickerTimer?.cancel();
    return super.close();
  }
}

class _FocusDataChanged extends FocusEvent {
  const _FocusDataChanged();
}
