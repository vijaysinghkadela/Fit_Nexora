/// Centralized raw database values that are shared across services, models,
/// and UI filters but are not fully represented by enums yet.
class DatabaseValues {
  DatabaseValues._();

  // Common statuses used by legacy filters or cross-table queries.
  static const String activeStatus = 'active';
  static const String expiredStatus = 'expired';
  static const String cancelledStatus = 'cancelled';

  // Gym member roles.
  static const String gymMemberOwnerRole = 'owner';
  static const String gymMemberTrainerRole = 'trainer';

  // Trainer chat roles.
  static const String trainerChatMemberRole = 'member';
  static const String trainerChatTrainerRole = 'trainer';

  // Food logging defaults.
  static const String breakfastMeal = 'breakfast';
  static const String lunchMeal = 'lunch';
  static const String dinnerMeal = 'dinner';
  static const String snackMeal = 'snack';
  static const String defaultMealType = snackMeal;
  static const String defaultManualMealType = breakfastMeal;
  static const List<String> mealTypes = [
    breakfastMeal,
    lunchMeal,
    dinnerMeal,
    snackMeal,
  ];

  // Currency defaults for member-facing gym memberships.
  static const String defaultCurrency = 'INR';
}
