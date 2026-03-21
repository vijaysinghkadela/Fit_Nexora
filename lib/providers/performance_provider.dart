import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLowPerformanceKey = 'low_performance_mode';

/// Represents the estimated capability tier of the current device.
///
/// Determined once at startup via [deviceTierProvider] and used throughout
/// the app to gate expensive visual effects.
///
/// - [low]     — budget Android devices (< 360 dp logical width or
///               explicitly set by the user via Settings).
/// - [mid]     — mainstream Android / older iPhones (360–400 dp).
/// - [premium] — flagship phones (> 400 dp logical width).
enum DeviceTier { low, mid, premium }

/// Estimates the device tier from the physical screen dimensions reported
/// by [PlatformDispatcher].
///
/// Using logical pixel width is a reliable proxy because OEMs ship budget
/// devices with small, low-density screens (< 360 dp) and flagship devices
/// with large, high-density displays (> 400 dp).
DeviceTier estimateDeviceTier() {
  try {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return DeviceTier.mid;

    final physicalWidth = view.physicalSize.width;
    final pixelRatio = view.devicePixelRatio;
    if (pixelRatio <= 0) return DeviceTier.mid;

    final logicalWidth = physicalWidth / pixelRatio;

    if (logicalWidth < 360) return DeviceTier.low;
    if (logicalWidth < 400) return DeviceTier.mid;
    return DeviceTier.premium;
  } catch (_) {
    return DeviceTier.mid;
  }
}

class PerformanceNotifier extends StateNotifier<bool> {
  PerformanceNotifier() : super(false) {
    Future.microtask(_loadSavedPerformanceMode);
  }

  Future<void> _loadSavedPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    final userHasSetManually = prefs.containsKey(_kLowPerformanceKey);

    if (userHasSetManually) {
      // Always respect what the user chose in Settings.
      state = prefs.getBool(_kLowPerformanceKey) ?? false;
    } else {
      // First launch: auto-detect and persist so the value is stable across
      // restarts (the user can still override it later in Settings).
      await _autoDetectAndPersist(prefs);
    }
  }

  /// Infers an appropriate initial performance mode from the estimated device
  /// tier and persists it to SharedPreferences.
  ///
  /// Called only once — on the very first launch before the user has touched
  /// the performance toggle in Settings.
  Future<void> _autoDetectAndPersist(SharedPreferences prefs) async {
    final tier = estimateDeviceTier();
    final enableLowPerfMode = tier == DeviceTier.low ||
        (tier == DeviceTier.mid &&
            defaultTargetPlatform == TargetPlatform.android);

    state = enableLowPerfMode;
    // Do NOT write to prefs here — we only write when the user explicitly
    // changes the toggle. This lets auto-detection re-run if the app is
    // reinstalled or the device's logical width changes (e.g. after an OS
    // font-scale change that affects the display).
    //
    // If you want the auto-detected value to survive reinstalls, uncomment:
    // await prefs.setBool(_kLowPerformanceKey, enableLowPerfMode);
  }

  Future<void> setLowPerformanceMode(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLowPerformanceKey, value);
  }

  Future<void> toggle() async {
    await setLowPerformanceMode(!state);
  }
}

/// Provider for managing if the app should run in low performance mode
/// (disabling blur, heavy shadows, etc.) to help low-end devices.
final performanceProvider = StateNotifierProvider<PerformanceNotifier, bool>(
  (ref) => PerformanceNotifier(),
);

/// Provides the estimated [DeviceTier] for the current device.
///
/// Computed once from screen dimensions. Widgets can read this to make
/// tier-specific decisions beyond the binary low/normal toggle — for
/// example, choosing animation complexity or chart resolution.
///
/// Usage:
/// ```dart
/// final tier = ref.watch(deviceTierProvider);
/// if (tier == DeviceTier.premium) { ... }
/// ```
final deviceTierProvider = Provider<DeviceTier>(
  (ref) => estimateDeviceTier(),
);
