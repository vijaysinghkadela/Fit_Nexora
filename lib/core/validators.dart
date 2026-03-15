/// Form input validators for the FitNexora app.
///
/// All validators return null on success and a [String] error message on failure.
/// Compatible with Flutter's [FormField.validator] API.
class AppValidators {
  AppValidators._();

  // ─── Text ──────────────────────────────────────────────────────────────────

  /// Required field — must not be blank.
  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  /// Minimum length validator.
  static String? Function(String?) minLength(int min, {String label = 'This field'}) {
    return (value) {
      if (value == null || value.trim().length < min) {
        return '$label must be at least $min characters.';
      }
      return null;
    };
  }

  /// Maximum length validator.
  static String? Function(String?) maxLength(int max, {String label = 'This field'}) {
    return (value) {
      if (value != null && value.trim().length > max) {
        return '$label must not exceed $max characters.';
      }
      return null;
    };
  }

  // ─── Contact ───────────────────────────────────────────────────────────────

  /// Email format validator.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Password: minimum 8 chars, at least one letter and one digit.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain at least one letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one number.';
    }
    return null;
  }

  /// Indian / international phone number (7–15 digits, optional +).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(digits)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  // ─── Numeric / Fitness ─────────────────────────────────────────────────────

  /// Age between [min] and [max] (defaults: 10–120).
  static String? age(String? value, {int min = 10, int max = 120}) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = int.tryParse(value.trim());
    if (n == null) return 'Enter a valid age.';
    if (n < min || n > max) return 'Age must be between $min and $max.';
    return null;
  }

  /// Weight in kg (1–500 kg).
  static String? weightKg(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid weight.';
    if (n < 1 || n > 500) return 'Weight must be between 1 and 500 kg.';
    return null;
  }

  /// Height in cm (50–300 cm).
  static String? heightCm(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid height.';
    if (n < 50 || n > 300) return 'Height must be between 50 and 300 cm.';
    return null;
  }

  /// Body measurement in cm (1–300 cm). Used for waist, chest, etc.
  static String? measurementCm(String? value, {String label = 'Measurement'}) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid $label.';
    if (n < 1 || n > 300) return '$label must be between 1 and 300 cm.';
    return null;
  }

  /// Body fat percentage (1–70%).
  static String? bodyFatPercent(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final n = double.tryParse(value.trim());
    if (n == null) return 'Enter a valid body fat %.';
    if (n < 1 || n > 70) return 'Body fat must be between 1 and 70%.';
    return null;
  }

  // ─── Gym / Business ────────────────────────────────────────────────────────

  /// GST number (Indian format: 15 alphanumeric).
  static String? gstNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final gst = value.trim().toUpperCase();
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]\d[Z][A-Z\d]$').hasMatch(gst)) {
      return 'Enter a valid 15-character GST number.';
    }
    return null;
  }

  /// Confirms two password fields match.
  static String? Function(String?) confirmPassword(String password) {
    return (value) {
      if (value != password) return 'Passwords do not match.';
      return null;
    };
  }

  // ─── Combine ───────────────────────────────────────────────────────────────

  /// Combines multiple validators — returns first error found.
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
