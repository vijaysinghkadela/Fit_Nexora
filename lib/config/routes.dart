import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/todos/todos_screen.dart';
import '../screens/traffic/gym_traffic_screen.dart';
import '../screens/nutrition/nutrition_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/member/member_home_screen.dart';
import '../screens/member/member_workout_screen.dart';
import '../screens/member/member_diet_screen.dart';
import '../screens/member/member_progress_screen.dart';
import '../screens/member/member_announcements_screen.dart';
import '../screens/pro/pro_home_screen.dart';
import '../screens/pro/pro_nutrition_screen.dart';
import '../screens/pro/pro_measurements_screen.dart';
import '../core/enums.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Reusable fade transition page builder.
Page<void> _fadePage(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Routes that do not require authentication.
const _publicRoutes = ['/', '/login', '/register'];

String _homeRouteForRole(UserRole role) =>
    role == UserRole.client ? '/member' : '/dashboard';

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

// ─── Auth refresh listenable ──────────────────────────────────────────────────

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter calls its redirect
/// every time the stream emits (i.e. on every Supabase auth state change).
///
/// Without this, GoRouter only runs [redirect] during navigation transitions,
/// which creates a race condition where the session appears null and the
/// authenticated user is bounced back to /login.
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

// ─── Router Provider ─────────────────────────────────────────────────────────

/// GoRouter configuration with auth guards.
final routerProvider = Provider<GoRouter>((ref) {
  final hasSupabase = AppConfig.hasSupabase;
  final supabase = hasSupabase ? Supabase.instance.client : null;

  GoRouterRefreshStream? refreshStream;
  if (supabase != null) {
    refreshStream = GoRouterRefreshStream(supabase.auth.onAuthStateChange);

    // Clean up the refresh stream when the provider is disposed.
    ref.onDispose(refreshStream.dispose);
  }

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,

    /// Re-evaluate redirect whenever Supabase auth state changes.
    refreshListenable: refreshStream,

    redirect: (context, state) {
      final session = supabase?.auth.currentSession;
      final isAuth = session != null;
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);
      final currentUser = hasSupabase ? ref.read(currentUserProvider) : null;
      final role = _resolveCurrentRole(currentUser, supabase);

      // Unauthenticated user trying to access a protected route → /login.
      if (!isAuth && !isPublic) return '/login';

      // Authenticated user on splash, login, or register — route based on role.
      if (isAuth &&
          (location == '/' ||
              location == '/login' ||
              location == '/register')) {
        if (role == null) return location == '/' ? null : '/';
        return _homeRouteForRole(role);
      }

      // Guard the admin route — only superAdmins may enter.
      if (location == '/admin') {
        if (role != UserRole.superAdmin) {
          return role == UserRole.client ? '/member' : '/dashboard';
        }
      }

      return null; // No redirect needed.
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
        pageBuilder: (context, state) =>
            _fadePage(state, const RegisterScreen()),
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
        path: '/pro',
        name: 'pro',
        builder: (context, state) => const ProHomeScreen(),
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
        pageBuilder: (context, state) =>
            _fadePage(state, const GymTrafficScreen()),
      ),
      GoRoute(
        path: '/nutrition',
        name: 'nutrition',
        pageBuilder: (context, state) =>
            _fadePage(state, const NutritionScreen()),
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
