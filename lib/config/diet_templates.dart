import '../models/diet_plan_model.dart';
import '../models/workout_plan_model.dart' show PlanStatus;

// ---------------------------------------------------------------------------
// Shared sentinel date
// ---------------------------------------------------------------------------

final _kTemplateDate = DateTime(2024, 1, 1);

// ===========================================================================
// 1 — Lean Bulk  (3 000 kcal / P220 C350 F80)
// ===========================================================================

final _leanBulkMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:00 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Rolled Oats', quantity: '100g',
          protein: 13, carbs: 68, fat: 7, calories: 389),
      FoodItem(name: 'Whole Eggs', quantity: '3 large',
          protein: 18, carbs: 1, fat: 15, calories: 210),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 105),
      FoodItem(name: 'Whole Milk', quantity: '200 ml',
          protein: 7, carbs: 10, fat: 7, calories: 130),
    ],
  ),
  const Meal(
    name: 'Pre-Workout',
    timing: '60 min before training',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Banana', quantity: '1 large',
          protein: 1, carbs: 31, fat: 0, calories: 121),
      FoodItem(name: 'Whey Protein', quantity: '1 scoop (30 g)',
          protein: 25, carbs: 3, fat: 1, calories: 120),
      FoodItem(name: 'Rice Cakes', quantity: '3 pieces',
          protein: 2, carbs: 21, fat: 1, calories: 105),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '200g',
          protein: 60, carbs: 0, fat: 4, calories: 330),
      FoodItem(name: 'White Rice (cooked)', quantity: '200g',
          protein: 4, carbs: 52, fat: 0, calories: 260),
      FoodItem(name: 'Mixed Vegetables', quantity: '150g',
          protein: 3, carbs: 10, fat: 1, calories: 58),
      FoodItem(name: 'Olive Oil', quantity: '1 tbsp',
          protein: 0, carbs: 0, fat: 14, calories: 120),
    ],
  ),
  const Meal(
    name: 'Post-Workout',
    timing: 'Within 30 min of training',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Whey Protein', quantity: '1 scoop (30 g)',
          protein: 25, carbs: 3, fat: 1, calories: 120),
      FoodItem(name: 'Mixed Fruit', quantity: '150g',
          protein: 1, carbs: 25, fat: 0, calories: 95),
      FoodItem(name: 'Low-fat Yogurt', quantity: '200g',
          protein: 12, carbs: 18, fat: 2, calories: 138),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Salmon Fillet', quantity: '180g',
          protein: 38, carbs: 0, fat: 18, calories: 330),
      FoodItem(name: 'Sweet Potato', quantity: '200g',
          protein: 3, carbs: 41, fat: 0, calories: 172),
      FoodItem(name: 'Mixed Salad', quantity: '100g',
          protein: 2, carbs: 5, fat: 1, calories: 35),
      FoodItem(name: 'Olive Oil Dressing', quantity: '1 tbsp',
          protein: 0, carbs: 0, fat: 14, calories: 120),
    ],
  ),
];

// ===========================================================================
// 2 — Aggressive Cut  (1 800 kcal / P210 C120 F55)
// ===========================================================================

final _cutMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:00 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Whole Eggs', quantity: '3 large',
          protein: 18, carbs: 1, fat: 15, calories: 210),
      FoodItem(name: 'Egg Whites', quantity: '3',
          protein: 11, carbs: 0, fat: 0, calories: 51),
      FoodItem(name: 'Spinach', quantity: '100g',
          protein: 3, carbs: 4, fat: 0, calories: 23),
      FoodItem(name: 'Black Coffee', quantity: '240 ml',
          protein: 0, carbs: 0, fat: 0, calories: 5),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '12:00 PM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Canned Tuna (in water)', quantity: '185g',
          protein: 44, carbs: 0, fat: 2, calories: 190),
      FoodItem(name: 'Mixed Salad Greens', quantity: '150g',
          protein: 2, carbs: 5, fat: 1, calories: 35),
      FoodItem(name: 'Cherry Tomatoes', quantity: '100g',
          protein: 1, carbs: 7, fat: 0, calories: 35),
      FoodItem(name: 'Balsamic Vinegar', quantity: '1 tbsp',
          protein: 0, carbs: 3, fat: 0, calories: 14),
    ],
  ),
  const Meal(
    name: 'Afternoon Snack',
    timing: '3:30 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Greek Yogurt (0% fat)', quantity: '200g',
          protein: 20, carbs: 8, fat: 0, calories: 110),
      FoodItem(name: 'Blueberries', quantity: '80g',
          protein: 1, carbs: 14, fat: 0, calories: 46),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:00 PM',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '220g',
          protein: 66, carbs: 0, fat: 5, calories: 363),
      FoodItem(name: 'Broccoli', quantity: '200g',
          protein: 5, carbs: 14, fat: 1, calories: 70),
      FoodItem(name: 'Cauliflower Rice', quantity: '150g',
          protein: 2, carbs: 8, fat: 0, calories: 38),
      FoodItem(name: 'Lemon Juice', quantity: '1 tbsp',
          protein: 0, carbs: 1, fat: 0, calories: 4),
    ],
  ),
];

// ===========================================================================
// 3 — Maintenance  (2 300 kcal / P175 C260 F70)
// ===========================================================================

final _maintenanceMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:30 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Whole Grain Toast', quantity: '2 slices',
          protein: 8, carbs: 38, fat: 3, calories: 210),
      FoodItem(name: 'Peanut Butter', quantity: '2 tbsp',
          protein: 8, carbs: 6, fat: 16, calories: 190),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 105),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Turkey Breast', quantity: '150g',
          protein: 45, carbs: 0, fat: 3, calories: 200),
      FoodItem(name: 'Whole Grain Wrap', quantity: '1 large',
          protein: 7, carbs: 42, fat: 3, calories: 220),
      FoodItem(name: 'Avocado', quantity: '60g',
          protein: 1, carbs: 4, fat: 9, calories: 96),
      FoodItem(name: 'Lettuce + Tomato', quantity: '80g',
          protein: 1, carbs: 5, fat: 0, calories: 25),
    ],
  ),
  const Meal(
    name: 'Snack',
    timing: '4:00 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Cottage Cheese', quantity: '150g',
          protein: 18, carbs: 5, fat: 5, calories: 136),
      FoodItem(name: 'Apple', quantity: '1 medium',
          protein: 0, carbs: 25, fat: 0, calories: 95),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Lean Beef Mince', quantity: '150g',
          protein: 37, carbs: 0, fat: 13, calories: 263),
      FoodItem(name: 'Brown Rice (cooked)', quantity: '150g',
          protein: 3, carbs: 39, fat: 1, calories: 174),
      FoodItem(name: 'Mixed Stir-fry Vegetables', quantity: '150g',
          protein: 3, carbs: 10, fat: 1, calories: 58),
    ],
  ),
];

// ===========================================================================
// 4 — Ketogenic  (2 200 kcal / P180 C30 F165)
// ===========================================================================

final _ketoMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '8:00 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Whole Eggs', quantity: '4 large',
          protein: 24, carbs: 1, fat: 20, calories: 280),
      FoodItem(name: 'Avocado', quantity: '1 medium (150g)',
          protein: 2, carbs: 9, fat: 21, calories: 240),
      FoodItem(name: 'Streaky Bacon', quantity: '60g',
          protein: 10, carbs: 0, fat: 18, calories: 200),
      FoodItem(name: 'Butter', quantity: '1 tsp',
          protein: 0, carbs: 0, fat: 4, calories: 36),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Fatty Fish (Mackerel)', quantity: '180g',
          protein: 36, carbs: 0, fat: 24, calories: 368),
      FoodItem(name: 'Spinach Salad', quantity: '100g',
          protein: 3, carbs: 4, fat: 1, calories: 23),
      FoodItem(name: 'MCT Oil', quantity: '1 tbsp',
          protein: 0, carbs: 0, fat: 14, calories: 122),
      FoodItem(name: 'Mixed Nuts', quantity: '30g',
          protein: 5, carbs: 4, fat: 17, calories: 186),
    ],
  ),
  const Meal(
    name: 'Snack',
    timing: '4:30 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Brie Cheese', quantity: '60g',
          protein: 11, carbs: 0, fat: 14, calories: 172),
      FoodItem(name: 'Celery Sticks', quantity: '80g',
          protein: 1, carbs: 3, fat: 0, calories: 13),
      FoodItem(name: 'Almond Butter', quantity: '1 tbsp',
          protein: 3, carbs: 3, fat: 9, calories: 98),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Ribeye Steak', quantity: '200g',
          protein: 51, carbs: 0, fat: 38, calories: 544),
      FoodItem(name: 'Asparagus (roasted)', quantity: '150g',
          protein: 4, carbs: 8, fat: 5, calories: 93),
      FoodItem(name: 'Butter', quantity: '1 tbsp',
          protein: 0, carbs: 0, fat: 11, calories: 102),
    ],
  ),
];

// ===========================================================================
// 5 — High Protein Recomp  (2 600 kcal / P250 C250 F65)
// ===========================================================================

final _recompMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:00 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Egg Whites', quantity: '6',
          protein: 22, carbs: 1, fat: 0, calories: 102),
      FoodItem(name: 'Whole Eggs', quantity: '2',
          protein: 12, carbs: 1, fat: 10, calories: 140),
      FoodItem(name: 'Oats', quantity: '80g',
          protein: 10, carbs: 54, fat: 6, calories: 311),
      FoodItem(name: 'Berries', quantity: '100g',
          protein: 1, carbs: 14, fat: 0, calories: 57),
    ],
  ),
  const Meal(
    name: 'Mid-Morning',
    timing: '10:30 AM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Greek Yogurt (0% fat)', quantity: '250g',
          protein: 25, carbs: 10, fat: 0, calories: 138),
      FoodItem(name: 'Whey Protein', quantity: '1 scoop',
          protein: 25, carbs: 3, fat: 1, calories: 120),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '200g',
          protein: 60, carbs: 0, fat: 4, calories: 330),
      FoodItem(name: 'Quinoa (cooked)', quantity: '150g',
          protein: 6, carbs: 34, fat: 3, calories: 185),
      FoodItem(name: 'Roasted Vegetables', quantity: '200g',
          protein: 4, carbs: 18, fat: 4, calories: 122),
    ],
  ),
  const Meal(
    name: 'Post-Workout',
    timing: 'Within 30 min of training',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Whey Protein', quantity: '1 scoop',
          protein: 25, carbs: 3, fat: 1, calories: 120),
      FoodItem(name: 'White Rice (cooked)', quantity: '150g',
          protein: 3, carbs: 39, fat: 0, calories: 195),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Lean Turkey Mince', quantity: '200g',
          protein: 48, carbs: 0, fat: 8, calories: 260),
      FoodItem(name: 'Sweet Potato', quantity: '150g',
          protein: 2, carbs: 31, fat: 0, calories: 129),
      FoodItem(name: 'Steamed Broccoli', quantity: '150g',
          protein: 4, carbs: 11, fat: 1, calories: 53),
    ],
  ),
];

// ===========================================================================
// 6 — Vegetarian Bulk  (2 900 kcal / P170 C370 F75)
// ===========================================================================

final _vegBulkMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:30 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Paneer', quantity: '100g',
          protein: 18, carbs: 4, fat: 20, calories: 265, isIndian: true),
      FoodItem(name: 'Whole Grain Toast', quantity: '2 slices',
          protein: 8, carbs: 38, fat: 3, calories: 210),
      FoodItem(name: 'Whole Milk', quantity: '300 ml',
          protein: 10, carbs: 14, fat: 10, calories: 186),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 105),
    ],
  ),
  const Meal(
    name: 'Mid-Morning',
    timing: '10:30 AM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Greek Yogurt', quantity: '200g',
          protein: 18, carbs: 8, fat: 5, calories: 148),
      FoodItem(name: 'Mixed Nuts and Seeds', quantity: '40g',
          protein: 7, carbs: 8, fat: 22, calories: 250),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 2,
    notes: 'Dal and rice is a complete amino acid protein pair.',
    foods: [
      FoodItem(name: 'Masoor Dal (cooked)', quantity: '200g',
          protein: 18, carbs: 36, fat: 1, calories: 226, isIndian: true),
      FoodItem(name: 'Brown Rice (cooked)', quantity: '200g',
          protein: 4, carbs: 52, fat: 2, calories: 232),
      FoodItem(name: 'Sabzi / Mixed Veg Curry', quantity: '150g',
          protein: 4, carbs: 15, fat: 8, calories: 144, isIndian: true),
      FoodItem(name: 'Roti', quantity: '2 medium',
          protein: 6, carbs: 40, fat: 3, calories: 211, isIndian: true),
    ],
  ),
  const Meal(
    name: 'Pre-Workout Snack',
    timing: '4:00 PM',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Tofu', quantity: '150g',
          protein: 18, carbs: 3, fat: 9, calories: 177),
      FoodItem(name: 'Quinoa (cooked)', quantity: '100g',
          protein: 4, carbs: 23, fat: 2, calories: 120),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Rajma (kidney beans, cooked)', quantity: '200g',
          protein: 16, carbs: 44, fat: 1, calories: 254, isIndian: true),
      FoodItem(name: 'Steamed Rice', quantity: '150g',
          protein: 3, carbs: 39, fat: 0, calories: 195),
      FoodItem(name: 'Paneer Bhurji', quantity: '100g',
          protein: 14, carbs: 5, fat: 16, calories: 215, isIndian: true),
    ],
  ),
];

// ===========================================================================
// 7 — Vegan Performance  (2 700 kcal / P155 C400 F60)
// ===========================================================================

final _veganPerfMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '7:00 AM',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Oats', quantity: '100g',
          protein: 13, carbs: 68, fat: 7, calories: 389),
      FoodItem(name: 'Soy Milk', quantity: '250 ml',
          protein: 9, carbs: 8, fat: 4, calories: 105),
      FoodItem(name: 'Hemp Seeds', quantity: '30g',
          protein: 10, carbs: 3, fat: 15, calories: 180),
      FoodItem(name: 'Blueberries', quantity: '100g',
          protein: 1, carbs: 14, fat: 0, calories: 57),
    ],
  ),
  const Meal(
    name: 'Mid-Morning',
    timing: '10:00 AM',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Vegan Protein Shake', quantity: '1 scoop (30g)',
          protein: 22, carbs: 5, fat: 2, calories: 125),
      FoodItem(name: 'Banana', quantity: '1 large',
          protein: 1, carbs: 31, fat: 0, calories: 121),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '1:00 PM',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Tempeh', quantity: '150g',
          protein: 30, carbs: 9, fat: 9, calories: 240),
      FoodItem(name: 'Brown Rice (cooked)', quantity: '200g',
          protein: 4, carbs: 52, fat: 2, calories: 232),
      FoodItem(name: 'Roasted Vegetables', quantity: '200g',
          protein: 4, carbs: 18, fat: 4, calories: 122),
      FoodItem(name: 'Tahini Dressing', quantity: '1 tbsp',
          protein: 1, carbs: 2, fat: 8, calories: 89),
    ],
  ),
  const Meal(
    name: 'Pre-Workout',
    timing: '60 min before training',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Chickpeas (cooked)', quantity: '150g',
          protein: 11, carbs: 36, fat: 3, calories: 219),
      FoodItem(name: 'Dates', quantity: '50g',
          protein: 1, carbs: 36, fat: 0, calories: 141),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '7:30 PM',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Chickpea Curry (homemade)', quantity: '250g',
          protein: 15, carbs: 45, fat: 8, calories: 312),
      FoodItem(name: 'Brown Rice (cooked)', quantity: '150g',
          protein: 3, carbs: 39, fat: 1, calories: 174),
      FoodItem(name: 'Mixed Green Salad', quantity: '100g',
          protein: 2, carbs: 5, fat: 1, calories: 37),
    ],
  ),
];

// ===========================================================================
// 8 — Bodybuilding Hypertrophy  (3 200 kcal / P280 C320 F85)
// ===========================================================================

final _bodybuildingMeals = [
  const Meal(
    name: 'Early Morning',
    timing: '06:00',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Whey Protein Shake', quantity: '1 scoop',
          protein: 30, carbs: 5, fat: 2, calories: 158),
      FoodItem(name: 'Oats with Honey', quantity: '100g oats + 1 tbsp honey',
          protein: 8, carbs: 55, fat: 5, calories: 297),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 112),
    ],
  ),
  const Meal(
    name: 'Pre-Workout',
    timing: '09:00',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '200g',
          protein: 46, carbs: 0, fat: 5, calories: 229),
      FoodItem(name: 'Brown Rice', quantity: '1 cup cooked',
          protein: 5, carbs: 45, fat: 2, calories: 218),
      FoodItem(name: 'Broccoli', quantity: '100g',
          protein: 3, carbs: 11, fat: 0, calories: 55),
    ],
  ),
  const Meal(
    name: 'Intra/Post Workout',
    timing: '12:00',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Whey Isolate Shake', quantity: '1 scoop',
          protein: 35, carbs: 3, fat: 1, calories: 161),
      FoodItem(name: 'White Rice', quantity: '1.5 cups cooked',
          protein: 6, carbs: 67, fat: 1, calories: 303),
    ],
  ),
  const Meal(
    name: 'Afternoon Meal',
    timing: '15:00',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Salmon', quantity: '150g',
          protein: 34, carbs: 0, fat: 13, calories: 259),
      FoodItem(name: 'Sweet Potato', quantity: '1 medium',
          protein: 2, carbs: 24, fat: 0, calories: 103),
      FoodItem(name: 'Salad', quantity: '100g mixed greens',
          protein: 2, carbs: 8, fat: 0, calories: 40),
    ],
  ),
  const Meal(
    name: 'Night Meal',
    timing: '20:00',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Cottage Cheese', quantity: '200g',
          protein: 28, carbs: 6, fat: 4, calories: 172),
      FoodItem(name: 'Casein Shake', quantity: '1 scoop',
          protein: 24, carbs: 4, fat: 1, calories: 121),
      FoodItem(name: 'Mixed Nuts', quantity: '30g',
          protein: 5, carbs: 6, fat: 15, calories: 173),
    ],
  ),
];

// ===========================================================================
// 9 — Powerlifting Strength Fuel  (3 500 kcal / P260 C400 F95)
// ===========================================================================

final _powerliftingMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '07:00',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Whole Eggs', quantity: '4 large',
          protein: 28, carbs: 2, fat: 20, calories: 312),
      FoodItem(name: 'Whole Wheat Toast', quantity: '3 slices',
          protein: 9, carbs: 42, fat: 3, calories: 231),
      FoodItem(name: 'Orange Juice', quantity: '250ml',
          protein: 2, carbs: 26, fat: 0, calories: 112),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 112),
    ],
  ),
  const Meal(
    name: 'Mid Morning',
    timing: '10:00',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Greek Yogurt', quantity: '250g',
          protein: 18, carbs: 12, fat: 5, calories: 165),
      FoodItem(name: 'Granola', quantity: '60g',
          protein: 5, carbs: 40, fat: 6, calories: 234),
      FoodItem(name: 'Blueberries', quantity: '100g',
          protein: 1, carbs: 21, fat: 0, calories: 84),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '13:00',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Ground Beef (lean)', quantity: '200g',
          protein: 42, carbs: 0, fat: 18, calories: 322),
      FoodItem(name: 'White Rice', quantity: '1.5 cups cooked',
          protein: 6, carbs: 67, fat: 1, calories: 303),
      FoodItem(name: 'Corn', quantity: '100g',
          protein: 3, carbs: 19, fat: 1, calories: 96),
    ],
  ),
  const Meal(
    name: 'Pre-Workout',
    timing: '16:00',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Turkey Sandwich', quantity: '1 large',
          protein: 35, carbs: 50, fat: 8, calories: 412),
      FoodItem(name: 'Apple', quantity: '1 medium',
          protein: 0, carbs: 25, fat: 0, calories: 95),
      FoodItem(name: 'Peanut Butter', quantity: '2 tbsp',
          protein: 7, carbs: 7, fat: 16, calories: 190),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '20:00',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Beef Steak', quantity: '250g',
          protein: 56, carbs: 0, fat: 20, calories: 412),
      FoodItem(name: 'Mashed Potato', quantity: '1 large serving',
          protein: 7, carbs: 63, fat: 10, calories: 365),
      FoodItem(name: 'Olive Oil Veggies', quantity: '150g',
          protein: 2, carbs: 10, fat: 7, calories: 110),
    ],
  ),
];

// ===========================================================================
// 10 — Arm Wrestling Power Plan  (2 800 kcal / P230 C290 F75)
// ===========================================================================

final _armWrestlingMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '07:00',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Egg White Omelette', quantity: '8 whites',
          protein: 28, carbs: 2, fat: 0, calories: 120),
      FoodItem(name: 'Whole Egg', quantity: '2 large',
          protein: 12, carbs: 1, fat: 10, calories: 143),
      FoodItem(name: 'Multigrain Toast', quantity: '2 slices',
          protein: 6, carbs: 28, fat: 2, calories: 154),
      FoodItem(name: 'Avocado', quantity: 'half',
          protein: 2, carbs: 9, fat: 12, calories: 160),
    ],
  ),
  const Meal(
    name: 'Mid Morning',
    timing: '10:00',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '150g',
          protein: 35, carbs: 0, fat: 4, calories: 180),
      FoodItem(name: 'Cottage Cheese', quantity: '100g',
          protein: 11, carbs: 3, fat: 2, calories: 72),
      FoodItem(name: 'Apple', quantity: '1 medium',
          protein: 0, carbs: 25, fat: 0, calories: 95),
    ],
  ),
  const Meal(
    name: 'Lunch',
    timing: '13:00',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Tuna', quantity: '200g',
          protein: 44, carbs: 0, fat: 2, calories: 194),
      FoodItem(name: 'Brown Rice', quantity: '1 cup cooked',
          protein: 5, carbs: 45, fat: 2, calories: 218),
      FoodItem(name: 'Chickpea Salad', quantity: '150g',
          protein: 8, carbs: 30, fat: 3, calories: 175, isIndian: true),
    ],
  ),
  const Meal(
    name: 'Afternoon',
    timing: '16:30',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Paneer', quantity: '100g',
          protein: 18, carbs: 3, fat: 14, calories: 265, isIndian: true),
      FoodItem(name: 'Daal', quantity: '1 cup cooked',
          protein: 10, carbs: 30, fat: 2, calories: 178, isIndian: true),
      FoodItem(name: 'Roti', quantity: '2 medium',
          protein: 5, carbs: 30, fat: 2, calories: 158, isIndian: true),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '20:00',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Salmon', quantity: '180g',
          protein: 40, carbs: 0, fat: 14, calories: 294),
      FoodItem(name: 'Quinoa', quantity: '1 cup cooked',
          protein: 8, carbs: 39, fat: 4, calories: 222),
      FoodItem(name: 'Steamed Veggies', quantity: '150g',
          protein: 3, carbs: 15, fat: 0, calories: 72),
    ],
  ),
];

// ===========================================================================
// 11 — Olympic Weightlifting Performance  (3 000 kcal / P220 C360 F78)
// ===========================================================================

final _weightliftingMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '06:30',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Oats', quantity: '100g',
          protein: 13, carbs: 68, fat: 6, calories: 375),
      FoodItem(name: 'Whey Protein', quantity: '30g scoop',
          protein: 24, carbs: 3, fat: 1, calories: 117),
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 112),
      FoodItem(name: 'Honey', quantity: '1 tbsp',
          protein: 0, carbs: 17, fat: 0, calories: 64),
    ],
  ),
  const Meal(
    name: 'Pre-Workout',
    timing: '09:30',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Rice Cakes', quantity: '4 pieces',
          protein: 2, carbs: 28, fat: 0, calories: 120),
      FoodItem(name: 'Peanut Butter', quantity: '2 tbsp',
          protein: 7, carbs: 7, fat: 16, calories: 190),
      FoodItem(name: 'Whey Shake', quantity: '1 scoop',
          protein: 24, carbs: 3, fat: 1, calories: 117),
    ],
  ),
  const Meal(
    name: 'Post-Workout Lunch',
    timing: '13:00',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Chicken Breast', quantity: '200g',
          protein: 46, carbs: 0, fat: 5, calories: 229),
      FoodItem(name: 'White Rice', quantity: '2 cups cooked',
          protein: 8, carbs: 90, fat: 1, calories: 404),
      FoodItem(name: 'Sweet Corn', quantity: '100g',
          protein: 3, carbs: 19, fat: 1, calories: 96),
    ],
  ),
  const Meal(
    name: 'Afternoon',
    timing: '16:00',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Greek Yogurt', quantity: '200g',
          protein: 14, carbs: 10, fat: 4, calories: 132),
      FoodItem(name: 'Dates', quantity: '5 pieces',
          protein: 1, carbs: 36, fat: 0, calories: 140),
      FoodItem(name: 'Almonds', quantity: '25g',
          protein: 5, carbs: 5, fat: 13, calories: 153),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '20:00',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Turkey Breast', quantity: '200g',
          protein: 44, carbs: 0, fat: 4, calories: 212),
      FoodItem(name: 'Pasta', quantity: '1.5 cups cooked',
          protein: 9, carbs: 65, fat: 2, calories: 318),
      FoodItem(name: 'Tomato Sauce', quantity: '100g',
          protein: 2, carbs: 15, fat: 3, calories: 95),
    ],
  ),
];

// ===========================================================================
// 12 — CrossFit Metabolic Fuel  (2 900 kcal / P210 C330 F80)
// ===========================================================================

final _crossfitMeals = [
  const Meal(
    name: 'Breakfast',
    timing: '06:00',
    orderIndex: 0,
    foods: [
      FoodItem(name: 'Egg Omelette', quantity: '3 eggs',
          protein: 18, carbs: 2, fat: 15, calories: 215),
      FoodItem(name: 'Whole Wheat Toast', quantity: '2 slices',
          protein: 6, carbs: 28, fat: 2, calories: 154),
      FoodItem(name: 'Spinach', quantity: '100g',
          protein: 2, carbs: 4, fat: 0, calories: 23),
      FoodItem(name: 'Orange', quantity: '1 medium',
          protein: 1, carbs: 15, fat: 0, calories: 62),
    ],
  ),
  const Meal(
    name: 'Pre-WOD',
    timing: '09:00',
    orderIndex: 1,
    foods: [
      FoodItem(name: 'Banana', quantity: '1 medium',
          protein: 1, carbs: 27, fat: 0, calories: 112),
      FoodItem(name: 'Whey Shake', quantity: '1 scoop',
          protein: 24, carbs: 3, fat: 1, calories: 117),
      FoodItem(name: 'Rice Cakes', quantity: '3 pieces',
          protein: 2, carbs: 21, fat: 0, calories: 90),
    ],
  ),
  const Meal(
    name: 'Post-WOD Lunch',
    timing: '12:00',
    orderIndex: 2,
    foods: [
      FoodItem(name: 'Grilled Chicken', quantity: '200g',
          protein: 46, carbs: 0, fat: 5, calories: 229),
      FoodItem(name: 'Sweet Potato', quantity: '1 large',
          protein: 4, carbs: 37, fat: 0, calories: 164),
      FoodItem(name: 'Mixed Salad', quantity: '100g',
          protein: 2, carbs: 10, fat: 1, calories: 57),
    ],
  ),
  const Meal(
    name: 'Afternoon',
    timing: '15:30',
    orderIndex: 3,
    foods: [
      FoodItem(name: 'Tuna Can', quantity: '150g',
          protein: 33, carbs: 0, fat: 2, calories: 146),
      FoodItem(name: 'Brown Rice', quantity: '1 cup cooked',
          protein: 5, carbs: 45, fat: 2, calories: 218),
      FoodItem(name: 'Broccoli', quantity: '100g',
          protein: 3, carbs: 11, fat: 0, calories: 55),
    ],
  ),
  const Meal(
    name: 'Dinner',
    timing: '20:00',
    orderIndex: 4,
    foods: [
      FoodItem(name: 'Salmon', quantity: '150g',
          protein: 34, carbs: 0, fat: 13, calories: 259),
      FoodItem(name: 'Quinoa', quantity: '1 cup cooked',
          protein: 8, carbs: 39, fat: 4, calories: 222),
      FoodItem(name: 'Roasted Veggies', quantity: '150g',
          protein: 3, carbs: 20, fat: 5, calories: 133),
    ],
  ),
];

// ===========================================================================
// Master list — exported for use throughout the app
// ===========================================================================

final List<DietPlan> kDietTemplates = [
  // 1 — Lean Bulk
  DietPlan(
    id: 'diet_template_lean_bulk',
    gymId: 'template',
    name: 'Lean Bulk',
    description:
        'High-calorie plan designed to maximise lean muscle gain while '
        'minimising fat accumulation. Carbohydrates timed around training.',
    goal: 'muscle_gain',
    targetCalories: 3000,
    targetProtein: 220,
    targetCarbs: 350,
    targetFat: 80,
    hydrationLiters: 4.0,
    meals: _leanBulkMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 2 — Aggressive Cut
  DietPlan(
    id: 'diet_template_cut',
    gymId: 'template',
    name: 'Aggressive Cut',
    description:
        'Steep calorie deficit with very high protein to preserve muscle '
        'during a rapid fat-loss phase. Low carbs, minimum fat.',
    goal: 'fat_loss',
    targetCalories: 1800,
    targetProtein: 210,
    targetCarbs: 120,
    targetFat: 55,
    hydrationLiters: 3.5,
    meals: _cutMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 3 — Maintenance
  DietPlan(
    id: 'diet_template_maintenance',
    gymId: 'template',
    name: 'Maintenance',
    description:
        'Balanced macros at calorie maintenance. Suitable for athletes '
        'between phases or during deload weeks.',
    goal: 'maintenance',
    targetCalories: 2300,
    targetProtein: 175,
    targetCarbs: 260,
    targetFat: 70,
    hydrationLiters: 3.0,
    meals: _maintenanceMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 4 — Ketogenic
  DietPlan(
    id: 'diet_template_keto',
    gymId: 'template',
    name: 'Ketogenic',
    description:
        'Very low-carb, high-fat ketogenic diet. Induces nutritional ketosis '
        'for sustained fat burning. MCT oil and fatty proteins are staples.',
    goal: 'fat_loss',
    targetCalories: 2200,
    targetProtein: 180,
    targetCarbs: 30,
    targetFat: 165,
    hydrationLiters: 3.5,
    meals: _ketoMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 5 — High Protein Recomp
  DietPlan(
    id: 'diet_template_recomp',
    gymId: 'template',
    name: 'High Protein Recomp',
    description:
        'Body recomposition plan: high protein, moderate carbs and fat at '
        'a slight deficit. Targets simultaneous fat loss and muscle retention.',
    goal: 'recomp',
    targetCalories: 2600,
    targetProtein: 250,
    targetCarbs: 250,
    targetFat: 65,
    hydrationLiters: 3.5,
    meals: _recompMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 6 — Vegetarian Bulk
  DietPlan(
    id: 'diet_template_veg_bulk',
    gymId: 'template',
    name: 'Vegetarian Bulk',
    description:
        'Lacto-vegetarian muscle-gain plan. Uses complementary plant proteins '
        '(dal + rice, paneer, legumes) to meet daily protein targets.',
    goal: 'muscle_gain',
    targetCalories: 2900,
    targetProtein: 170,
    targetCarbs: 370,
    targetFat: 75,
    hydrationLiters: 3.5,
    meals: _vegBulkMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 7 — Vegan Performance
  DietPlan(
    id: 'diet_template_vegan_perf',
    gymId: 'template',
    name: 'Vegan Performance',
    description:
        'Whole-food plant-based performance plan. High-carb timing around '
        'training, hemp seeds and tempeh for complete amino acid coverage.',
    goal: 'performance',
    targetCalories: 2700,
    targetProtein: 155,
    targetCarbs: 400,
    targetFat: 60,
    hydrationLiters: 4.0,
    meals: _veganPerfMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: _kTemplateDate,
    updatedAt: _kTemplateDate,
  ),

  // 8 — Bodybuilding Hypertrophy
  DietPlan(
    id: 'template_bodybuilding',
    gymId: '',
    clientId: null,
    trainerId: null,
    name: 'Bodybuilding Hypertrophy',
    description:
        'High-protein plan for muscle hypertrophy and aesthetic development. '
        'Periodized carb intake around training.',
    goal: 'bodybuilding',
    targetCalories: 3200,
    targetProtein: 280,
    targetCarbs: 320,
    targetFat: 85,
    hydrationLiters: 4.5,
    meals: _bodybuildingMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),

  // 9 — Powerlifting Strength Fuel
  DietPlan(
    id: 'template_powerlifting',
    gymId: '',
    clientId: null,
    trainerId: null,
    name: 'Powerlifting Strength Fuel',
    description:
        'Calorie-surplus plan designed for maximal strength gains in the Big '
        'Three: Squat, Bench Press, Deadlift.',
    goal: 'powerlifting',
    targetCalories: 3500,
    targetProtein: 260,
    targetCarbs: 400,
    targetFat: 95,
    hydrationLiters: 4.5,
    meals: _powerliftingMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),

  // 10 — Arm Wrestling Power Plan
  DietPlan(
    id: 'template_arm_wrestling',
    gymId: '',
    clientId: null,
    trainerId: null,
    name: 'Arm Wrestling Power Plan',
    description:
        'Lean power plan targeting forearm, wrist and grip strength. High '
        'protein, moderate carbs for explosive pulling power.',
    goal: 'arm_wrestling',
    targetCalories: 2800,
    targetProtein: 230,
    targetCarbs: 290,
    targetFat: 75,
    hydrationLiters: 4.0,
    meals: _armWrestlingMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),

  // 11 — Olympic Weightlifting Performance
  DietPlan(
    id: 'template_weightlifting',
    gymId: '',
    clientId: null,
    trainerId: null,
    name: 'Olympic Weightlifting Performance',
    description:
        'Explosive power and technique plan for Snatch and Clean & Jerk. '
        'Carb-centric for high-intensity training sessions.',
    goal: 'weightlifting',
    targetCalories: 3000,
    targetProtein: 220,
    targetCarbs: 360,
    targetFat: 78,
    hydrationLiters: 4.0,
    meals: _weightliftingMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),

  // 12 — CrossFit Metabolic Fuel
  DietPlan(
    id: 'template_crossfit',
    gymId: '',
    clientId: null,
    trainerId: null,
    name: 'CrossFit Metabolic Fuel',
    description:
        'High-intensity functional fitness plan. Balanced macros with '
        'strategic carb timing to power through WODs.',
    goal: 'crossfit',
    targetCalories: 2900,
    targetProtein: 210,
    targetCarbs: 330,
    targetFat: 80,
    hydrationLiters: 4.0,
    meals: _crossfitMeals,
    isTemplate: true,
    status: PlanStatus.active,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  ),
];
