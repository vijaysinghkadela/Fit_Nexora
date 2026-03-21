import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/biometric_provider.dart';
import '../../widgets/fit_auth_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _biometricLoading = false;
  String? _errorText;

  bool get _requiresCurrentPassword => widget.initialEmail == null;

  @override
  void dispose() {
    _currentController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref
          .read(currentUserProvider.notifier)
          .updatePassword(
            _passwordController.text.trim(),
            currentPassword:
                _requiresCurrentPassword ? _currentController.text : null,
          );
      if (!mounted) return;
      context.go('/password-updated');
    } catch (error) {
      setState(() {
        _errorText = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final newPassword = _passwordController.text;
    final checks = [
      _PasswordCheck(
        label: 'At least 8 characters',
        passed: newPassword.length >= 8,
      ),
      _PasswordCheck(
        label: 'Contains one special character',
        passed: RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(newPassword),
      ),
      _PasswordCheck(
        label: 'Contains one uppercase letter',
        passed: RegExp(r'[A-Z]').hasMatch(newPassword),
      ),
    ];

    return FitAuthScaffold(
      title: _requiresCurrentPassword ? 'Change Password' : 'Create a new password',
      subtitle: _requiresCurrentPassword
          ? 'Update your password to keep your FitNexora profile and health data secure.'
          : 'Choose a strong password for your FitNexora account and keep your recovery flow secure.',
      heroIcon: _requiresCurrentPassword
          ? Icons.shield_moon_outlined
          : Icons.lock_reset_rounded,
      heroLabel: _requiresCurrentPassword ? 'Security settings' : 'Recovery secure',
      showBack: true,
      onBack: () {
        if (_requiresCurrentPassword) {
          context.go('/settings');
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/login');
          }
        }
      },
      footer: TextButton(
        onPressed: () {
          if (_requiresCurrentPassword) {
            context.go('/forgot-password');
          } else {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          }
        },
        child: Text(
          _requiresCurrentPassword
              ? 'Forgot your current password?'
              : 'Back to verification',
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassmorphicCard(
            borderRadius: 28,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.danger.withOpacity(0.24),
                          ),
                        ),
                        child: Text(
                          _errorText!,
                          style: GoogleFonts.inter(
                            color: colors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_requiresCurrentPassword) ...[
                      const _FieldLabel(label: 'CURRENT PASSWORD'),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _currentController,
                        obscureText: _obscureCurrent,
                        decoration: InputDecoration(
                          hintText: 'Enter current password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscureCurrent = !_obscureCurrent);
                            },
                            icon: Icon(
                              _obscureCurrent
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (_requiresCurrentPassword &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Current password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    _FieldLabel(
                      label: _requiresCurrentPassword ? 'NEW PASSWORD' : 'CREATE PASSWORD',
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        prefixIcon: const Icon(Icons.lock_open_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Column(
                      children: checks
                          .map((check) => _PasswordCheckRow(check: check))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel(label: 'CONFIRM PASSWORD'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-type new password',
                        prefixIcon: const Icon(Icons.verified_user_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: colors.accent,
                        foregroundColor: const Color(0xFF062218),
                        textStyle: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Color(0xFF062218),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Update Password'),
                                SizedBox(width: 8),
                                Icon(Icons.lock_reset_rounded),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Biometric Fingerprint Setup ──────────────────────────────────
          if (_requiresCurrentPassword) ...[
            const SizedBox(height: 24),
            _BiometricSetupCard(
              isLoading: _biometricLoading,
              onToggle: _handleBiometricToggle,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleBiometricToggle(bool enable) async {
    final bioService = ref.read(biometricServiceProvider);

    setState(() => _biometricLoading = true);

    try {
      if (enable) {
        // Step 1: Check device capability
        final available = await bioService.isAvailable();
        if (!available) {
          if (mounted) {
            context.showSnackBar(
              'Biometric hardware not available on this device',
              isError: true,
            );
          }
          return;
        }

        // Step 2: Trigger OS fingerprint prompt
        final authenticated = await bioService.authenticate(
          reason: 'Scan your fingerprint to set up biometric login',
        );
        if (!authenticated) {
          if (mounted) {
            context.showSnackBar(
              'Fingerprint authentication failed',
              isError: true,
            );
          }
          return;
        }

        // Step 3: Prompt for credentials to store
        if (!mounted) return;
        final credentials = await _showCredentialDialog();
        if (credentials == null) return;

        // Step 4: Save credentials
        await bioService.saveCredentials(
          email: credentials.email,
          password: credentials.password,
        );

        // Refresh providers
        ref.invalidate(biometricEnabledProvider);
        ref.invalidate(canBiometricLoginProvider);

        if (mounted) {
          context.showSnackBar('Fingerprint login enabled successfully!');
        }
      } else {
        // Disable: clear credentials
        await bioService.clearCredentials();
        ref.invalidate(biometricEnabledProvider);
        ref.invalidate(canBiometricLoginProvider);

        if (mounted) {
          context.showSnackBar('Fingerprint login disabled');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _biometricLoading = false);
    }
  }

  Future<({String email, String password})?> _showCredentialDialog() async {
    final colors = context.fitTheme;
    final user = ref.read(currentUserProvider).value;
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final passCtrl = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool obscure = true;

    final result = await showDialog<({String email, String password})?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: colors.border),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: colors.brandGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Save Login Credentials',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your credentials to enable fingerprint sign-in. These will be securely stored on your device.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: emailCtrl,
                      style: GoogleFonts.inter(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: GoogleFonts.inter(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.email_rounded, color: colors.brand),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: colors.brand, width: 2),
                        ),
                        filled: true,
                        fillColor: colors.surfaceMuted,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: obscure,
                      style: GoogleFonts.inter(color: colors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: GoogleFonts.inter(color: colors.textMuted),
                        prefixIcon:
                            Icon(Icons.lock_rounded, color: colors.brand),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() => obscure = !obscure);
                          },
                          icon: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colors.textMuted,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: colors.brand, width: 2),
                        ),
                        filled: true,
                        fillColor: colors.surfaceMuted,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (!dialogFormKey.currentState!.validate()) return;
                    Navigator.of(ctx).pop((
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text,
                    ));
                  },
                  child: Text(
                    'Save & Enable',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    emailCtrl.dispose();
    passCtrl.dispose();
    return result;
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('Invalid login credentials')) {
      return 'Current password is incorrect.';
    }
    return message;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: colors.textMuted,
      ),
    );
  }
}

class _PasswordCheck {
  const _PasswordCheck({
    required this.label,
    required this.passed,
  });

  final String label;
  final bool passed;
}

class _PasswordCheckRow extends StatelessWidget {
  const _PasswordCheckRow({required this.check});

  final _PasswordCheck check;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final activeColor = check.passed ? colors.accent : colors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            check.passed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: activeColor,
          ),
          const SizedBox(width: 8),
          Text(
            check.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: check.passed ? colors.textPrimary : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Biometric Setup Card ──────────────────────────────────────────────────────

class _BiometricSetupCard extends ConsumerWidget {
  const _BiometricSetupCard({
    required this.isLoading,
    required this.onToggle,
  });

  final bool isLoading;
  final Future<void> Function(bool enable) onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.fitTheme;
    final bioAvailable = ref.watch(biometricAvailableProvider);
    final bioEnabled = ref.watch(biometricEnabledProvider);

    final isAvailable = bioAvailable.valueOrNull ?? false;
    final isEnabled = bioEnabled.valueOrNull ?? false;

    return GlassmorphicCard(
      borderRadius: 28,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isEnabled
                        ? colors.brandGradient
                        : LinearGradient(
                            colors: [
                              colors.surfaceMuted,
                              colors.surfaceMuted,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isEnabled
                        ? [
                            BoxShadow(
                              color: colors.glow.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.fingerprint_rounded,
                    size: 26,
                    color: isEnabled ? Colors.white : colors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fingerprint Login',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEnabled
                            ? 'Biometric sign-in active'
                            : isAvailable
                                ? 'Use fingerprint to sign in'
                                : 'Not available on this device',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isEnabled
                              ? colors.accent
                              : colors.textSecondary,
                          fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colors.brand,
                    ),
                  )
                else
                  Switch.adaptive(
                    value: isEnabled,
                    activeColor: colors.brand,
                    onChanged: isAvailable
                        ? (val) => onToggle(val)
                        : null,
                  ),
              ],
            ),
            if (isEnabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colors.accent.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Biometric credentials stored securely on this device',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isAvailable) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.textMuted.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No biometric hardware detected or no fingerprints enrolled',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
