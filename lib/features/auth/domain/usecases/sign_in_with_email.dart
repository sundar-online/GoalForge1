import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  final AuthRepository repository;

  SignInWithEmail(this.repository);

  Future<User> call(String email, String password) {
    return repository.signInWithEmail(email, password);
  }
}
