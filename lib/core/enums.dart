/// User roles within the GymOS platform.
enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  gymOwner('gym_owner', 'Gym Owner'),
  trainer('trainer', 'Trainer'),
  client('client', 'Client');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}

/// SaaS subscription tiers.
enum PlanTier {
  basic('basic', 'Basic', 50, 1),
  pro('pro', 'Pro', 200, 5),
  elite('elite', 'Elite', 500, -1); // 500 soft cap, -1 trainers = unlimited

  const PlanTier(this.value, this.label, this.maxClients, this.maxTrainers);
  final String value;
  final String label;
  final int maxClients;
  final int maxTrainers;

  bool get isUnlimited => maxClients == -1;

  static PlanTier fromString(String value) {
    return PlanTier.values.firstWhere(
      (tier) => tier.value == value,
      orElse: () => PlanTier.basic,
    );
  }
}

/// Membership status for gym clients.
enum MembershipStatus {
  active('active', 'Active'),
  expired('expired', 'Expired'),
  cancelled('cancelled', 'Cancelled'),
  paused('paused', 'Paused');

  const MembershipStatus(this.value, this.label);
  final String value;
  final String label;

  static MembershipStatus fromString(String value) {
    return MembershipStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => MembershipStatus.active,
    );
  }
}

/// Subscription status for the gym's SaaS plan.
enum SubscriptionStatus {
  active('active', 'Active'),
  pastDue('past_due', 'Past Due'),
  cancelled('cancelled', 'Cancelled'),
  trialing('trialing', 'Trial');

  const SubscriptionStatus(this.value, this.label);
  final String value;
  final String label;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SubscriptionStatus.active,
    );
  }
}

/// Client fitness goals — maps 1:1 to AI prompt schema.
enum FitnessGoal {
  fatLoss('fat_loss', 'Fat Loss'),
  muscleGain('muscle_gain', 'Muscle Gain'),
  maintenance('maintenance', 'Maintenance'),
  athleticPerformance('athletic_performance', 'Athletic Performance'),
  generalFitness('general_fitness', 'General Fitness'),
  rehabilitation('rehabilitation', 'Rehabilitation'),
  sportSpecific('sport_specific', 'Sport Specific');

  const FitnessGoal(this.value, this.label);
  final String value;
  final String label;

  static FitnessGoal fromString(String value) {
    return FitnessGoal.values.firstWhere(
      (g) => g.value == value,
      orElse: () => FitnessGoal.generalFitness,
    );
  }
}

/// Training experience level.
enum TrainingLevel {
  beginner('beginner', 'Beginner'),
  intermediate('intermediate', 'Intermediate'),
  advanced('advanced', 'Advanced'),
  athlete('athlete', 'Athlete');

  const TrainingLevel(this.value, this.label);
  final String value;
  final String label;

  static TrainingLevel fromString(String value) {
    return TrainingLevel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => TrainingLevel.beginner,
    );
  }
}

/// Available equipment — expanded for AI prompt schema.
enum EquipmentType {
  fullGym('full_gym', 'Full Gym'),
  homeWithEquipment('home_with_equipment', 'Home (With Equipment)'),
  homeMinimal('home_minimal', 'Home (Minimal)'),
  bodyweightOnly('bodyweight_only', 'Bodyweight Only');

  const EquipmentType(this.value, this.label);
  final String value;
  final String label;

  static EquipmentType fromString(String value) {
    return EquipmentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EquipmentType.fullGym,
    );
  }
}

/// Dietary preference — expanded for Indian market.
enum DietType {
  nonVegetarian('non_veg', 'Non-Vegetarian'),
  vegetarian('veg', 'Vegetarian'),
  lactoVegetarian('lacto_vegetarian', 'Lacto-Vegetarian'),
  vegan('vegan', 'Vegan'),
  jain('jain', 'Jain'),
  keto('keto', 'Keto'),
  intermittentFasting('intermittent_fasting', 'Intermittent Fasting'),
  diabeticFriendly('diabetic_friendly', 'Diabetic Friendly'),
  lowCarb('low_carb', 'Low Carb'),
  other('other', 'Other');

  const DietType(this.value, this.label);
  final String value;
  final String label;

  static DietType fromString(String value) {
    return DietType.values.firstWhere(
      (d) => d.value == value,
      orElse: () => DietType.other,
    );
  }
}

/// Preferred training time of day.
enum TrainingTime {
  morning('morning', 'Morning'),
  afternoon('afternoon', 'Afternoon'),
  evening('evening', 'Evening');

  const TrainingTime(this.value, this.label);
  final String value;
  final String label;

  static TrainingTime fromString(String value) {
    return TrainingTime.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TrainingTime.morning,
    );
  }
}

/// Weight trend for progress tracking.
enum WeightTrend {
  losingFast('losing_fast', 'Losing Fast'),
  losingSlow('losing_slow', 'Losing Slow'),
  onTrack('on_track', 'On Track'),
  losing('losing', 'Losing'),
  gaining('gaining', 'Gaining'),
  stalling('stalling', 'Stalling'),
  fluctuating('fluctuating', 'Fluctuating');

  const WeightTrend(this.value, this.label);
  final String value;
  final String label;

  static WeightTrend fromString(String value) {
    return WeightTrend.values.firstWhere(
      (t) => t.value == value,
      orElse: () => WeightTrend.stalling,
    );
  }
}

/// Quality/level rating (sleep, energy).
enum QualityRating {
  poor('poor', 'Poor'),
  average('average', 'Average'),
  good('good', 'Good'),
  excellent('excellent', 'Excellent');

  const QualityRating(this.value, this.label);
  final String value;
  final String label;

  static QualityRating fromString(String value) {
    return QualityRating.values.firstWhere(
      (r) => r.value == value,
      orElse: () => QualityRating.average,
    );
  }
}

/// Language preference.
enum LanguagePreference {
  english('english', 'English'),
  hindi('hindi', 'Hindi'),
  hinglish('hinglish', 'Hinglish');

  const LanguagePreference(this.value, this.label);
  final String value;
  final String label;

  static LanguagePreference fromString(String value) {
    return LanguagePreference.values.firstWhere(
      (l) => l.value == value,
      orElse: () => LanguagePreference.english,
    );
  }
}

/// Stress level — for v2.0 client profile schema.
enum StressLevel {
  low('low', 'Low'),
  moderate('moderate', 'Moderate'),
  high('high', 'High'),
  veryHigh('very_high', 'Very High');

  const StressLevel(this.value, this.label);
  final String value;
  final String label;

  static StressLevel fromString(String value) {
    return StressLevel.values.firstWhere(
      (s) => s.value == value,
      orElse: () => StressLevel.moderate,
    );
  }
}

/// Cuisine preference.
enum CuisineType {
  indian('indian', 'Indian'),
  mixed('mixed', 'Mixed'),
  western('western', 'Western');

  const CuisineType(this.value, this.label);
  final String value;
  final String label;

  static CuisineType fromString(String value) {
    return CuisineType.values.firstWhere(
      (c) => c.value == value,
      orElse: () => CuisineType.indian,
    );
  }
}

/// Cooking capability.
enum CookingLevel {
  fullCooking('full_cooking', 'Full Cooking'),
  partial('partial', 'Partial'),
  minimal('minimal', 'Minimal'),
  none('none', 'None');

  const CookingLevel(this.value, this.label);
  final String value;
  final String label;

  static CookingLevel fromString(String value) {
    return CookingLevel.values.firstWhere(
      (c) => c.value == value,
      orElse: () => CookingLevel.fullCooking,
    );
  }
}
