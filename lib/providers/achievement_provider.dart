// lib/providers/achievement_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_model.dart';

const _kUnlockedKey = 'unlocked_achievements';
const _kXpKey = 'total_xp';

class AchievementNotifier extends StateNotifier<List<Achievement>> {
  AchievementNotifier() : super(AchievementData.all) {
    _loadUnlocked();
  }

  int _totalXp = 0;
  int get totalXp => _totalXp;

  Future<void> _loadUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kUnlockedKey) ?? [];
    _totalXp = prefs.getInt(_kXpKey) ?? 0;

    state = state.map((a) {
      if (ids.contains(a.id)) {
        return Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          emoji: a.emoji,
          category: a.category,
          xpReward: a.xpReward,
          isUnlocked: true,
          unlockedAt: DateTime.now(), // approximate
          progress: 1.0,
        );
      }
      return a;
    }).toList();
  }

  Future<void> unlock(String achievementId) async {
    final target = state.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => throw StateError('Achievement $achievementId not found'),
    );
    if (target.isUnlocked) return;

    state = state.map((a) {
      if (a.id == achievementId) {
        return Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          emoji: a.emoji,
          category: a.category,
          xpReward: a.xpReward,
          isUnlocked: true,
          unlockedAt: DateTime.now(),
          progress: 1.0,
        );
      }
      return a;
    }).toList();

    _totalXp += target.xpReward;

    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_kUnlockedKey) ?? [];
    if (!ids.contains(achievementId)) ids.add(achievementId);
    await prefs.setStringList(_kUnlockedKey, ids);
    await prefs.setInt(_kXpKey, _totalXp);
  }

  Future<void> updateProgress(String achievementId, double progress) async {
    state = state.map((a) {
      if (a.id == achievementId && !a.isUnlocked) {
        return Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          emoji: a.emoji,
          category: a.category,
          xpReward: a.xpReward,
          isUnlocked: false,
          progress: progress.clamp(0.0, 1.0),
        );
      }
      return a;
    }).toList();
  }

  List<Achievement> get unlocked =>
      state.where((a) => a.isUnlocked).toList();

  List<Achievement> get locked =>
      state.where((a) => !a.isUnlocked).toList();

  int get level => (_totalXp / 500).floor() + 1;
  double get levelProgress => (_totalXp % 500) / 500.0;
}

final achievementProvider =
    StateNotifierProvider<AchievementNotifier, List<Achievement>>(
  (ref) => AchievementNotifier(),
);

final totalXpProvider = Provider<int>((ref) {
  ref.watch(achievementProvider); // trigger rebuild
  return ref.read(achievementProvider.notifier).totalXp;
});

final levelProvider = Provider<int>((ref) {
  ref.watch(achievementProvider);
  return ref.read(achievementProvider.notifier).level;
});
