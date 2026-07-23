import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  User? call() {
    return repository.getCurrentUser();
  }
}
