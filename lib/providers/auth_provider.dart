import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../core/enums.dart';
import '../core/dev_bypass.dart';

// ─── Core Service Providers ───────────────────────────────────────

/// Supabase client provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!AppConfig.hasSupabase) {
    throw StateError(
      'Supabase is not configured. Add SUPABASE_URL and '
      'SUPABASE_ANON_KEY to your .env file.',
    );
  }
  return Supabase.instance.client;
});

/// Auth service provider.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(supabaseClientProvider));
});

/// Database service provider.
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.read(supabaseClientProvider));
});

/// Storage service provider.
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.read(supabaseClientProvider));
});

// ─── Auth State ────────────────────────────────────────────────────

/// Watches Supabase auth state changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authStateChanges;
});

/// Current authenticated user profile.
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<AppUser?>>((ref) {
  return CurrentUserNotifier(ref);
});

/// Notifier that manages the current user state.
class CurrentUserNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref _ref;

  CurrentUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final authService = _ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user != null) {
      try {
        var profile = await authService.getProfile(user.id);
        if (isDevUser(profile.email)) {
          profile = profile.copyWith(globalRole: UserRole.gymOwner);
        }
        state = AsyncValue.data(profile);
      } catch (e) {
        // Fallback for dev users even if profile fetch fails
        if (isDevUser(user.email)) {
          state = AsyncValue.data(AppUser(
            id: user.id,
            email: user.email!,
            fullName: user.userMetadata?['full_name'] ?? 'Dev Owner',
            globalRole: UserRole.gymOwner,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } else {
          state = const AsyncValue.data(null);
        }
      }
    } else {
      state = const AsyncValue.data(null);
    }

    // Listen for auth state changes
    _ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) {
        _handleAuthChange(authService, authState);
      });
    });
  }

  /// Internal handler for auth state changes — keeps the whenData callback sync.
  Future<void> _handleAuthChange(
    AuthService authService,
    AuthState authState,
  ) async {
    if (authState.event == AuthChangeEvent.signedOut) {
      state = const AsyncValue.data(null);
      return;
    }

    if (authState.session?.user != null) {
      final user = authState.session!.user;
      try {
        var profile = await authService.getProfile(user.id);
        if (isDevUser(profile.email)) {
          profile = profile.copyWith(globalRole: UserRole.gymOwner);
        }
        state = AsyncValue.data(profile);
      } catch (e) {
        // Fallback for dev users even if profile fetch fails
        if (isDevUser(user.email)) {
          state = AsyncValue.data(AppUser(
            id: user.id,
            email: user.email!,
            fullName: user.userMetadata?['full_name'] ?? 'Dev Owner',
            globalRole: UserRole.gymOwner,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        } else {
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    }
  }

  /// Sign up and set current user.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole role = UserRole.gymOwner,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(authServiceProvider).signUp(
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
            role: role,
          );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Let the UI (register screen) handle and display the error.
    }
  }

  /// Sign in and set current user.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _ref.read(authServiceProvider).signIn(
            email: email,
            password: password,
          );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    await _ref.read(authServiceProvider).signOut();
    state = const AsyncValue.data(null);
  }

  /// Refresh profile from database.
  Future<void> refresh() async {
    final authService = _ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user != null) {
      try {
        var profile = await authService.getProfile(user.id);
        if (isDevUser(profile.email)) {
          profile = profile.copyWith(globalRole: UserRole.gymOwner);
        }
        state = AsyncValue.data(profile);
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Reset password by sending a recovery email.
  Future<void> resetPassword(String email) async {
    await _ref.read(authServiceProvider).resetPassword(email);
  }

  /// Verify the recovery code before allowing a password reset.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    await _ref.read(authServiceProvider).verifyRecoveryOtp(
          email: email,
          token: token,
        );
  }

  /// Update password for the current session or recovery flow.
  Future<void> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    await _ref.read(authServiceProvider).updatePassword(
          newPassword,
          currentPassword: currentPassword,
        );
  }
}
