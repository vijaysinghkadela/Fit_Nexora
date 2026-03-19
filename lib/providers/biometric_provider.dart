import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/biometric_service.dart';

/// Singleton instance of [BiometricService].
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Whether biometric hardware is available on this device.
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricServiceProvider).isAvailable();
});

/// Whether the user can perform a biometric login right now
/// (device capable + credentials stored from a prior sign-in).
final canBiometricLoginProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricServiceProvider).canBiometricLogin();
});

/// Whether the user has opted-in to biometric login.
final biometricEnabledProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricServiceProvider).isEnabled();
});
