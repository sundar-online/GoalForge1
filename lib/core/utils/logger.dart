import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';

/// Secure application logger.
///
/// **Security policy (SAST-03)**:
/// All logging is completely disabled in release/production builds via the
/// [kReleaseMode] guard.  This prevents PII (emails, UIDs, stack traces)
/// from being written to device logs where they could be harvested by
/// other apps on a rooted device or via ADB.
///
/// Debug and profile builds retain full verbose logging to assist development.
class AppLogger {
  AppLogger._();

  // Noop logger used in release mode — zero overhead, zero output.
  static final Logger _noopLogger = Logger(
    level: Level.off,
    printer: SimplePrinter(),
  );

  static final Logger _devLogger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static Logger get _logger => kReleaseMode ? _noopLogger : _devLogger;

  /// Debug-level log — suppressed in release builds.
  static void d(String message) => _logger.d(message);

  /// Info-level log — suppressed in release builds.
  static void i(String message) => _logger.i(message);

  /// Warning-level log — suppressed in release builds.
  static void w(String message) => _logger.w(message);

  /// Error-level log — suppressed in release builds.
  /// Never pass raw PII (email, UID, passwords) as [message].
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
