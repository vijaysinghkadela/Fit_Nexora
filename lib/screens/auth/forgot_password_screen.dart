import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fit_auth_scaffold.dart';
import '../../widgets/glassmorphic_card.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final email = _emailController.text.trim();
      await ref.read(currentUserProvider.notifier).resetPassword(email);
      if (!mounted) return;
      // Show success state instead of navigating immediately
      setState(() => _emailSent = true);
      // Navigate to OTP screen after a short delay so user sees the success state
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      context.go(_routeWithEmail('/verify-otp', email));
    } catch (error) {
      setState(() {
        _errorText = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _routeWithEmail(String path, String email) {
    return Uri(
      path: path,
      queryParameters: {'email': email},
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return _SuccessView(email: _emailController.text.trim());
    }

    final t = context.fitTheme;

    return FitAuthScaffold(
      title: 'Forgot password?',
      subtitle:
          'Enter your email and we will guide you through recovery.',
      heroIcon: Icons.lock_outline_rounded,
      heroLabel: 'Secure account recovery',
      showBack: true,
      footer: Column(
        children: [
          Text(
            'You will receive a recovery code based on your configured auth provider.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: t.textMuted),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Remember your password? Log in'),
          ),
        ],
      ),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error banner
                if (_errorText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: t.danger.withValues(alpha: 0.24)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: t.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorText!,
                            style: GoogleFonts.inter(
                              color: t.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(hz: 2, offset: const Offset(4, 0)),
                  const SizedBox(height: 16),
                ],
                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'name@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Submit button with gradient
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.brand, t.accent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: t.brand.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Send Reset Link',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.send_rounded, size: 17),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success state
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  final String email;

  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: t.background,
      body: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _GlowOrb(color: t.accent.withValues(alpha: 0.15), size: 300),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _GlowOrb(color: t.brand.withValues(alpha: 0.12), size: 280),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated checkmark container
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [t.accent, t.brand],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: t.accent.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(),
                    const SizedBox(height: 32),
                    Text(
                      'Email Sent!',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: t.textPrimary,
                        letterSpacing: -0.8,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 14),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: t.textSecondary,
                          height: 1.55,
                        ),
                        children: [
                          const TextSpan(
                              text:
                                  'We sent a recovery code to\n'),
                          TextSpan(
                            text: email.isEmpty ? 'your email address' : email,
                            style: TextStyle(
                              color: t.brand,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(
                              text:
                                  '.\nCheck your inbox and follow the instructions.'),
                        ],
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 350.ms),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          side: BorderSide(color: t.border, width: 1.4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => context.go('/login'),
                        icon: Icon(Icons.arrow_back_rounded,
                            color: t.textPrimary),
                        label: Text(
                          'Back to Login',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: t.textPrimary,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 350.ms)
                        .slideY(begin: 0.15, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
          ),
        ),
      ),
    );
  }
}
