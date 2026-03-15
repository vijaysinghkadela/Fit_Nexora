/// Custom exception types for FitNexora.
///
/// Throw these instead of generic [Exception] or raw [String]s so that
/// UI can distinguish error categories and show appropriate messages.
library;

// ─── Base ─────────────────────────────────────────────────────────────────────

/// Root exception class for all app-specific errors.
abstract class AppException implements Exception {
  const AppException(this.message, {this.originalError});

  /// Human-readable error description.
  final String message;

  /// The underlying error / stack trace (for logging).
  final Object? originalError;

  @override
  String toString() => '$runtimeType: $message';
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

/// Authentication or authorisation error.
class AuthException extends AppException {
  const AuthException(super.message, {super.originalError});
}

/// Thrown when the user is not logged in.
class NotAuthenticatedException extends AuthException {
  const NotAuthenticatedException()
      : super('You are not signed in. Please log in again.');
}

/// Thrown when a user tries to access a feature they are not allowed to.
class PermissionDeniedException extends AuthException {
  const PermissionDeniedException([String? action])
      : super(
          action != null
              ? 'You do not have permission to $action.'
              : 'Permission denied.',
        );
}

// ─── Subscription / Plan ──────────────────────────────────────────────────────

/// Thrown when the user's plan does not include the requested feature.
class PlanUpgradeRequiredException extends AppException {
  const PlanUpgradeRequiredException({
    required this.requiredPlan,
    String? featureName,
  }) : super(
          featureName != null
              ? '$featureName requires the $requiredPlan plan or higher.'
              : 'This feature requires the $requiredPlan plan or higher.',
        );

  /// The minimum plan name needed (e.g. "Pro", "Elite", "Master").
  final String requiredPlan;
}

// ─── Database ─────────────────────────────────────────────────────────────────

/// Generic database / Supabase error.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.originalError});
}

/// Thrown when a required record is not found.
class RecordNotFoundException extends DatabaseException {
  const RecordNotFoundException(String entity)
      : super('$entity not found.');
}

/// Thrown when inserting a duplicate record.
class DuplicateRecordException extends DatabaseException {
  const DuplicateRecordException(String entity)
      : super('A $entity with these details already exists.');
}

// ─── Network ──────────────────────────────────────────────────────────────────

/// Network or HTTP errors.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.originalError});
}

/// Thrown when a request times out.
class RequestTimeoutException extends NetworkException {
  const RequestTimeoutException()
      : super(
          'The request timed out. Please check your connection and try again.',
        );
}

/// Thrown when the server returns an unexpected status code.
class ServerException extends NetworkException {
  const ServerException(int statusCode)
      : super('Server error ($statusCode). Please try again later.');
}

// ─── Validation ───────────────────────────────────────────────────────────────

/// Thrown when user-provided data fails validation.
class ValidationException extends AppException {
  const ValidationException(super.message);

  /// Map of field → error message.
  factory ValidationException.fields(Map<String, String> fieldErrors) {
    final summary = fieldErrors.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    return ValidationException(summary);
  }
}
