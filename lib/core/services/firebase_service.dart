import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      
      // Enable Firestore offline persistence on native platforms
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
