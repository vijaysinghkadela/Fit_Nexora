import 'package:flutter_test/flutter_test.dart';
import 'package:gymos_ai/core/database_values.dart';
import 'package:gymos_ai/models/food_log_model.dart';

void main() {
  group('FoodLog', () {
    test('defaults meal type when the payload omits it', () {
      final log = FoodLog.fromJson({
        'id': 'log-1',
        'user_id': 'user-1',
        'product_name': 'Apple',
        'logged_at': '2026-03-14T12:00:00Z',
      });

      expect(log.mealType, DatabaseValues.defaultMealType);
    });

    test('toInsertJson keeps the selected meal type', () {
      final log = FoodLog(
        id: 'ignored',
        userId: 'user-1',
        productName: 'Protein Bar',
        caloriesKcal: 220,
        proteinG: 20,
        fatG: 8,
        carbsG: 18,
        sugarG: 6,
        fiberG: 4,
        sodiumMg: 180,
        servingSizeG: 60,
        quantity: 1,
        mealType: DatabaseValues.breakfastMeal,
        loggedAt: DateTime.parse('2026-03-14T12:00:00Z'),
      );

      expect(log.toInsertJson()['meal_type'], DatabaseValues.breakfastMeal);
      expect(log.toInsertJson().containsKey('id'), isFalse);
    });
  });
}
