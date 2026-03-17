import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/constants.dart';
import '../core/enums.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/password_updated_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/verify_otp_screen.dart';
import '../screens/clients/clients_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/diet/diet_plans_screen.dart';
import '../screens/elite/elite_ai_trainer_screen.dart';
import '../screens/elite/elite_chat_screen.dart';
import '../screens/elite/elite_home_screen.dart';
import '../screens/elite/elite_muscle_progress_screen.dart';
import '../screens/elite/elite_paywall_screen.dart';
import '../screens/elite/elite_supplement_screen.dart';
import '../screens/elite/elite_transformation_screen.dart';
import '../screens/master/master_ai_coach_screen.dart';
import '../screens/master/master_analytics_screen.dart';
import '../screens/master/master_challenges_screen.dart';
import '../screens/master/master_home_screen.dart';
import '../screens/master/master_live_sessions_screen.dart';
import '../screens/master/master_paywall_screen.dart';
import '../screens/master/master_recovery_screen.dart';
import '../screens/member/member_announcements_screen.dart';
import '../screens/member/member_diet_screen.dart';
import '../screens/member/member_home_screen.dart';
import '../screens/member/member_paywall_screen.dart';
import '../screens/member/member_progress_screen.dart';
import '../screens/member/member_workout_screen.dart';
import '../screens/memberships/memberships_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/nutrition/barcode_scanner_screen.dart';
import '../screens/nutrition/manual_nutrition_log_screen.dart';
import '../screens/nutrition/daily_calorie_goal_screen.dart';
import '../screens/workouts/active_workout_screen.dart';
import '../screens/workouts/rest_timer_screen.dart';
import '../screens/workouts/workout_completion_screen.dart';
import '../screens/workouts/workout_history_screen.dart';
import '../screens/workouts/search_exercise_screen.dart';
import '../screens/workouts/exercise_progress_screen.dart';
import '../screens/workouts/compare_exercises_screen.dart';
import '../screens/master/master_profile_screen.dart';
import '../screens/master/master_perks_screen.dart';
import '../screens/master/master_transformation_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/clients/log_checkin_screen.dart';
import '../screens/pro/pro_ai_screen.dart';
import '../screens/pro/pro_home_screen.dart';
import '../screens/pro/pro_measurements_screen.dart';
import '../screens/pro/pro_nutrition_screen.dart';
import '../screens/pro/pro_paywall_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/subscription/pricing_screen.dart';
import '../screens/todos/todos_screen.dart';
import '../screens/trainer/trainer_dashboard_screen.dart';
import '../screens/traffic/gym_traffic_screen.dart';
import '../screens/workouts/workouts_screen.dart';
import '../screens/health/steps_tracking_screen.dart';
import '../screens/health/sleep_tracking_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/workouts/workout_calendar_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../widgets/shared_management_wrapper.dart';

Page<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );

const _publicRoutes = [
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/verify-otp',
  '/change-password',
  '/password-updated',
];

String _homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.superAdmin:
      return '/admin';
    case UserRole.trainer:
      return '/trainer';
    case UserRole.client:
      return '/member';
    case UserRole.gymOwner:
      return '/dashboard';
  }
}

UserRole? _resolveCurrentRole(
  AsyncValue<AppUser?>? currentUser,
  SupabaseClient? supabase,
) {
  final profileRole = currentUser?.value?.globalRole;
  if (profileRole != null) return profileRole;

  final metadataRole =
      supabase?.auth.currentUser?.userMetadata?['global_role'] as String?;
  if (metadataRole == null || metadataRole.isEmpty) return null;

  return UserRole.fromString(metadataRole);
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final hasSupabase = AppConfig.hasSupabase;
  final supabase = hasSupabase ? Supabase.instance.client : null;

  GoRouterRefreshStream? refreshStream;
  if (supabase != null) {
    refreshStream = GoRouterRefreshStream(supabase.auth.onAuthStateChange);
    ref.onDispose(refreshStream.dispose);
  }

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refreshStream,
    redirect: (context, state) {
      final session = supabase?.auth.currentSession;
      final isAuth = session != null;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);
      final currentUser = hasSupabase ? ref.read(currentUserProvider) : null;
      final role = _resolveCurrentRole(currentUser, supabase);

      if (!isAuth && !isPublic) return '/login';

      if (isAuth && (location == '/' || location == '/login' || location == '/register')) {
        if (role == null) return location == '/' ? null : '/';
        return _homeRouteForRole(role);
      }

      if (location == '/admin' && role != UserRole.superAdmin) {
        return role == null ? '/dashboard' : _homeRouteForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) => _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => _fadePage(
          state,
          ForgotPasswordScreen(
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        pageBuilder: (context, state) => _fadePage(
          state,
          VerifyOtpScreen(
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change-password',
        pageBuilder: (context, state) => _fadePage(
          state,
          ChangePasswordScreen(
            initialEmail: state.uri.queryParameters['email'],
          ),
        ),
      ),
      GoRoute(
        path: '/password-updated',
        name: 'password-updated',
        pageBuilder: (context, state) =>
            _fadePage(state, const PasswordUpdatedScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/trainer',
        name: 'trainer',
        builder: (context, state) => const TrainerDashboardScreen(),
      ),
      GoRoute(
        path: '/clients',
        name: 'clients',
        builder: (context, state) => const SharedManagementWrapper(
          currentRoute: '/clients',
          child: ClientsScreen(),
        ),
      ),
      GoRoute(
        path: '/memberships',
        name: 'memberships',
        builder: (context, state) => const SharedManagementWrapper(
          currentRoute: '/memberships',
          child: MembershipsScreen(),
        ),
      ),
      GoRoute(
        path: '/workouts',
        name: 'workouts',
        builder: (context, state) => const SharedManagementWrapper(
          currentRoute: '/workouts',
          child: WorkoutsScreen(),
        ),
      ),
      GoRoute(
        path: '/diet-plans',
        name: 'diet-plans',
        builder: (context, state) => const SharedManagementWrapper(
          currentRoute: '/diet-plans',
          child: DietPlansScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/pricing',
        name: 'pricing',
        builder: (context, state) => const PricingScreen(),
      ),
      GoRoute(
        path: '/member',
        name: 'member',
        builder: (context, state) => const MemberHomeScreen(),
      ),
      GoRoute(
        path: '/member/workout',
        name: 'member-workout',
        builder: (context, state) => const MemberWorkoutScreen(),
      ),
      GoRoute(
        path: '/member/diet',
        name: 'member-diet',
        builder: (context, state) => const MemberDietScreen(),
      ),
      GoRoute(
        path: '/member/progress',
        name: 'member-progress',
        builder: (context, state) => const MemberProgressScreen(),
      ),
      GoRoute(
        path: '/member/announcements',
        name: 'member-announcements',
        builder: (context, state) => const MemberAnnouncementsScreen(),
      ),
      GoRoute(
        path: '/member/paywall',
        name: 'member-paywall',
        builder: (context, state) => const MemberPaywallScreen(),
      ),
      GoRoute(
        path: '/pro',
        name: 'pro',
        builder: (context, state) => const ProHomeScreen(),
      ),
      GoRoute(
        path: '/pro/ai',
        name: 'pro-ai',
        builder: (context, state) => const ProAiScreen(),
      ),
      GoRoute(
        path: '/pro/nutrition',
        name: 'pro-nutrition',
        builder: (context, state) => const ProNutritionScreen(),
      ),
      GoRoute(
        path: '/pro/measurements',
        name: 'pro-measurements',
        builder: (context, state) => const ProMeasurementsScreen(),
      ),
      GoRoute(
        path: '/pro/paywall',
        name: 'pro-paywall',
        builder: (context, state) => const ProPaywallScreen(),
      ),
      GoRoute(
        path: '/elite',
        name: 'elite',
        builder: (context, state) => const EliteHomeScreen(),
      ),
      GoRoute(
        path: '/elite/ai',
        name: 'elite-ai',
        builder: (context, state) => const EliteAiTrainerScreen(),
      ),
      GoRoute(
        path: '/elite/chat',
        name: 'elite-chat',
        builder: (context, state) => const EliteChatScreen(),
      ),
      GoRoute(
        path: '/elite/supplements',
        name: 'elite-supplements',
        builder: (context, state) => const EliteSupplementScreen(),
      ),
      GoRoute(
        path: '/elite/progress',
        name: 'elite-progress',
        builder: (context, state) => const EliteMuscleProgressScreen(),
      ),
      GoRoute(
        path: '/elite/transformation',
        name: 'elite-transformation',
        builder: (context, state) => const EliteTransformationScreen(),
      ),
      GoRoute(
        path: '/elite/paywall',
        name: 'elite-paywall',
        builder: (context, state) => const ElitePaywallScreen(),
      ),
      GoRoute(
        path: '/master',
        name: 'master',
        builder: (context, state) => const MasterHomeScreen(),
      ),
      GoRoute(
        path: '/master/ai',
        name: 'master-ai',
        builder: (context, state) => const MasterAiCoachScreen(),
      ),
      GoRoute(
        path: '/master/analytics',
        name: 'master-analytics',
        builder: (context, state) => const MasterAnalyticsScreen(),
      ),
      GoRoute(
        path: '/master/challenges',
        name: 'master-challenges',
        builder: (context, state) => const MasterChallengesScreen(),
      ),
      GoRoute(
        path: '/master/live',
        name: 'master-live',
        builder: (context, state) => const MasterLiveSessionsScreen(),
      ),
      GoRoute(
        path: '/master/recovery',
        name: 'master-recovery',
        builder: (context, state) => const MasterRecoveryScreen(),
      ),
      GoRoute(
        path: '/master/paywall',
        name: 'master-paywall',
        builder: (context, state) => const MasterPaywallScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
      GoRoute(
        path: '/todos',
        name: 'todos',
        builder: (context, state) => const TodosScreen(),
      ),
      GoRoute(
        path: '/traffic',
        name: 'traffic',
        pageBuilder: (context, state) => _fadePage(
          state,
          const SharedManagementWrapper(
            currentRoute: '/traffic',
            child: GymTrafficScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/nutrition',
        name: 'nutrition',
        pageBuilder: (context, state) => _fadePage(
          state,
          const SharedManagementWrapper(
            currentRoute: '/nutrition',
            child: NutritionScreen(),
          ),
        ),
      ),
      GoRoute(
        path: '/nutrition/scan',
        name: 'nutrition-scan',
        pageBuilder: (context, state) =>
            _fadePage(state, const BarcodeScannerScreen()),
      ),
      GoRoute(
        path: '/nutrition/log',
        name: 'nutrition-log',
        pageBuilder: (context, state) =>
            _fadePage(state, const ManualNutritionLogScreen()),
      ),
      GoRoute(
        path: '/nutrition/goal',
        name: 'nutrition-goal',
        pageBuilder: (context, state) =>
            _fadePage(state, const DailyCalorieGoalScreen()),
      ),
      GoRoute(
        path: '/workout/active',
        name: 'workout-active',
        builder: (context, state) => const ActiveWorkoutScreen(),
      ),
      GoRoute(
        path: '/workout/timer',
        name: 'workout-timer',
        builder: (context, state) => const RestTimerScreen(),
      ),
      GoRoute(
        path: '/workout/done',
        name: 'workout-done',
        builder: (context, state) => const WorkoutCompletionScreen(),
      ),
      GoRoute(
        path: '/workout/history',
        name: 'workout-history',
        builder: (context, state) => const WorkoutHistoryScreen(),
      ),
      GoRoute(
        path: '/workout/exercise-search',
        name: 'workout-exercise-search',
        builder: (context, state) => const SearchExerciseScreen(),
      ),
      GoRoute(
        path: '/workout/exercise-progress',
        name: 'workout-exercise-progress',
        builder: (context, state) => const ExerciseProgressScreen(),
      ),
      GoRoute(
        path: '/workout/compare',
        name: 'workout-compare',
        builder: (context, state) => const CompareExercisesScreen(),
      ),
      GoRoute(
        path: '/master/profile',
        name: 'master-profile',
        builder: (context, state) => const MasterProfileScreen(),
      ),
      GoRoute(
        path: '/master/perks',
        name: 'master-perks',
        builder: (context, state) => const MasterPerksScreen(),
      ),
      GoRoute(
        path: '/master/transformation',
        name: 'master-transformation',
        builder: (context, state) => const MasterTransformationScreen(),
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/clients/checkin',
        name: 'clients-checkin',
        builder: (context, state) => const LogCheckinScreen(),
      ),
      GoRoute(
        path: '/health/steps',
        name: 'steps-tracking',
        pageBuilder: (c, s) => _fadePage(s, const StepsTrackingScreen()),
      ),
      GoRoute(
        path: '/health/sleep',
        name: 'sleep-tracking',
        pageBuilder: (c, s) => _fadePage(s, const SleepTrackingScreen()),
      ),
      GoRoute(
        path: '/notes',
        name: 'notes',
        pageBuilder: (c, s) => _fadePage(s, const NotesScreen()),
      ),
      GoRoute(
        path: '/workout/calendar',
        name: 'workout-calendar',
        pageBuilder: (c, s) => _fadePage(s, const WorkoutCalendarScreen()),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (c, s) => _fadePage(s, const NotificationsScreen()),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
