import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLowPerformanceKey = 'low_performance_mode';

class PerformanceNotifier extends StateNotifier<bool> {
  PerformanceNotifier() : super(false) {
    _loadSavedPerformanceMode();
  }

  Future<void> _loadSavedPerformanceMode() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kLowPerformanceKey) ?? false;
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
