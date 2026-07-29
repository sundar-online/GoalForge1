import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/password_validator.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

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

  @override
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final normalized = AuthValidator.normalizeEmail(email);
      AppLogger.i('Attempting signInWithEmail for normalized email: $normalized');
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('User credential payload is null.');
      }
      AppLogger.i('signInWithEmail succeeded for user: ${credential.user!.uid}');
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('FirebaseAuthException in signInWithEmail: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      AppLogger.e('Unexpected exception in signInWithEmail: $e');
      throw ServerException('An unexpected error occurred during email sign in: $e');
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final normalized = AuthValidator.normalizeEmail(email);
      AppLogger.i('Attempting signUpWithEmail for normalized email: $normalized');
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalized,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw ServerException('User creation failed.');
      }
      
      // Update display name profile safely
      if (displayName.trim().isNotEmpty) {
        try {
          await user.updateDisplayName(displayName.trim());
          await user.reload();
        } catch (e) {
          AppLogger.w('Non-fatal warning: Could not update Firebase Auth display name: $e');
        }
      }

      // Write user profile document to Firestore users/{uid}
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': normalized,
          'displayName': displayName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        AppLogger.i('Successfully written Firestore user document for uid: ${user.uid}');
      } catch (e) {
        AppLogger.w('Non-fatal warning: Could not write Firestore user profile document: $e');
      }

      final currentUser = _firebaseAuth.currentUser ?? user;
      AppLogger.i('signUpWithEmail completed successfully for user: ${currentUser.uid} (${currentUser.email})');
      return currentUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.e('FirebaseAuthException in signUpWithEmail: ${e.code} - ${e.message}');
      throw ServerException(e.message ?? 'User registration error occurred.');
    } catch (e) {
      AppLogger.e('Unexpected exception in signUpWithEmail: $e');
      throw ServerException('An unexpected error occurred during user registration: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final normalized = AuthValidator.normalizeEmail(email);
      await _firebaseAuth.sendPasswordResetEmail(email: normalized);
    } on FirebaseAuthException catch (e) {
      // Per security policy (Option A), if user-not-found occurs or any reset email error occurs,
      // we log internally or swallow non-fatal exceptions so we never leak account existence.
      // But if there is a severe network failure, throw ServerException.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        // Silent swallow for user privacy
        return;
      }
      throw ServerException(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
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

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw ServerException('Failed to authenticate with Google credentials.');
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Google OAuth registration error occurred.');
    } catch (e) {
      throw ServerException('An unexpected error occurred during Google Sign In: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerException('An error occurred during sign out: $e');
    }
  }
}
