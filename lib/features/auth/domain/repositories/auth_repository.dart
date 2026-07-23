import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges;

  /// Sign in with email and password.
  Future<User> signInWithEmail(String email, String password);

  /// Sign up with email and password.
  Future<User> signUpWithEmail(String email, String password, String displayName);

  /// Sign in with Google OAuth credentials.
  Future<User> signInWithGoogle();

  /// Sign out current user.
  Future<void> signOut();

  /// Get current user.
  User? getCurrentUser();
}
