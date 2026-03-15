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
        'global_role': role.value,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Sign up failed — no user returned');
    }

    // The DB trigger handle_new_user() already creates the profile row.
    // Wait briefly then fetch it so we return a fully-populated AppUser.
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return await getProfile(user.id);
    } catch (_) {
      // Profile row not ready yet — return a minimal AppUser from signup data.
      return AppUser(
        id: user.id,
        fullName: fullName,
        email: email,
        phone: phone,
        globalRole: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
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

  /// Verify the recovery OTP and establish a password recovery session.
  Future<void> verifyRecoveryOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.recovery,
      email: email,
      token: token,
    );
  }

  /// Update the password for the current recovery or signed-in session.
  Future<void> updatePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    if (currentPassword != null && currentPassword.isNotEmpty) {
      final email = _client.auth.currentUser?.email;
      if (email == null || email.isEmpty) {
        throw Exception('Unable to verify your current password. Please sign in again.');
      }

      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    }

    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
