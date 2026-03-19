/// Developer bypass for testing all plan tiers without real database records.
///
/// When the logged-in user matches [devEmail], every provider returns rich
/// mock data so the entire member dashboard, workout, diet, progress, and
/// check-in features can be exercised end-to-end.
///
/// ⚠️  Remove or disable before production release.
library;

import '../models/membership_model.dart';
import '../models/workout_plan_model.dart';
import '../models/diet_plan_model.dart';
import '../models/announcement_model.dart';
import '../models/gym_model.dart';
import '../models/client_profile_model.dart';
import '../models/membership_counts.dart';
import 'pagination.dart';
import 'enums.dart';

// ─── Config ──────────────────────────────────────────────────────────────────

/// The developer emails that trigger all bypasses.
const List<String> devEmails = [
  'vijaysinghfitness@gmail.com',
  'rohit@gmail.com',
  'vinaypalsingh085@gmail.com',
];

/// Quick check used by every provider.
bool isDevUser(String? email) => devEmails.contains(email);

// ─── Membership (Master — unlocks ALL features) ─────────────────────────────

Membership devMembership() => Membership(
      id: 'dev-mock-membership',
      clientId: 'dev-mock-client',
      gymId: 'dev-mock-gym',
      planName: 'Master',
      amount: 2499.0,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 365)),
      status: MembershipStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

// ─── Workout Plan ────────────────────────────────────────────────────────────

WorkoutPlan devWorkoutPlan() {
  final now = DateTime.now();
  return WorkoutPlan(
    id: 'dev-workout-001',
    gymId: 'dev-mock-gym',
    clientId: 'dev-mock-client',
    trainerId: 'dev-mock-trainer',
    name: 'Ultimate Muscle Builder',
    description: 'A 6-day PPL split designed for hypertrophy and strength.',
    goal: 'muscle_gain',
    durationWeeks: 12,
    currentWeek: 3,
    phase: 'Hypertrophy',
    status: PlanStatus.active,
    createdAt: now,
    updatedAt: now,
    days: const [
      TrainingDay(
        dayName: 'Day 1 — Push (Chest & Triceps)',
        muscleGroup: 'chest_triceps',
        dayIndex: 0,
        exercises: [
          Exercise(name: 'Bench Press', sets: 4, reps: '8-10', restSeconds: 90, equipment: 'Barbell'),
          Exercise(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', restSeconds: 75, equipment: 'Dumbbells'),
          Exercise(name: 'Cable Fly', sets: 3, reps: '12-15', restSeconds: 60, equipment: 'Cable'),
          Exercise(name: 'Overhead Tricep Extension', sets: 3, reps: '12', restSeconds: 60, equipment: 'Dumbbell'),
          Exercise(name: 'Tricep Pushdowns', sets: 3, reps: '15', restSeconds: 45, equipment: 'Cable'),
        ],
      ),
      TrainingDay(
        dayName: 'Day 2 — Pull (Back & Biceps)',
        muscleGroup: 'back_biceps',
        dayIndex: 1,
        exercises: [
          Exercise(name: 'Deadlift', sets: 4, reps: '6-8', restSeconds: 120, equipment: 'Barbell'),
          Exercise(name: 'Pull-ups', sets: 3, reps: '8-10', restSeconds: 90, equipment: 'Bodyweight'),
          Exercise(name: 'Seated Cable Row', sets: 3, reps: '10-12', restSeconds: 75, equipment: 'Cable'),
          Exercise(name: 'Barbell Curl', sets: 3, reps: '10', restSeconds: 60, equipment: 'Barbell'),
          Exercise(name: 'Hammer Curls', sets: 3, reps: '12', restSeconds: 45, equipment: 'Dumbbells'),
        ],
      ),
      TrainingDay(
        dayName: 'Day 3 — Legs & Core',
        muscleGroup: 'legs_core',
        dayIndex: 2,
        exercises: [
          Exercise(name: 'Barbell Squat', sets: 4, reps: '8-10', restSeconds: 120, equipment: 'Barbell'),
          Exercise(name: 'Romanian Deadlift', sets: 3, reps: '10-12', restSeconds: 90, equipment: 'Barbell'),
          Exercise(name: 'Leg Press', sets: 3, reps: '12-15', restSeconds: 75, equipment: 'Machine'),
          Exercise(name: 'Leg Curl', sets: 3, reps: '12', restSeconds: 60, equipment: 'Machine'),
          Exercise(name: 'Hanging Leg Raise', sets: 3, reps: '15', restSeconds: 45, equipment: 'Bar'),
          Exercise(name: 'Plank', sets: 3, reps: '60s', restSeconds: 30, equipment: 'Bodyweight'),
        ],
      ),
      TrainingDay(
        dayName: 'Day 4 — Shoulders & Arms',
        muscleGroup: 'shoulders_arms',
        dayIndex: 3,
        exercises: [
          Exercise(name: 'Overhead Press', sets: 4, reps: '8-10', restSeconds: 90, equipment: 'Barbell'),
          Exercise(name: 'Lateral Raise', sets: 3, reps: '12-15', restSeconds: 60, equipment: 'Dumbbells'),
          Exercise(name: 'Face Pulls', sets: 3, reps: '15', restSeconds: 60, equipment: 'Cable'),
          Exercise(name: 'EZ-Bar Curl', sets: 3, reps: '10', restSeconds: 60, equipment: 'EZ-Bar'),
          Exercise(name: 'Skull Crushers', sets: 3, reps: '10-12', restSeconds: 60, equipment: 'EZ-Bar'),
        ],
      ),
      TrainingDay(
        dayName: 'Day 5 — Full Body Power',
        muscleGroup: 'full_body',
        dayIndex: 4,
        exercises: [
          Exercise(name: 'Power Clean', sets: 4, reps: '5', restSeconds: 120, equipment: 'Barbell'),
          Exercise(name: 'Front Squat', sets: 3, reps: '8', restSeconds: 90, equipment: 'Barbell'),
          Exercise(name: 'Weighted Dips', sets: 3, reps: '8-10', restSeconds: 75, equipment: 'Bodyweight'),
          Exercise(name: 'Barbell Row', sets: 3, reps: '10', restSeconds: 75, equipment: 'Barbell'),
          Exercise(name: 'Farmer Walk', sets: 3, reps: '40m', restSeconds: 60, equipment: 'Dumbbells'),
        ],
      ),
      TrainingDay(
        dayName: 'Day 6 — Active Recovery & Cardio',
        muscleGroup: 'cardio',
        dayIndex: 5,
        exercises: [
          Exercise(name: 'Treadmill Incline Walk', sets: 1, reps: '20 min', restSeconds: 0, equipment: 'Treadmill'),
          Exercise(name: 'Foam Rolling', sets: 1, reps: '10 min', restSeconds: 0, equipment: 'Foam Roller'),
          Exercise(name: 'Stretching Routine', sets: 1, reps: '15 min', restSeconds: 0, equipment: 'Bodyweight'),
        ],
      ),
    ],
  );
}

// ─── Diet Plan ───────────────────────────────────────────────────────────────

DietPlan devDietPlan() {
  final now = DateTime.now();
  return DietPlan(
    id: 'dev-diet-001',
    gymId: 'dev-mock-gym',
    clientId: 'dev-mock-client',
    trainerId: 'dev-mock-trainer',
    name: 'High Protein Muscle Gain',
    description: 'A structured Indian-friendly diet plan for muscle building.',
    goal: 'muscle_gain',
    targetCalories: 2800,
    targetProtein: 180,
    targetCarbs: 320,
    targetFat: 75,
    hydrationLiters: 4.0,
    status: PlanStatus.active,
    createdAt: now,
    updatedAt: now,
    meals: const [
      Meal(
        name: 'Breakfast',
        timing: '7:00 AM',
        orderIndex: 0,
        foods: [
          FoodItem(name: 'Oats with Milk', quantity: '100g oats + 250ml milk', protein: 18, carbs: 65, fat: 10, calories: 420, isIndian: true),
          FoodItem(name: 'Banana', quantity: '2 medium', protein: 2, carbs: 54, fat: 1, calories: 210),
          FoodItem(name: 'Almonds', quantity: '15 pieces', protein: 6, carbs: 3, fat: 14, calories: 160),
        ],
      ),
      Meal(
        name: 'Mid-Morning Snack',
        timing: '10:00 AM',
        orderIndex: 1,
        foods: [
          FoodItem(name: 'Paneer Bhurji', quantity: '150g paneer', protein: 28, carbs: 8, fat: 22, calories: 340, isIndian: true),
          FoodItem(name: 'Whole Wheat Roti', quantity: '2 pieces', protein: 6, carbs: 40, fat: 2, calories: 200, isIndian: true),
        ],
      ),
      Meal(
        name: 'Lunch',
        timing: '1:00 PM',
        orderIndex: 2,
        foods: [
          FoodItem(name: 'Chicken Breast', quantity: '200g', protein: 46, carbs: 0, fat: 6, calories: 330, isIndian: true),
          FoodItem(name: 'Brown Rice', quantity: '200g cooked', protein: 5, carbs: 45, fat: 2, calories: 220, isIndian: true),
          FoodItem(name: 'Dal (Lentils)', quantity: '1 cup', protein: 12, carbs: 30, fat: 3, calories: 200, isIndian: true),
          FoodItem(name: 'Mixed Salad', quantity: '1 bowl', protein: 2, carbs: 8, fat: 1, calories: 45),
        ],
      ),
      Meal(
        name: 'Pre-Workout',
        timing: '4:30 PM',
        orderIndex: 3,
        foods: [
          FoodItem(name: 'Whey Protein Shake', quantity: '1 scoop + water', protein: 24, carbs: 3, fat: 1, calories: 120),
          FoodItem(name: 'Apple', quantity: '1 medium', protein: 0, carbs: 25, fat: 0, calories: 95),
        ],
      ),
      Meal(
        name: 'Dinner',
        timing: '8:00 PM',
        orderIndex: 4,
        foods: [
          FoodItem(name: 'Fish Curry', quantity: '200g fish', protein: 40, carbs: 10, fat: 12, calories: 310, isIndian: true),
          FoodItem(name: 'Jeera Rice', quantity: '150g cooked', protein: 4, carbs: 35, fat: 2, calories: 180, isIndian: true),
          FoodItem(name: 'Raita', quantity: '1 cup', protein: 5, carbs: 8, fat: 4, calories: 80, isIndian: true),
        ],
      ),
    ],
  );
}

// ─── Progress Check-ins ──────────────────────────────────────────────────────

List<Map<String, dynamic>> devProgressData() => [
      {'weight_kg': 78.5, 'checkin_date': DateTime.now().subtract(const Duration(days: 0)).toIso8601String()},
      {'weight_kg': 78.8, 'checkin_date': DateTime.now().subtract(const Duration(days: 7)).toIso8601String()},
      {'weight_kg': 79.2, 'checkin_date': DateTime.now().subtract(const Duration(days: 14)).toIso8601String()},
      {'weight_kg': 79.5, 'checkin_date': DateTime.now().subtract(const Duration(days: 21)).toIso8601String()},
      {'weight_kg': 80.0, 'checkin_date': DateTime.now().subtract(const Duration(days: 28)).toIso8601String()},
    ];

// ─── Attendance ──────────────────────────────────────────────────────────────

/// Mock attendance count for this month.
const int devAttendanceThisMonth = 18;

// ─── Announcements ───────────────────────────────────────────────────────────

List<Announcement> devAnnouncements() => [
      Announcement(
        id: 'dev-ann-001',
        gymId: 'dev-mock-gym',
        title: '🎉 New Year, New You Challenge!',
        body: 'Join our 30-day transformation challenge starting next Monday. Prizes for top 3 transformations!',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Announcement(
        id: 'dev-ann-002',
        gymId: 'dev-mock-gym',
        title: '🔧 Gym Maintenance Notice',
        body: 'The cardio section will be under maintenance on Sunday from 6 AM to 10 AM. Sorry for the inconvenience.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Announcement(
        id: 'dev-ann-003',
        gymId: 'dev-mock-gym',
        title: '💪 Free PT Session This Weekend',
        body: 'All Master plan members get a complimentary personal training session this Saturday!',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
// ─── Gyms & Dashboard (Owner Bypass) ─────────────────────────────────────────

List<Gym> devGyms() => [
      Gym(
        id: 'dev-mock-gym',
        ownerId: 'dev-mock-owner',
        name: 'Fit Nexora Dev Gym',
        address: '123 AI Avenue, Silicon Valley',
        phone: '+91 98765 43210',
        planTier: PlanTier.elite,
        maxClients: 500,
        maxTrainers: 10,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
    ];

Map<String, dynamic> devDashboardStats() => {
      'total_clients': 150,
      'active_members': 142,
      'expired_members': 8,
      'expiring_soon': 12,
    };

// ─── Clients (Paged) ─────────────────────────────────────────────────────────

PagedResult<ClientProfile> devClientsPaged({
  int limit = 20,
  int offset = 0,
  String? search,
  FitnessGoal? goalFilter,
  String? sort = 'name_asc',
}) {
  List<ClientProfile> allClients = List.generate(45, (i) {
    return ClientProfile(
      id: 'dev-client-${100 + i}',
      gymId: 'dev-mock-gym',
      fullName: 'Dev Client ${i + 1}',
      email: 'client$i@example.com',
      phone: '+91 90000 000${i.toString().padLeft(2, '0')}',
      goal: i % 3 == 0
          ? FitnessGoal.fatLoss
          : (i % 3 == 1 ? FitnessGoal.muscleGain : FitnessGoal.maintenance),
      sex: i % 2 == 0 ? 'male' : 'female',
      createdAt: DateTime.now().subtract(Duration(days: i)),
      updatedAt: DateTime.now(),
    );
  });

  // Apply filters
  if (goalFilter != null) {
    allClients = allClients.where((c) => c.goal == goalFilter).toList();
  }

  if (search != null && search.isNotEmpty) {
    final query = search.toLowerCase();
    allClients = allClients.where((c) =>
        (c.fullName?.toLowerCase().contains(query) ?? false) ||
        (c.email?.toLowerCase().contains(query) ?? false)).toList();
  }

  // Apply sorting
  if (sort == 'name_asc') {
    allClients.sort((a, b) => (a.fullName ?? '').compareTo(b.fullName ?? ''));
  } else if (sort == 'name_desc') {
    allClients.sort((a, b) => (b.fullName ?? '').compareTo(a.fullName ?? ''));
  } else if (sort == 'recent') {
    allClients.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  final items = allClients.skip(offset).take(limit).toList();
  return PagedResult<ClientProfile>(
    items: items,
    hasMore: offset + items.length < allClients.length,
    nextOffset: offset + items.length,
    totalCount: allClients.length,
  );
}

// ─── Memberships (Paged) ─────────────────────────────────────────────────────

PagedResult<Membership> devMembershipsPaged({
  int limit = 12,
  int offset = 0,
}) {
  final List<Membership> allMemberships = List.generate(35, (i) {
    final status = i % 5 == 0 ? MembershipStatus.expired : MembershipStatus.active;
    return Membership(
      id: 'dev-mem-${200 + i}',
      clientId: 'dev-client-${100 + i}',
      gymId: 'dev-mock-gym',
      planName: i % 2 == 0 ? 'Elite' : 'Pro',
      amount: i % 2 == 0 ? 25000 : 15000,
      startDate: DateTime.now().subtract(Duration(days: 30 + i)),
      endDate: status == MembershipStatus.expired
          ? DateTime.now().subtract(const Duration(days: 1))
          : DateTime.now().add(Duration(days: 30 + i)),
      status: status,
      createdAt: DateTime.now().subtract(Duration(days: 35 + i)),
      updatedAt: DateTime.now(),
    );
  });

  final items = allMemberships.skip(offset).take(limit).toList();
  return PagedResult<Membership>(
    items: items,
    hasMore: offset + items.length < allMemberships.length,
    nextOffset: offset + items.length,
    totalCount: allMemberships.length,
  );
}

MembershipCounts devMembershipCounts() => const MembershipCounts(
      total: 35,
      active: 28,
      expiring: 7,
    );

List<Map<String, dynamic>> devRecentCheckInsOwner() => List.generate(24, (i) {
      return {
        'checked_in_at': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
        'checked_out_at':
            DateTime.now().subtract(Duration(hours: i - 1)).toIso8601String(),
      };
    });
