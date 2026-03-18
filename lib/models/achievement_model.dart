// lib/models/achievement_model.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum AchievementCategory { fitness, nutrition, consistency, social, milestone }

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int xpReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0–1.0

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    required this.xpReward,
    required this.isUnlocked,
    this.unlockedAt,
    this.progress = 0.0,
  });

  Color get categoryColor {
    switch (category) {
      case AchievementCategory.fitness:
        return const Color(0xFF895AF6);
      case AchievementCategory.nutrition:
        return const Color(0xFF10D88A);
      case AchievementCategory.consistency:
        return const Color(0xFFF6B546);
      case AchievementCategory.social:
        return const Color(0xFF7A8BFF);
      case AchievementCategory.milestone:
        return const Color(0xFFFF6B7D);
    }
  }

  String get categoryLabel {
    switch (category) {
      case AchievementCategory.fitness:
        return 'Fitness';
      case AchievementCategory.nutrition:
        return 'Nutrition';
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.milestone:
        return 'Milestone';
    }
  }

  @override
  List<Object?> get props => [id, isUnlocked];
}

/// Static seed data — replace with Supabase calls once `achievements` table is live.
class AchievementData {
  static List<Achievement> get all => [
        const Achievement(
          id: 'first_workout',
          title: 'First Blood',
          description: 'Complete your very first workout',
          emoji: '🏋️',
          category: AchievementCategory.fitness,
          xpReward: 50,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'week_streak',
          title: '7-Day Warrior',
          description: 'Log workouts 7 days in a row',
          emoji: '🔥',
          category: AchievementCategory.consistency,
          xpReward: 200,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'hydration_hero',
          title: 'Hydration Hero',
          description: 'Hit your water goal 5 days in a row',
          emoji: '💧',
          category: AchievementCategory.nutrition,
          xpReward: 100,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'protein_king',
          title: 'Protein King',
          description: 'Hit your protein goal 7 days straight',
          emoji: '🥩',
          category: AchievementCategory.nutrition,
          xpReward: 150,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'bench_100',
          title: 'Century Club',
          description: 'Bench press 100 kg',
          emoji: '🏆',
          category: AchievementCategory.fitness,
          xpReward: 500,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'squat_1x_bw',
          title: 'Body Squat',
          description: 'Squat your own body weight',
          emoji: '🦵',
          category: AchievementCategory.fitness,
          xpReward: 300,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'step_master',
          title: 'Step Master',
          description: 'Hit 10,000 steps in a single day',
          emoji: '👟',
          category: AchievementCategory.fitness,
          xpReward: 100,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'month_streak',
          title: '30-Day Legend',
          description: 'Log activity every day for 30 days',
          emoji: '🌟',
          category: AchievementCategory.consistency,
          xpReward: 1000,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'nutrition_scan',
          title: 'Scan Artist',
          description: 'Scan 10 food barcodes',
          emoji: '📷',
          category: AchievementCategory.nutrition,
          xpReward: 75,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'sleep_champ',
          title: 'Sleep Champion',
          description: 'Log 8+ hours of sleep 5 nights running',
          emoji: '😴',
          category: AchievementCategory.milestone,
          xpReward: 150,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'perfect_week',
          title: 'Perfect Week',
          description: 'Complete all planned workouts in a week',
          emoji: '✅',
          category: AchievementCategory.consistency,
          xpReward: 250,
          isUnlocked: false,
        ),
        const Achievement(
          id: 'pr_setter',
          title: 'PR Machine',
          description: 'Set 5 personal records',
          emoji: '📈',
          category: AchievementCategory.fitness,
          xpReward: 200,
          isUnlocked: false,
        ),
      ];
}
