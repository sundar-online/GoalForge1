import 'package:flutter_test/flutter_test.dart';
import 'package:goalforge/core/utils/password_validator.dart';
import 'package:goalforge/features/auth/domain/repositories/auth_repository.dart';
import 'package:goalforge/features/auth/domain/usecases/get_current_user.dart';
import 'package:goalforge/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:goalforge/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:goalforge/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:goalforge/features/auth/domain/usecases/sign_out.dart';
import 'package:goalforge/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_event.dart';
import 'package:goalforge/features/auth/presentation/bloc/auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockAuthRepository implements AuthRepository {
  String? lastNormalizedEmail;
  bool sendPasswordResetCalled = false;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  User? getCurrentUser() => null;

  @override
  Future<User> signInWithEmail(String email, String password) async {
    lastNormalizedEmail = email;
    throw UnimplementedError();
  }

  @override
  Future<User> signUpWithEmail(String email, String password, String displayName) async {
    lastNormalizedEmail = email;
    throw UnimplementedError();
  }

  @override
  Future<User> signInWithGoogle() async => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sendPasswordResetCalled = true;
    lastNormalizedEmail = email;
  }
}

void main() {
  group("1. Password Policy Validation Tests", () {
    test("rejects weak password missing required criteria", () {
      // 123456 fails length, uppercase, lowercase, special char
      final res1 = AuthValidator.validatePassword("123456");
      expect(res1.isValid, isFalse);
      expect(res1.hasMinLength, isFalse);

      // Password1 fails special char
      final res2 = AuthValidator.validatePassword("Password1");
      expect(res2.isValid, isFalse);
      expect(res2.hasSpecialChar, isFalse);

      // password1! fails uppercase
      final res3 = AuthValidator.validatePassword("password1!");
      expect(res3.isValid, isFalse);
      expect(res3.hasUppercase, isFalse);
    });

    test("accepts strong password meeting all 5 criteria", () {
      final res = AuthValidator.validatePassword("P@ssword123");
      expect(res.isValid, isTrue);
      expect(res.hasMinLength, isTrue);
      expect(res.hasUppercase, isTrue);
      expect(res.hasLowercase, isTrue);
      expect(res.hasDigit, isTrue);
      expect(res.hasSpecialChar, isTrue);
    });

    test("accepts password manager symbols like underscores, hyphens, and tildes", () {
      final res1 = AuthValidator.validatePassword("P_ssword123");
      expect(res1.isValid, isTrue);

      final res2 = AuthValidator.validatePassword("P-ssword123");
      expect(res2.isValid, isTrue);

      final res3 = AuthValidator.validatePassword("P~ssword123");
      expect(res3.isValid, isTrue);
    });

    test("login validation permits existing weak passwords (non-empty only)", () {
      expect(AuthValidator.validateLoginPassword("123456"), isNull);
      expect(AuthValidator.validateLoginPassword(""), equals("Please enter your password"));
      expect(AuthValidator.validateLoginPassword(null), equals("Please enter your password"));
    });
  });

  group("2. Email Normalization & Format Validation Tests", () {
    test("normalizes email by trimming whitespace and lowercasing", () {
      expect(AuthValidator.normalizeEmail(" SunDar123@Gmail.COM "), equals("sundar123@gmail.com"));
      expect(AuthValidator.normalizeEmail("USER.NAME@DOMAIN.CO.UK"), equals("user.name@domain.co.uk"));
    });

    test("rejects malformed email formats", () {
      expect(AuthValidator.isValidEmail("invalid-email"), isFalse);
      expect(AuthValidator.isValidEmail("user@"), isFalse);
      expect(AuthValidator.isValidEmail("@domain.com"), isFalse);
      expect(AuthValidator.isValidEmail("user@domain"), isFalse);
      expect(AuthValidator.isValidEmail(""), isFalse);
      expect(AuthValidator.isValidEmail(null), isFalse);
    });

    test("accepts valid email formats", () {
      expect(AuthValidator.isValidEmail("sundar@gmail.com"), isTrue);
      expect(AuthValidator.isValidEmail("user.name+tag@sub.domain.org"), isTrue);
    });
  });

  group("3. Forgot Password Flow & BLoC Integration Tests", () {
    late MockAuthRepository mockRepo;
    late AuthBloc authBloc;

    setUp(() {
      mockRepo = MockAuthRepository();
      authBloc = AuthBloc(
        signInWithEmail: SignInWithEmail(mockRepo),
        signUpWithEmail: SignUpWithEmail(mockRepo),
        signInWithGoogle: SignInWithGoogle(mockRepo),
        signOut: SignOut(mockRepo),
        getCurrentUser: GetCurrentUser(mockRepo),
        sendPasswordResetEmail: SendPasswordResetEmail(mockRepo),
        authRepository: mockRepo,
      );
    });

    tearDown(() {
      authBloc.close();
    });

    test("dispatches PasswordResetRequested and normalizes email before repository call", () async {
      final states = <AuthState>[];
      final subscription = authBloc.stream.listen(states.add);

      authBloc.add(const PasswordResetRequested("   UserRecruit@Domain.COM  "));

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockRepo.sendPasswordResetCalled, isTrue);
      expect(mockRepo.lastNormalizedEmail, equals("userrecruit@domain.com"));

      expect(states, contains(isA<PasswordResetSent>()));
      final resetState = states.firstWhere((s) => s is PasswordResetSent) as PasswordResetSent;
      expect(resetState.message, contains("If an account exists with this email"));

      await subscription.cancel();
    });
  });
}
