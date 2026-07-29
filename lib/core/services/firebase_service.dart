import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase_options.dart';
import '../utils/logger.dart';

class FirebaseService {
  FirebaseService._();

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static Future<void> init() async {
    try {
      AppLogger.i('Initializing Firebase Core with DefaultFirebaseOptions...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // SAST-11: Activate Firebase App Check to attest that requests originate
      // from genuine GoalForge app instances rather than scripts/bots.
      // - Web: reCAPTCHA v3 (invisible, no user interaction required)
      // - Android: Play Integrity API
      // - iOS / macOS: DeviceCheck
      // In debug mode, the debug provider is used automatically so CI/testing
      // is not blocked.
      try {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(
            // TODO: Replace with your actual reCAPTCHA v3 site key from
            // https://console.firebase.google.com → App Check → Register app
            'YOUR_RECAPTCHA_V3_SITE_KEY',
          ),
          androidProvider: kDebugMode
              ? AndroidProvider.debug
              : AndroidProvider.playIntegrity,
          appleProvider: kDebugMode
              ? AppleProvider.debug
              : AppleProvider.deviceCheck,
        );
        AppLogger.i('Firebase App Check activated successfully.');
      } catch (e) {
        // App Check activation failure is non-fatal during development.
        // In production, consider enforcing App Check in the Firebase console.
        AppLogger.w('Firebase App Check activation warning: $e');
      }

      // Enable Firestore offline persistence on native platforms.
      if (!kIsWeb) {
        db.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      AppLogger.i('Firebase Core initialized successfully with offline persistence settings.');
    } catch (e) {
      AppLogger.w('Firebase initialization warning: $e');
    }
  }
}
