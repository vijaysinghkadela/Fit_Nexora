import 'package:equatable/equatable.dart';
import 'workout_plan_model.dart' show PlanStatus;

/// A nutrition/diet plan assigned to a client.
class DietPlan extends Equatable {
  final String id;
  final String gymId;
  final String? clientId;
  final String? trainerId;

  // Plan metadata
  final String name;
  final String? description;
  final String goal;

  // Targets
  final int targetCalories;
  final int targetProtein; // grams
  final int targetCarbs; // grams
  final int targetFat; // grams
  final double hydrationLiters;

  // Meals
  final List<Meal> meals;

  // Status
  final PlanStatus status;
  final bool isTemplate;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DietPlan({
    required this.id,
    required this.gymId,
    this.clientId,
    this.trainerId,
    required this.name,
    this.description,
    this.goal = 'general_fitness',
    this.targetCalories = 2000,
    this.targetProtein = 150,
    this.targetCarbs = 200,
    this.targetFat = 65,
    this.hydrationLiters = 3.0,
    this.meals = const [],
    this.status = PlanStatus.active,
    this.isTemplate = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total actual calories from all meals.
  int get actualCalories => meals.fold(0, (sum, m) => sum + m.totalCalories);

  /// Total actual protein from all meals.
  int get actualProtein => meals.fold(0, (sum, m) => sum + m.totalProtein);

  /// True when this plan was assigned by a trainer.
  bool get isTrainerAssigned => trainerId != null;

  /// True when the member created this plan themselves.
  bool get isSelfCreated => trainerId == null && !isTemplate;

  factory DietPlan.fromJson(Map<String, dynamic> json) {
    final mealsJson = json['meals'] as List<dynamic>? ?? [];
    return DietPlan(
      id: json['id'] as String,
      gymId: json['gym_id'] as String,
      clientId: json['client_id'] as String?,
      trainerId: json['trainer_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      goal: json['goal'] as String? ?? 'general_fitness',
      targetCalories: json['target_calories'] as int? ?? 2000,
      targetProtein: json['target_protein'] as int? ?? 150,
      targetCarbs: json['target_carbs'] as int? ?? 200,
      targetFat: json['target_fat'] as int? ?? 65,
      hydrationLiters: (json['hydration_liters'] as num?)?.toDouble() ?? 3.0,
      meals: mealsJson
          .map((m) => Meal.fromJson(m as Map<String, dynamic>))
          .toList(),
      status: PlanStatus.fromString(json['status'] as String? ?? 'active'),
      isTemplate: json['is_template'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'gym_id': gymId,
        'client_id': clientId,
        'trainer_id': trainerId,
        'name': name,
        'description': description,
        'goal': goal,
        'target_calories': targetCalories,
        'target_protein': targetProtein,
        'target_carbs': targetCarbs,
        'target_fat': targetFat,
        'hydration_liters': hydrationLiters,
        'meals': meals.map((m) => m.toJson()).toList(),
        'status': status.value,
        'is_template': isTemplate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, name, gymId];
}

/// A single meal within a diet plan.
class Meal {
  final String name; // e.g., "Pre-Workout Meal"
  final String timing; // e.g., "60 mins before training"
  final int orderIndex;
  final List<FoodItem> foods;
  final String? notes;

  const Meal({
    required this.name,
    this.timing = '',
    this.orderIndex = 0,
    this.foods = const [],
    this.notes,
  });

  /// Per-meal macro totals.
  int get totalProtein => foods.fold(0, (sum, f) => sum + f.protein);
  int get totalCarbs => foods.fold(0, (sum, f) => sum + f.carbs);
  int get totalFat => foods.fold(0, (sum, f) => sum + f.fat);
  int get totalCalories => foods.fold(0, (sum, f) => sum + f.calories);

  factory Meal.fromJson(Map<String, dynamic> json) {
    final foodsJson = json['foods'] as List<dynamic>? ?? [];
    return Meal(
      name: json['name'] as String,
      timing: json['timing'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
      foods: foodsJson
          .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'timing': timing,
        'order_index': orderIndex,
        'foods': foods.map((f) => f.toJson()).toList(),
        'notes': notes,
      };
}

/// A single food item within a meal.
class FoodItem {
  final String name;
  final String quantity; // e.g., "200g", "2 cups"
  final int protein; // grams
  final int carbs; // grams
  final int fat; // grams
  final int calories;
  final bool isIndian; // flag for Indian food database items

  const FoodItem({
    required this.name,
    this.quantity = '',
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.calories = 0,
    this.isIndian = false,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      quantity: json['quantity'] as String? ?? '',
      protein: json['protein'] as int? ?? 0,
      carbs: json['carbs'] as int? ?? 0,
      fat: json['fat'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
      isIndian: json['is_indian'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'calories': calories,
        'is_indian': isIndian,
      };
}
