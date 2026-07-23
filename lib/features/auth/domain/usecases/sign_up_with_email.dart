import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  Future<User> call(String email, String password, String displayName) {
    return repository.signUpWithEmail(email, password, displayName);
  }
}
