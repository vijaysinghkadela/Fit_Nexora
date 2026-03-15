import 'package:flutter/material.dart';
import '../core/constants.dart';

enum NutrientLevel { excellent, good, ok, caution, high }

extension NutrientLevelX on NutrientLevel {
  Color get color => switch (this) {
        NutrientLevel.excellent => AppColors.accent,
        NutrientLevel.good => AppColors.success,
        NutrientLevel.ok => AppColors.textMuted,
        NutrientLevel.caution => AppColors.warning,
        NutrientLevel.high => AppColors.error,
      };

  String get label => switch (this) {
        NutrientLevel.excellent => 'EXCELLENT',
        NutrientLevel.good => 'GOOD',
        NutrientLevel.ok => 'OK',
        NutrientLevel.caution => 'MODERATE',
        NutrientLevel.high => 'HIGH',
      };

  IconData get icon => switch (this) {
        NutrientLevel.excellent => Icons.star_rounded,
        NutrientLevel.good => Icons.check_circle_rounded,
        NutrientLevel.ok => Icons.remove_circle_outline_rounded,
        NutrientLevel.caution => Icons.warning_rounded,
        NutrientLevel.high => Icons.dangerous_rounded,
      };
}

class NutrientAlert {
  final String name;
  final double per100g;
  final String unit;
  final NutrientLevel level;
  final String note;

  const NutrientAlert({
    required this.name,
    required this.per100g,
    required this.unit,
    required this.level,
    required this.note,
  });
}

class FoodProduct {
  final String barcode;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double saturatedFatPer100g;
  final double carbsPer100g;
  final double sugarPer100g;
  final double fiberPer100g;
  final double sodiumMgPer100g; // stored as mg
  final String? ingredientsText;
  final double defaultServingSizeG;
  final String? nutriscoreGrade;

  const FoodProduct({
    required this.barcode,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.saturatedFatPer100g,
    required this.carbsPer100g,
    required this.sugarPer100g,
    required this.fiberPer100g,
    required this.sodiumMgPer100g,
    this.ingredientsText,
    required this.defaultServingSizeG,
    this.nutriscoreGrade,
  });

  factory FoodProduct.fromOpenFoodFacts(
      String barcode, Map<String, dynamic> data) {
    final n = (data['nutriments'] as Map<String, dynamic>?) ?? {};

    double n100(String key) => (n[key] as num?)?.toDouble() ?? 0.0;

    // Prefer energy-kcal_100g; fall back to kJ ÷ 4.184
    final kcal = n['energy-kcal_100g'] != null
        ? n100('energy-kcal_100g')
        : n100('energy_100g') / 4.184;

    // Parse serving size from strings like "30g", "30 g", "1 biscuit (30g)"
    double servingG = 100.0;
    final sq = (data['serving_quantity'] as num?)?.toDouble();
    if (sq != null && sq > 0) {
      servingG = sq;
    } else {
      final raw = data['serving_size'] as String?;
      if (raw != null) {
        final m = RegExp(r'(\d+(?:\.\d+)?)\s*g', caseSensitive: false)
            .firstMatch(raw);
        if (m != null) servingG = double.tryParse(m.group(1)!) ?? 100.0;
      }
    }

    final rawName = (data['product_name'] as String?)?.trim() ?? '';

    return FoodProduct(
      barcode: barcode,
      name: rawName.isNotEmpty ? rawName : 'Unknown Product',
      brand: (data['brands'] as String?)?.split(',').first.trim(),
      caloriesPer100g: kcal,
      proteinPer100g: n100('proteins_100g'),
      fatPer100g: n100('fat_100g'),
      saturatedFatPer100g: n100('saturated-fat_100g'),
      carbsPer100g: n100('carbohydrates_100g'),
      sugarPer100g: n100('sugars_100g'),
      fiberPer100g: n100('fiber_100g'),
      sodiumMgPer100g: n100('sodium_100g') * 1000, // g → mg
      ingredientsText: data['ingredients_text'] as String?,
      defaultServingSizeG: servingG,
      nutriscoreGrade: (data['nutriscore_grade'] as String?)?.toUpperCase(),
    );
  }

  /// Nutrients for a given serving size and number of servings.
  Map<String, double> nutrientsForServing(double servingG, double qty) {
    final f = (servingG / 100.0) * qty;
    return {
      'calories': caloriesPer100g * f,
      'protein': proteinPer100g * f,
      'fat': fatPer100g * f,
      'saturated_fat': saturatedFatPer100g * f,
      'carbs': carbsPer100g * f,
      'sugar': sugarPer100g * f,
      'fiber': fiberPer100g * f,
      'sodium': sodiumMgPer100g * f,
    };
  }

  /// UK FSA traffic-light ingredient alerts (per 100 g).
  List<NutrientAlert> get alerts => [
        _neg('Sugar', sugarPer100g, 'g',
            low: 5,
            med: 22.5,
            lowNote: 'Low sugar — good choice',
            medNote: 'Moderate sugar — watch portion size',
            highNote: 'High sugar — limit consumption'),
        _neg('Total Fat', fatPer100g, 'g',
            low: 3,
            med: 17.5,
            lowNote: 'Low fat content',
            medNote: 'Moderate fat',
            highNote: 'High fat — may contribute to weight gain'),
        _neg('Saturated Fat', saturatedFatPer100g, 'g',
            low: 1.5,
            med: 5.0,
            lowNote: 'Low in saturated fats',
            medNote: 'Moderate saturated fat',
            highNote: 'High saturated fat — raises LDL cholesterol'),
        _neg('Sodium', sodiumMgPer100g, 'mg',
            low: 300,
            med: 600,
            lowNote: 'Low sodium',
            medNote: 'Moderate sodium',
            highNote: 'High sodium — may raise blood pressure'),
        _pos('Protein', proteinPer100g, 'g',
            good: 10,
            excellent: 20,
            lowNote: 'Low protein',
            goodNote: 'Good protein source',
            excellentNote: 'Excellent protein — great for muscle recovery'),
        _pos('Fiber', fiberPer100g, 'g',
            good: 3,
            excellent: 6,
            lowNote: 'Low fiber',
            goodNote: 'Good fiber content',
            excellentNote: 'High fiber — great for digestion'),
      ];

  NutrientAlert _neg(
    String name,
    double val,
    String unit, {
    required double low,
    required double med,
    required String lowNote,
    required String medNote,
    required String highNote,
  }) {
    final level = val <= low
        ? NutrientLevel.good
        : val <= med
            ? NutrientLevel.caution
            : NutrientLevel.high;
    final note = val <= low ? lowNote : val <= med ? medNote : highNote;
    return NutrientAlert(
        name: name, per100g: val, unit: unit, level: level, note: note);
  }

  NutrientAlert _pos(
    String name,
    double val,
    String unit, {
    required double good,
    required double excellent,
    required String lowNote,
    required String goodNote,
    required String excellentNote,
  }) {
    final level = val >= excellent
        ? NutrientLevel.excellent
        : val >= good
            ? NutrientLevel.good
            : NutrientLevel.ok;
    final note =
        val >= excellent ? excellentNote : val >= good ? goodNote : lowNote;
    return NutrientAlert(
        name: name, per100g: val, unit: unit, level: level, note: note);
  }
}
