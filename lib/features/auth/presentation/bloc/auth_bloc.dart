import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/password_validator.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_password_reset_email.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInWithEmail signInWithEmail;
  final SignUpWithEmail signUpWithEmail;
  final SignInWithGoogle signInWithGoogle;
  final SignOut signOut;
  final GetCurrentUser getCurrentUser;
  final SendPasswordResetEmail? sendPasswordResetEmail;
  final AuthRepository authRepository;
  
  StreamSubscription<User?>? _authStateSubscription;

  AuthBloc({
    required this.signInWithEmail,
    required this.signUpWithEmail,
    required this.signInWithGoogle,
    required this.signOut,
    required this.getCurrentUser,
    this.sendPasswordResetEmail,
    required this.authRepository,
  })  : super(AuthInitial()) {
    
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);

    // Subscribe to Firebase Auth state stream changes
    _authStateSubscription = authRepository.authStateChanges.listen((user) {
      add(_AuthUserChanged(user));
    });
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = getCurrentUser();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final normalizedEmail = AuthValidator.normalizeEmail(event.email);
      final user = await signInWithEmail(normalizedEmail, event.password);
      emit(Authenticated(user));
    } catch (e) {
      final failure = FailureMapper.map(e);
      emit(AuthError(failure.message));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final normalizedEmail = AuthValidator.normalizeEmail(event.email);
      final user = await signUpWithEmail(
        normalizedEmail,
        event.password,
        event.displayName,
      );
      emit(Authenticated(user));
    } catch (e) {
      final failure = FailureMapper.map(e);
      emit(AuthError(failure.message));
    }
  }

  Future<void> _onPasswordResetRequested(
    PasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final normalizedEmail = AuthValidator.normalizeEmail(event.email);
      if (sendPasswordResetEmail != null) {
        await sendPasswordResetEmail!(normalizedEmail);
      } else {
        await authRepository.sendPasswordResetEmail(normalizedEmail);
      }
      // Always show generic security response per Option A
      emit(const PasswordResetSent(
        'If an account exists with this email, a password reset link has been sent.',
      ));
    } catch (e) {
      // Even if network exception occurs, emit generic response or failure
      final failure = FailureMapper.map(e);
      emit(AuthError(failure.message));
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await signInWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      final failure = FailureMapper.map(e);
      emit(AuthError(failure.message));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await signOut();
      emit(Unauthenticated());
    } catch (e) {
      final failure = FailureMapper.map(e);
      emit(AuthError(failure.message));
    }
  }

  void _onAuthUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}

// Private internal event to handle streams
class _AuthUserChanged extends AuthEvent {
  final User? user;
  const _AuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
