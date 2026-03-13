import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glassmorphic_card.dart';

/// Premium dark-themed login screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(currentUserProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please verify your email address first.';
    }
    if (error.contains('network')) {
      return 'Network error. Please check your connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background gradient orbs
          _buildBackgroundEffects(),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                    const SizedBox(height: 24),
                    _buildFooterLinks(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffects() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -80,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.fitness_center_rounded,
            size: 36,
            color: Colors.white,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1, 1),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 300.ms),

        const SizedBox(height: 24),

        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),

        const SizedBox(height: 8),

        Text(
          'Sign in to manage your gym',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ).animate(delay: 300.ms).fadeIn(),
      ],
    );
  }

  Widget _buildLoginForm() {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().shake(hz: 2, offset: const Offset(4, 0)),

              // Email field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  hintText: 'you@example.com',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: GoogleFonts.inter(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  hintText: '••••••••',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: AppColors.textMuted, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.bgInput,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Minimum 6 characters';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _showForgotPasswordDialog();
                  },
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign in button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0);
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController =
        TextEditingController(text: _emailController.text);
    bool isResetting = false;
    String? resetError;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.bgElevated,
              title: Text('Reset Password',
                  style: GoogleFonts.inter(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resetError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        resetError!,
                        style: GoogleFonts.inter(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  Text(
                    'Enter your email and we will send you a password reset link.',
                    style: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || (!email.contains('@'))) {
                            setDialogState(() =>
                                resetError = 'Please enter a valid email.');
                            return;
                          }

                          setDialogState(() {
                            isResetting = true;
                            resetError = null;
                          });

                          try {
                            await ref
                                .read(currentUserProvider.notifier)
                                .resetPassword(email);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Password reset link sent! Please check your email.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              resetError = _friendlyError(e.toString());
                              isResetting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: isResetting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Send Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Register your gym',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ).animate(delay: 600.ms).fadeIn();
  }
}
