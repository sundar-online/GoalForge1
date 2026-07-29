import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/password_validator.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth Repository — security hardened implementation.
///
/// Security fixes applied:
/// - SAST-04: All log messages are PII-free (no email, no UID logged).
/// - SAST-07: Exponential backoff rate limiter on email sign-in to resist
///   brute-force attacks at the client layer, complementing Firebase limits.
/// - SAST-08: Password reset always waits a fixed + small random delay before
///   returning, regardless of outcome, to prevent email enumeration via
///   differential response timing.
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  // SAST-07: Rate limiter state — tracks failures per session.
  int _signInFailureCount = 0;
  DateTime? _lastFailureTime;
  static const int _maxImmediateAttempts = 3;
  static const Duration _backoffBase = Duration(milliseconds: 500);

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<User?> get authStateChanges {
    try {
      return _firebaseAuth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  User? getCurrentUser() {
    try {
      return _firebaseAuth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Applies exponential backoff delay based on recent failure count (SAST-07).
  Future<void> _applyBackoff() async {
    if (_signInFailureCount < _maxImmediateAttempts) return;
    final exponent = min(_signInFailureCount - _maxImmediateAttempts, 6);
    final delayMs = _backoffBase.inMilliseconds * (1 << exponent);
    final jitter = Random().nextInt(200);
    AppLogger.d('AuthRateLimit: applying backoff delay of ${delayMs + jitter}ms');
    await Future.delayed(Duration(milliseconds: delayMs + jitter));
  }

  @override
  Future<User> signInWithEmail(String email, String password) async {
    // SAST-07: Apply exponential backoff on repeated failures.
    await _applyBackoff();

    try {
      final normalized = AuthValidator.normalizeEmail(email);
      AppLogger.i('Attempting signInWithEmail'); // SAST-04: no email in log
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('User credential payload is null.');
      }
      // Reset failure counter on success.
      _signInFailureCount = 0;
      _lastFailureTime = null;
      AppLogger.i('signInWithEmail succeeded'); // SAST-04: no uid in log
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      _signInFailureCount++;
      _lastFailureTime = DateTime.now();
      // SAST-04: log code only, never log email or uid
      AppLogger.e('FirebaseAuthException in signInWithEmail: ${e.code}');
      throw ServerException(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      _signInFailureCount++;
      _lastFailureTime = DateTime.now();
      AppLogger.e('Unexpected exception in signInWithEmail');
      throw ServerException('An unexpected error occurred during email sign in.');
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final normalized = AuthValidator.normalizeEmail(email);
      AppLogger.i('Attempting signUpWithEmail'); // SAST-04: no email in log
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw ServerException('User creation failed.');
      }

      // Update display name profile safely.
      if (displayName.trim().isNotEmpty) {
        try {
          await user.updateDisplayName(displayName.trim());
          await user.reload();
        } catch (e) {
          AppLogger.w('Non-fatal: Could not update Firebase Auth display name.');
        }
      }

      // Write user profile document to Firestore users/{uid}.
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': normalized,
          'displayName': displayName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        AppLogger.i('signUpWithEmail: Firestore user document written.'); // SAST-04: no uid/email in log
      } catch (e) {
        AppLogger.w('Non-fatal: Could not write Firestore user profile document.');
      }

      final currentUser = _firebaseAuth.currentUser ?? user;
      AppLogger.i('signUpWithEmail completed successfully.'); // SAST-04: no uid/email
      return currentUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('FirebaseAuthException in signUpWithEmail: ${e.code}');
      throw ServerException(e.message ?? 'User registration error occurred.');
    } catch (e) {
      AppLogger.e('Unexpected exception in signUpWithEmail');
      throw ServerException('An unexpected error occurred during user registration.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // SAST-08: Fixed-duration window normalizes response time across all outcomes
    // (valid account, invalid account, network error) to prevent email enumeration
    // via differential timing analysis.
    const _minWindowMs = 800;
    final stopwatch = Stopwatch()..start();

    try {
      final normalized = AuthValidator.normalizeEmail(email);
      await _firebaseAuth.sendPasswordResetEmail(email: normalized);
    } on FirebaseAuthException catch (e) {
      // Swallow user-not-found and invalid-email silently (anti-enumeration).
      if (e.code != 'user-not-found' && e.code != 'invalid-email') {
        // Only throw on genuine network / server errors.
        throw ServerException(e.message ?? 'Failed to send password reset email.');
      }
      // Fall through to timing normalization below.
    } catch (e) {
      throw ServerException('An unexpected error occurred.');
    } finally {
      // SAST-08: Pad remaining time to [_minWindowMs] + small random jitter
      // so every call to this method takes ~800-1000ms regardless of outcome.
      stopwatch.stop();
      final elapsed = stopwatch.elapsedMilliseconds;
      final remaining = _minWindowMs - elapsed;
      if (remaining > 0) {
        final jitter = Random().nextInt(200);
        await Future.delayed(Duration(milliseconds: remaining + jitter));
      }
    }
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw ServerException('Google authentication flow cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw ServerException('Failed to authenticate with Google credentials.');
      }

      // SAST-04: no uid logged
      AppLogger.i('signInWithGoogle succeeded.');
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Google OAuth registration error occurred.');
    } catch (e) {
      throw ServerException('An unexpected error occurred during Google Sign In.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
      // Reset rate-limiter on sign-out.
      _signInFailureCount = 0;
      _lastFailureTime = null;
      AppLogger.i('User signed out successfully.');
    } catch (e) {
      throw ServerException('An error occurred during sign out.');
    }
  }
}


