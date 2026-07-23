import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  SignInWithGoogle(this.repository);

  Future<User> call() {
    return repository.signInWithGoogle();
  }
}
