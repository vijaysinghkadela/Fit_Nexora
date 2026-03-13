import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// String extensions.
extension StringExtension on String {
  /// Capitalizes the first letter.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Title case: "hello world" → "Hello World".
  String get titleCase => split(' ').map((w) => w.capitalized).join(' ');

  /// Truncates string to max length with ellipsis.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}…';
}

/// DateTime extensions.
extension DateTimeExtension on DateTime {
  /// Formats as "Mar 4, 2026".
  String get formatted => DateFormat('MMM d, y').format(this);

  /// Formats as "04/03/2026".
  String get shortFormatted => DateFormat('dd/MM/yyyy').format(this);

  /// Returns relative time: "2 days ago", "in 5 hours".
  String get relative {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.isNegative) {
      final absDiff = difference(now);
      if (absDiff.inDays > 30) return 'in ${absDiff.inDays ~/ 30} months';
      if (absDiff.inDays > 0) return 'in ${absDiff.inDays} days';
      if (absDiff.inHours > 0) return 'in ${absDiff.inHours} hours';
      return 'in ${absDiff.inMinutes} minutes';
    }

    if (diff.inDays > 30) return '${diff.inDays ~/ 30} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'just now';
  }

  /// Whether this date is expired (before now).
  bool get isExpired => isBefore(DateTime.now());

  /// Days until this date. Negative if past.
  int get daysFromNow => difference(DateTime.now()).inDays;
}

/// Number extensions for currency formatting.
extension NumberExtension on num {
  /// Formats as Indian Rupees: "₹1,234".
  String get inr => '₹${NumberFormat('#,##,###').format(this)}';

  /// Formats with one decimal: "72.5 kg".
  String get withUnit => toStringAsFixed(1);
}

/// BuildContext extensions for quick access.
extension ContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isMobile => screenSize.width < 600;
  bool get isTablet => screenSize.width >= 600 && screenSize.width < 1200;
  bool get isDesktop => screenSize.width >= 1200;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
      ),
    );
  }
}
