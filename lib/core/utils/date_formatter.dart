// =============================================================================
// FILE: lib/core/utils/date_formatter.dart
// =============================================================================
// PURPOSE: Utility class for formatting dates in a user-friendly way
// WHY: Raw DateTime objects aren't user-friendly. This converts them
//      to strings like "Today", "Yesterday", "Dec 25, 2024"
// =============================================================================

import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Formats a DateTime as a relative or absolute date string
  ///
  /// Examples:
  ///   - Today → "Today"
  ///   - Yesterday → "Yesterday"
  ///   - Dec 25, 2024 → "Dec 25, 2024"
  ///
  /// HOW IT WORKS:
  /// 1. Compare the date to today
  /// 2. If same day → "Today"
  /// 3. If yesterday → "Yesterday"
  /// 4. Otherwise → formatted date
  ///
  static String formatDate(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  /// Formats DateTime with time included
  /// Example: "Today at 2:30 PM"
  static String formatDateWithTime(DateTime? date) {
    if (date == null) return '';

    final dateStr = formatDate(date);
    final timeStr = DateFormat('h:mm a').format(date);

    if (dateStr == 'Today' || dateStr == 'Yesterday') {
      return '$dateStr at $timeStr';
    }
    return '$dateStr at $timeStr';
  }

  /// Returns just the time portion
  /// Example: "2:30 PM"
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat('h:mm a').format(date);
  }

  /// Checks if a date is overdue (before today)
  static bool isOverdue(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    return dateOnly.isBefore(today);
  }
}
