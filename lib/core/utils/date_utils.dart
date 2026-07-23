import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _yMMMdFormat = DateFormat('d MMM yyyy');
  static final DateFormat _yyyyMMddFormat = DateFormat('yyyy-MM-dd');

  /// Formats Date into YYYY-MM-DD string
  static String toLocalYYYYMMDD(DateTime date) {
    return _yyyyMMddFormat.format(date.toLocal());
  }

  /// Parses YYYY-MM-DD string into local DateTime
  static DateTime parseYYYYMMDD(String dateStr) {
    return _yyyyMMddFormat.parse(dateStr).toLocal();
  }

  /// Formats date to display style, e.g. "31 Dec 2026"
  static String formatDisplayDate(DateTime date) {
    return _yMMMdFormat.format(date);
  }

  /// Returns today's YYYY-MM-DD string representation
  static String getTodayString() {
    return toLocalYYYYMMDD(DateTime.now());
  }

  /// Checks if reset is needed based on last reset date string comparison
  static bool shouldRunReset(String? lastResetDateStr) {
    if (lastResetDateStr == null || lastResetDateStr.isEmpty) return true;
    final todayStr = getTodayString();
    return todayStr != lastResetDateStr;
  }

  /// Checks if two YYYY-MM-DD strings are consecutive days (nextDateStr is exactly 1 day after prevDateStr)
  static bool isConsecutive(String prevDateStr, String nextDateStr) {
    try {
      final prev = parseYYYYMMDD(prevDateStr);
      final next = parseYYYYMMDD(nextDateStr);
      return next.difference(prev).inDays == 1;
    } catch (_) {
      return false;
    }
  }

  /// Returns the difference in days between two YYYY-MM-DD strings
  static int getDaysDifference(String startDateStr, String endDateStr) {
    try {
      final start = parseYYYYMMDD(startDateStr);
      final end = parseYYYYMMDD(endDateStr);
      return end.difference(start).inDays;
    } catch (_) {
      return 0;
    }
  }

  /// Checks if the YYYY-MM-DD date string represents yesterday
  static bool isYesterday(String dateStr) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = toLocalYYYYMMDD(yesterday);
    return dateStr == yesterdayStr;
  }
}
