import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kUnitSystemKey = 'app_unit_system';

enum UnitSystem { metric, imperial }

class UnitSystemNotifier extends StateNotifier<UnitSystem> {
  UnitSystemNotifier() : super(UnitSystem.metric) {
    _loadSavedUnitSystem();
  }

  Future<void> _loadSavedUnitSystem() async {
    final prefs = await SharedPreferences.getInstance();
    final rawSys = prefs.getString(_kUnitSystemKey);
    state = switch (rawSys) {
      'imperial' => UnitSystem.imperial,
      _ => UnitSystem.metric,
    };
  }

  Future<void> setUnitSystem(UnitSystem system) async {
    state = system;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnitSystemKey, system.name);
  }
}

final unitProvider = StateNotifierProvider<UnitSystemNotifier, UnitSystem>(
  (ref) => UnitSystemNotifier(),
);
