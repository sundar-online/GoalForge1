import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/sync_engine.dart';
import '../services/streak_service.dart';
import '../services/progress_service.dart';
import '../services/gamification_service.dart';
import '../domain/repositories/goals_repository.dart';
import '../data/repositories/goals_repository_impl.dart';
import '../domain/repositories/tasks_repository.dart';
import '../data/repositories/tasks_repository_impl.dart';
import '../domain/repositories/notes_repository.dart';
import '../data/repositories/notes_repository_impl.dart';
import '../domain/repositories/focus_repository.dart';
import '../data/repositories/focus_repository_impl.dart';
import '../domain/repositories/gamification_repository.dart';
import '../data/repositories/gamification_repository_impl.dart';
import '../domain/repositories/settings_repository.dart';
import '../data/repositories/settings_repository_impl.dart';
import '../domain/repositories/events_repository.dart';
import '../data/repositories/events_repository_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user.dart';
import '../../features/auth/domain/usecases/send_password_reset_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_email.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/goals/presentation/bloc/goals_bloc.dart';
import '../../features/habits/presentation/bloc/habits_bloc.dart';
import '../../features/tasks/presentation/bloc/tasks_bloc.dart';
import '../../features/logs/presentation/bloc/notes_bloc.dart';
import '../../features/events/presentation/bloc/events_bloc.dart';
import '../../features/focus/presentation/bloc/focus_bloc.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../services/focus_audio_service.dart';
import '../services/ai_insights_service.dart';
import '../services/notification_service.dart';
import '../lifecycle/lifecycle_watcher.dart';
import '../theme/theme_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core Theme
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  // Core Utilities & Services
  sl.registerLazySingleton<LifecycleWatcher>(() => LifecycleWatcher());
  sl.registerLazySingleton<StreakService>(() => const StreakService());
  sl.registerLazySingleton<ProgressService>(() => const ProgressService());
  sl.registerLazySingleton<GamificationService>(
    () => GamificationService(gamificationRepository: sl<GamificationRepository>()),
  );
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  await sl<NotificationService>().initialize();
  sl.registerLazySingleton<FocusAudioService>(() => FocusAudioService());
  sl.registerLazySingleton<AiInsightsService>(() => const AiInsightsService());

  // Firebase Clients & Google Sign In dependencies
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Sync Engine
  sl.registerLazySingleton<SyncEngine>(
    () => SyncEngine(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
    ),
  );

  sl.registerLazySingleton<GoalsRepository>(
    () => GoalsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
    ),
  );

  sl.registerLazySingleton<TasksRepository>(
    () => TasksRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
    ),
  );

  sl.registerLazySingleton<NotesRepository>(
    () => NotesRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
    ),
  );

  sl.registerLazySingleton<FocusRepository>(
    () => FocusRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
      notificationService: sl<NotificationService>(),
    ),
  );

  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
    ),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
    ),
  );

  sl.registerLazySingleton<EventsRepository>(
    () => EventsRepositoryImpl(
      firestore: sl<FirebaseFirestore>(),
      firebaseAuth: sl<FirebaseAuth>(),
      syncEngine: sl<SyncEngine>(),
      notificationService: sl<NotificationService>(),
    ),
  );

  // Auth Use Cases
  sl.registerLazySingleton<SignInWithEmail>(() => SignInWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton<SignUpWithEmail>(() => SignUpWithEmail(sl<AuthRepository>()));
  sl.registerLazySingleton<SignInWithGoogle>(() => SignInWithGoogle(sl<AuthRepository>()));
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<GetCurrentUser>(() => GetCurrentUser(sl<AuthRepository>()));
  sl.registerLazySingleton<SendPasswordResetEmail>(() => SendPasswordResetEmail(sl<AuthRepository>()));
  // BLoCs
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      signInWithEmail: sl<SignInWithEmail>(),
      signUpWithEmail: sl<SignUpWithEmail>(),
      signInWithGoogle: sl<SignInWithGoogle>(),
      signOut: sl<SignOut>(),
      getCurrentUser: sl<GetCurrentUser>(),
      sendPasswordResetEmail: sl<SendPasswordResetEmail>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  sl.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      goalsRepository: sl<GoalsRepository>(),
      tasksRepository: sl<TasksRepository>(),
      notesRepository: sl<NotesRepository>(),
      focusRepository: sl<FocusRepository>(),
      gamificationRepository: sl<GamificationRepository>(),
      eventsRepository: sl<EventsRepository>(),
    ),
  );

  sl.registerFactory<GoalsBloc>(
    () => GoalsBloc(
      goalsRepository: sl<GoalsRepository>(),
    ),
  );

  sl.registerFactory<HabitsBloc>(
    () => HabitsBloc(
      goalsRepository: sl<GoalsRepository>(),
      gamificationService: sl<GamificationService>(),
      lifecycleWatcher: sl<LifecycleWatcher>(),
    ),
  );

  sl.registerFactory<TasksBloc>(
    () => TasksBloc(
      tasksRepository: sl<TasksRepository>(),
      gamificationService: sl<GamificationService>(),
    ),
  );

  sl.registerFactory<NotesBloc>(
    () => NotesBloc(
      notesRepository: sl<NotesRepository>(),
    ),
  );

  sl.registerFactory<EventsBloc>(
    () => EventsBloc(
      eventsRepository: sl<EventsRepository>(),
    ),
  );

  sl.registerFactory<FocusBloc>(
    () => FocusBloc(
      focusRepository: sl<FocusRepository>(),
      gamificationService: sl<GamificationService>(),
      lifecycleWatcher: sl<LifecycleWatcher>(),
      notificationService: sl<NotificationService>(),
      audioService: sl<FocusAudioService>(),
    ),
  );

  sl.registerFactory<AnalyticsBloc>(
    () => AnalyticsBloc(
      goalsRepository: sl<GoalsRepository>(),
      tasksRepository: sl<TasksRepository>(),
      focusRepository: sl<FocusRepository>(),
      gamificationRepository: sl<GamificationRepository>(),
      gamificationService: sl<GamificationService>(),
    ),
  );

  sl.registerFactory<ProfileBloc>(
    () => ProfileBloc(
      gamificationRepository: sl<GamificationRepository>(),
      gamificationService: sl<GamificationService>(),
      goalsRepository: sl<GoalsRepository>(),
      tasksRepository: sl<TasksRepository>(),
      focusRepository: sl<FocusRepository>(),
      firebaseAuth: sl<FirebaseAuth>(),
    ),
  );
}
