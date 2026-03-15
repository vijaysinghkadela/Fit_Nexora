import '../core/database_values.dart';

/// Single food log entry stored in `food_logs`.
class FoodLog {
  final String id;
  final String userId;
  final String? gymId;
  final String? barcode;
  final String productName;
  final String? brand;
  final double caloriesKcal;
  final double proteinG;
  final double fatG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double sodiumMg;
  final double servingSizeG;
  final double quantity;
  final String mealType;
  final DateTime loggedAt;

  const FoodLog({
    required this.id,
    required this.userId,
    this.gymId,
    this.barcode,
    required this.productName,
    this.brand,
    required this.caloriesKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.sodiumMg,
    required this.servingSizeG,
    required this.quantity,
    required this.mealType,
    required this.loggedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> j) => FoodLog(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        gymId: j['gym_id'] as String?,
        barcode: j['barcode'] as String?,
        productName: j['product_name'] as String? ?? '',
        brand: j['brand'] as String?,
        caloriesKcal: (j['calories_kcal'] as num? ?? 0).toDouble(),
        proteinG: (j['protein_g'] as num? ?? 0).toDouble(),
        fatG: (j['fat_g'] as num? ?? 0).toDouble(),
        carbsG: (j['carbs_g'] as num? ?? 0).toDouble(),
        sugarG: (j['sugar_g'] as num? ?? 0).toDouble(),
        fiberG: (j['fiber_g'] as num? ?? 0).toDouble(),
        sodiumMg: (j['sodium_mg'] as num? ?? 0).toDouble(),
        servingSizeG: (j['serving_size_g'] as num? ?? 100).toDouble(),
        quantity: (j['quantity'] as num? ?? 1).toDouble(),
        mealType:
            j['meal_type'] as String? ?? DatabaseValues.defaultMealType,
        loggedAt: DateTime.tryParse(j['logged_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'gym_id': gymId,
        'barcode': barcode,
        'product_name': productName,
        'brand': brand,
        'calories_kcal': caloriesKcal,
        'protein_g': proteinG,
        'fat_g': fatG,
        'carbs_g': carbsG,
        'sugar_g': sugarG,
        'fiber_g': fiberG,
        'sodium_mg': sodiumMg,
        'serving_size_g': servingSizeG,
        'quantity': quantity,
        'meal_type': mealType,
      };
}

/// Aggregated nutrition for a set of food logs.
class NutritionSummary {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double sugar;
  final double fiber;
  final double sodium;
  final int count;
  final List<FoodLog> logs;

  const NutritionSummary({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.sugar,
    required this.fiber,
    required this.sodium,
    required this.count,
    required this.logs,
  });

  factory NutritionSummary.fromLogs(List<FoodLog> logs) => NutritionSummary(
        calories: logs.fold(0, (s, l) => s + l.caloriesKcal),
        protein: logs.fold(0, (s, l) => s + l.proteinG),
        fat: logs.fold(0, (s, l) => s + l.fatG),
        carbs: logs.fold(0, (s, l) => s + l.carbsG),
        sugar: logs.fold(0, (s, l) => s + l.sugarG),
        fiber: logs.fold(0, (s, l) => s + l.fiberG),
        sodium: logs.fold(0, (s, l) => s + l.sodiumMg),
        count: logs.length,
        logs: logs,
      );

  static const NutritionSummary empty = NutritionSummary(
    calories: 0,
    protein: 0,
    fat: 0,
    carbs: 0,
    sugar: 0,
    fiber: 0,
    sodium: 0,
    count: 0,
    logs: [],
  );
}

/// Recommended daily values used for high-level macro progress bars.
class DailyTargets {
  static const double calories = 2000;
  static const double protein = 50;
  static const double fat = 70;
  static const double carbs = 260;
  static const double sugar = 90;
  static const double fiber = 30;
  static const double sodiumMg = 2300;
}
