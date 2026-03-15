import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;
import 'exceptions.dart' hide AuthException;


/// Centralised error translation and display utilities.
///
/// Usage:
/// ```dart
/// try {
///   await db.doSomething();
/// } catch (e, st) {
///   final msg = ErrorHandler.message(e);
///   ErrorHandler.showSnackBar(context, msg);
///   ErrorHandler.log(e, st);
/// }
/// ```
class ErrorHandler {
  ErrorHandler._();

  // ─── Translation ────────────────────────────────────────────────────────────

  /// Converts any error into a user-friendly message string.
  static String message(Object error) {
    // Already friendly
    if (error is AppException) return error.message;

    // Supabase errors
    if (error is AuthException) {
      return _supabaseAuthMessage(error);
    }
    if (error is PostgrestException) {
      return _postgrestMessage(error);
    }

    // Dart / Flutter core errors
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. Contact your gym admin.';
    }

    return 'Something went wrong. Please try again.';
  }

  /// Maps a [PostgrestException] to a user-readable string.
  static String _postgrestMessage(PostgrestException e) {
    final code = e.code ?? '';
    final detail = e.details?.toString().toLowerCase() ?? '';
    final msg = e.message.toLowerCase();

    if (code == '23505' || detail.contains('unique') || msg.contains('duplicate')) {
      return 'A record with these details already exists.';
    }
    if (code == '23503' || detail.contains('foreign key')) {
      return 'Related record not found.';
    }
    if (code == '42501' || msg.contains('row-level') || msg.contains('permission')) {
      return 'You do not have permission to do this.';
    }
    if (msg.contains('not found') || code == 'PGRST116') {
      return 'Record not found.';
    }
    return 'Database error. Please try again.';
  }

  /// Maps a Supabase [AuthException] to a user-readable string.
  static String _supabaseAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (msg.contains('email already') || msg.contains('already registered')) {
      return 'This email is already registered.';
    }
    if (msg.contains('weak password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }
    return 'Authentication error. Please try again.';
  }

  // ─── Display ────────────────────────────────────────────────────────────────

  /// Show a red error SnackBar.
  static void showSnackBar(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;
    final msg = error is String ? error : message(error);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }

  /// Show a success (green-ish) SnackBar.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ─── Logging ────────────────────────────────────────────────────────────────

  /// Logs an error with optional stack trace.
  /// Replace the body with Sentry / Crashlytics when ready.
  static void log(Object error, [StackTrace? stackTrace]) {
    debugPrint('❌ [ErrorHandler] $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
