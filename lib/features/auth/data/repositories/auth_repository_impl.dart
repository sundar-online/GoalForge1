import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/error/exceptions.dart';
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
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('User credential payload is null.');
      }
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      throw ServerException('An unexpected error occurred during email sign in: $e');
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw ServerException('User creation failed.');
      }
      // Update display name profile
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();
      return _firebaseAuth.currentUser!;
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'User registration error occurred.');
    } catch (e) {
      throw ServerException('An unexpected error occurred during user registration: $e');
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
