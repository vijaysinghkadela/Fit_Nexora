import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles biometric authentication and secure credential storage.
class BiometricService {
  static const _keyEmail = 'bio_email';
  static const _keyPassword = 'bio_password';
  static const _keyEnabled = 'bio_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  // ─── Device capability ────────────────────────────────────────────

  /// Returns `true` if the device has biometric hardware AND at least one
  /// biometric (fingerprint / face) is enrolled.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      debugPrint('BiometricService.isAvailable error: $e');
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, iris).
  Future<List<BiometricType>> enrolledBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('BiometricService.enrolledBiometrics error: $e');
      return [];
    }
  }

  // ─── Authentication ───────────────────────────────────────────────

  /// Triggers the OS biometric prompt. Returns `true` on success.
  Future<bool> authenticate({
    String reason = 'Scan your fingerprint to log in',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
      );
    } catch (e) {
      debugPrint('BiometricService.authenticate error: $e');
      return false;
    }
  }

  // ─── Credential storage ───────────────────────────────────────────

  /// Persist email + password so biometric login can replay them.
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyEnabled, true);
  }

  /// Retrieve stored credentials. Returns `null` if nothing saved.
  Future<({String email, String password})?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  /// Clear stored credentials (e.g. on sign-out).
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keyEnabled, false);
  }

  /// Whether the user has opted-in to biometric login.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  /// Returns `true` when biometric hardware is available AND the user has
  /// stored credentials from a previous sign-in.
  Future<bool> canBiometricLogin() async {
    final available = await isAvailable();
    if (!available) return false;
    final enabled = await isEnabled();
    if (!enabled) return false;
    final creds = await getCredentials();
    return creds != null;
  }
}
