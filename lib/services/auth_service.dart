import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
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
    String? gymId,
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

    if (gymId != null && gymId.isNotEmpty) {
      try {
        final memberRole = role == UserRole.gymOwner ? 'owner' : role.value;
        await _client.from(AppConstants.gymMembersTable).insert({
          'gym_id': gymId,
          'user_id': user.id,
          'role': memberRole,
        });

        if (role == UserRole.client) {
          await _client.from(AppConstants.clientsTable).insert({
            'gym_id': gymId,
            'user_id': user.id,
            'full_name': fullName,
            'email': email,
            'phone': phone,
          });
        }
      } catch (e) {
        debugPrint('Failed to link user to gym: $e');
      }
    }

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

  /// Sign in with Google OAuth (native — uses GoogleSignIn package).
  ///
  /// On Android & iOS this shows the native Google account picker, then
  /// exchanges the Google ID token for a Supabase session via signInWithIdToken.
  Future<void> signInWithGoogle() async {
    final webClientId = AppConfig.googleWebClientId;

    final GoogleSignIn googleSignIn = GoogleSignIn(
      // The server client ID (Web) lets Supabase verify the token.
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // The user cancelled the picker.
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Google sign-in failed — no ID token received.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    // The authStateProvider listener in auth_provider.dart picks up the
    // new session and loads the user profile automatically.
  }

  /// Disconnect Google account — call this alongside Supabase sign-out so
  /// the account picker appears on the next Google sign-in instead of auto-selecting.
  Future<void> signOutGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google sign-out error (non-fatal): $e');
    }
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

  /// Sign out (email/password and Google).
  Future<void> signOut() async {
    await signOutGoogle();
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
