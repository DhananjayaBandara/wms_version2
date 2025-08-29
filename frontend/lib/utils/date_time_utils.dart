import 'package:intl/intl.dart';

/// Utility functions to handle date and time formatting across the app.
///
/// The backend now exposes `formatted_date` and `formatted_time` fields on
/// session-related objects. These helpers will prefer those fields when
/// available and gracefully fall back to formatting the raw `date_time`
/// value to keep backward-compatibility.

String formatDateFromSession(Map session) {
  final formatted = session['formatted_date'];
  if (formatted is String && formatted.isNotEmpty) {
    return formatted;
  }
  final raw = session['date'];
  if (raw == null) return 'No Date';
  try {
    final dt = DateTime.parse(raw);
    // Same pattern as backend: Monday, 17 June 2025
    return DateFormat('EEEE, dd MMMM yyyy').format(dt);
  } catch (_) {
    return raw.toString();
  }
}

String formatTimeFromSession(Map session) {
  final formatted = session['formatted_time'];
  if (formatted is String && formatted.isNotEmpty) {
    return formatted;
  }
  final raw = session['time'];
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw);
    // Same pattern as backend: 11:55 AM
    return DateFormat('hh:mm a').format(dt);
  } catch (_) {
    return 'No Time';
  }
}

/// Format a raw ISO date-time string into a readable date (e.g. *Monday, 17 June 2025*).
String formatDateString(String? rawDateTime) {
  if (rawDateTime == null) return 'No Date';
  try {
    final dt = DateTime.parse(rawDateTime);
    return DateFormat('EEEE, dd MMMM yyyy').format(dt);
  } catch (_) {
    return rawDateTime;
  }
}

/// Format a raw ISO date-time string into a readable time (e.g. *11:55 AM*).
String formatTimeString(String? rawDateTime) {
  if (rawDateTime == null) return '';
  try {
    final dt = DateTime.parse(rawDateTime);
    return DateFormat('hh:mm').format(dt);
  } catch (_) {
    return '';
  }
}

/// Legacy helpers still referenced in some screens. These call the new
/// formatting utilities to avoid widespread refactors.
class Utils {
  /// Generic date formatter with custom pattern.
  static String formatDate(DateTime dt, String pattern) =>
      DateFormat(pattern).format(dt);

  /// Time formatter returning 12-hour clock (e.g., 11:55 AM).
  static String formatTime(DateTime dt) => DateFormat('hh:mm a').format(dt);
}
