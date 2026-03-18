import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
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
      footer: TextButton(
        onPressed: () {
          if (_requiresCurrentPassword) {
            context.go('/forgot-password');
          } else {
            Navigator.of(context).maybePop();
          }
        },
        child: Text(
          _requiresCurrentPassword
              ? 'Forgot your current password?'
              : 'Back to verification',
        ),
      ),
      child: GlassmorphicCard(
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
                  _FieldLabel(label: 'CURRENT PASSWORD'),
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
                _FieldLabel(label: 'CONFIRM PASSWORD'),
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
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
    );
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
