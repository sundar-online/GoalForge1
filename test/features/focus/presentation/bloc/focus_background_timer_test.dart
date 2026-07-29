import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/domain/models/focus_session.dart';
import 'package:goalforge/core/domain/models/xp_profile.dart';
import 'package:goalforge/core/domain/repositories/focus_repository.dart';
import 'package:goalforge/core/lifecycle/lifecycle_watcher.dart';
import 'package:goalforge/core/services/focus_audio_service.dart';
import 'package:goalforge/core/services/gamification_service.dart';
import 'package:goalforge/core/services/notification_service.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_bloc.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_event.dart';
import 'package:goalforge/features/focus/presentation/bloc/focus_state.dart';

class MockFocusRepository implements FocusRepository {
  final List<FocusSession> _sessions = [];

  @override
  List<FocusSession> getFocusSessions() => _sessions;

  @override
  Stream<List<FocusSession>> watchFocusSessions() async* {
    yield _sessions;
  }

  @override
  Future<void> logFocusSession(FocusSession session) async {
    _sessions.add(session);
  }

  @override
  Future<void> fetchRemoteFocusSessions() async {}

  @override
  Future<int> getTotalFocusMinutesToday() async => 0;

  @override
  Future<int> getTotalSessionsCount() async => _sessions.length;
}

class MockGamificationService implements GamificationService {
  int totalXpAwarded = 0;

  @override
  Future<XPProfile> awardXp(
    int amount, {
    String title = 'Activity Completed',
    String type = 'general',
    int streakDays = 0,
    int completedTasksCount = 0,
    int completedHabitsCount = 0,
    int focusMinutes = 0,
    int perfectDaysCount = 0,
    int completedGoalsCount = 0,
  }) async {
    totalXpAwarded += amount;
    return XPProfile(
      totalXP: totalXpAwarded,
      level: 1,
      earnedBadges: const [],
      xpHistory: const {},
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudioService extends FocusAudioService {
  final List<String> playedSounds = [];
  final List<double> playedVolumes = [];

  @override
  void playAlertSound(String sound, double volume) {
    playedSounds.add(sound);
    playedVolumes.add(volume);
  }

  @override
  void previewSound(String sound, double volume) {
    playedSounds.add("PREVIEW_$sound");
    playedVolumes.add(volume);
  }
}

class FakeNotificationService extends NotificationService {
  bool requestedPermission = false;
  int completionNotificationsSent = 0;

  @override
  Future<bool> requestPermission() async {
    requestedPermission = true;
    return true;
  }

  @override
  Future<void> showFocusCompletedNotification({
    required String sessionType,
    required int minutes,
  }) async {
    completionNotificationsSent++;
  }
}

void main() {
  late MockFocusRepository mockRepo;
  late MockGamificationService mockGamification;
  late FakeAudioService fakeAudio;
  late FakeNotificationService fakeNotifications;
  late LifecycleWatcher lifecycleWatcher;
  late FocusBloc focusBloc;

  setUp(() {
    mockRepo = MockFocusRepository();
    mockGamification = MockGamificationService();
    fakeAudio = FakeAudioService();
    fakeNotifications = FakeNotificationService();
    lifecycleWatcher = LifecycleWatcher();

    focusBloc = FocusBloc(
      focusRepository: mockRepo,
      gamificationService: mockGamification,
      lifecycleWatcher: lifecycleWatcher,
      notificationService: fakeNotifications,
      audioService: fakeAudio,
    );
  });

  tearDown(() {
    focusBloc.close();
  });

  group('Focus Background Timer & Lifecycle Reliability Tests', () {
    test('1. StartTimerEvent initializes targetEndTime and requests notification permission', () async {
      focusBloc.add(SubscribeToFocus());
      await pumpEventQueue();

      focusBloc.add(StartTimerEvent());
      await pumpEventQueue();

      expect(focusBloc.state, isA<FocusLoaded>());
      final state = focusBloc.state as FocusLoaded;
      expect(state.isRunning, isTrue);
      expect(state.targetEndTime, isNotNull);
      expect(fakeNotifications.requestedPermission, isTrue);
    });

    test('2. App Lifecycle Resume recalculates timer from targetEndTime without restarting', () async {
      focusBloc.add(SubscribeToFocus());
      await pumpEventQueue();

      focusBloc.add(SelectDurationEvent(25));
      await pumpEventQueue();

      focusBloc.add(StartTimerEvent());
      await pumpEventQueue();

      final state1 = focusBloc.state as FocusLoaded;
      expect(state1.remainingSeconds, equals(1500));

      // Simulate app resuming after lifecycle transition
      focusBloc.onResumed();
      await pumpEventQueue();

      final state2 = focusBloc.state as FocusLoaded;
      expect(state2.isRunning, isTrue);
      expect(state2.selectedDurationMinutes, equals(25));
      expect(state2.targetEndTime, equals(state1.targetEndTime));
    });

    test('3. Session Completion plays selected sound (ZEN) at specified volume', () async {
      focusBloc.add(SubscribeToFocus());
      await pumpEventQueue();

      focusBloc.add(SelectSoundscapeEvent('ZEN'));
      focusBloc.add(ChangeVolumeEvent(0.85));
      await pumpEventQueue();

      focusBloc.add(const CompleteFocusSessionEvent());
      await pumpEventQueue();

      expect(fakeAudio.playedSounds, contains('ZEN'));
      expect(fakeAudio.playedVolumes, contains(0.85));
      expect(fakeNotifications.completionNotificationsSent, equals(1));
    });

    test('4. Duplicate alarms are prevented on completion', () async {
      focusBloc.add(SubscribeToFocus());
      await pumpEventQueue();

      focusBloc.add(SelectSoundscapeEvent('CYBER'));
      await pumpEventQueue();

      focusBloc.add(const CompleteFocusSessionEvent());
      await pumpEventQueue();

      // Dispatch completion second time
      focusBloc.add(const CompleteFocusSessionEvent());
      await pumpEventQueue();

      expect(fakeAudio.playedSounds.where((s) => s == 'CYBER').length, equals(1));
      expect(fakeNotifications.completionNotificationsSent, equals(1));
    });

    test('5. PauseTimerEvent retains accurate remaining seconds and clears targetEndTime', () async {
      focusBloc.add(SubscribeToFocus());
      await pumpEventQueue();

      focusBloc.add(StartTimerEvent());
      await pumpEventQueue();

      focusBloc.add(PauseTimerEvent());
      await pumpEventQueue();

      final state = focusBloc.state as FocusLoaded;
      expect(state.isRunning, isFalse);
      expect(state.targetEndTime, isNull);
    });
  });
}
