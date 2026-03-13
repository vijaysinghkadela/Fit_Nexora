import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/enums.dart';

/// Wraps Supabase Auth with app-specific logic.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Current Supabase user (raw auth).
  User? get currentUser => _client.auth.currentUser;

  /// Whether user is signed in.
  bool get isSignedIn => currentUser != null;

  /// Auth state stream.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up with email + password and create profile.
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    UserRole role = UserRole.gymOwner,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'phone': phone,
      },
    );

    if (response.user == null) {
      throw Exception('Sign up failed — no user returned');
    }

    // Create profile in profiles table
    final profile = {
      'id': response.user!.id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'global_role': role.value,
    };

    await _client.from(AppConstants.profilesTable).upsert(profile);

    return AppUser(
      id: response.user!.id,
      fullName: fullName,
      email: email,
      phone: phone,
      globalRole: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Sign in with email + password.
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Sign in failed — invalid credentials');
    }

    return getProfile(response.user!.id);
  }

  /// Sign in with Google OAuth.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'com.gymos.app://login-callback',
    );
  }

  /// Get user profile from the profiles table.
  Future<AppUser> getProfile(String userId) async {
    final data = await _client
        .from(AppConstants.profilesTable)
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromJson(data);
  }

  /// Update user profile.
  Future<AppUser> updateProfile(AppUser user) async {
    await _client
        .from(AppConstants.profilesTable)
        .update(user.toJson())
        .eq('id', user.id);

    return user;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Reset password.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
