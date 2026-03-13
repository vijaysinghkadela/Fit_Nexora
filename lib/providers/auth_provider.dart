import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../core/enums.dart';

// ─── Core Service Providers ───────────────────────────────────────

/// Supabase client provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
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
        final profile = await authService.getProfile(user.id);
        state = AsyncValue.data(profile);
      } catch (e) {
        state = const AsyncValue.data(null);
      }
    } else {
      state = const AsyncValue.data(null);
    }

    // Listen for auth state changes
    _ref.listen(authStateProvider, (previous, next) {
      next.whenData((authState) async {
        if (authState.event == AuthChangeEvent.signedIn &&
            authState.session?.user != null) {
          try {
            final profile =
                await authService.getProfile(authState.session!.user.id);
            state = AsyncValue.data(profile);
          } catch (e) {
            state = AsyncValue.error(e, StackTrace.current);
          }
        } else if (authState.event == AuthChangeEvent.signedOut) {
          state = const AsyncValue.data(null);
        }
      });
    });
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
        final profile = await authService.getProfile(user.id);
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
}
