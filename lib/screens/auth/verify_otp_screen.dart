import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/fit_auth_scaffold.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _digitCount = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  bool _isLoading = false;
  int _secondsRemaining = 55;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(_digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
    // Rebuild on focus change to animate box borders
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 55;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  String get _code =>
      _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_code.length != _digitCount) {
      _showMessage('Enter the 4-digit code to continue.');
      return;
    }

    final email = widget.initialEmail?.trim();
    if (email == null || email.isEmpty) {
      _showMessage(
          'Start the recovery flow again so we know which account to verify.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).verifyRecoveryOtp(
            email: email,
            token: _code,
          );
      if (!mounted) return;
      context.go(
        Uri(
          path: '/change-password',
          queryParameters: {'email': email},
        ).toString(),
      );
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleChanged(String value, int index) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < _digitCount; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      if (digits.length >= _digitCount) {
        _focusNodes.last.unfocus();
      } else {
        _focusNodes[digits.length].requestFocus();
      }
      setState(() {});
      return;
    }

    if (value.isNotEmpty && index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('Token has expired')) {
      return 'This recovery code has expired. Request a new one and try again.';
    }
    if (message.contains('Invalid token') || message.contains('invalid')) {
      return 'That recovery code is invalid. Please check the code and try again.';
    }
    return message;
  }

  Future<void> _resendCode() async {
    final email = widget.initialEmail?.trim();
    if (email == null || email.isEmpty) {
      _showMessage(
          'Start the recovery flow again so we know which account to verify.');
      return;
    }

    try {
      await ref.read(currentUserProvider.notifier).resetPassword(email);
      if (!mounted) return;
      _startTimer();
      _showMessage('A new recovery code has been sent.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;
    final email = (widget.initialEmail ?? '').trim();
    final timerExpired = _secondsRemaining == 0;

    return FitAuthScaffold(
      title: 'Verify Code',
      subtitle: 'Enter the 4-digit code sent to your email.',
      heroIcon: Icons.lock_outline_rounded,
      heroLabel: 'Secure account recovery',
      showBack: true,
      child: Column(
        children: [
          // Email confirmation chip
          if (email.isNotEmpty) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: t.brand.withOpacity(0.10),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: t.brand.withOpacity(0.22)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline_rounded,
                      color: t.brand, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: t.brand,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
          ],

          // OTP boxes
          Row(
            children: List.generate(_digitCount, (index) {
              final isFocused = _focusNodes[index].hasFocus;
              final isFilled = _controllers[index].text.isNotEmpty;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: index == _digitCount - 1 ? 0 : 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 80,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? t.brand.withOpacity(0.10)
                          : t.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isFocused
                            ? t.brand
                            : isFilled
                                ? t.brand.withOpacity(0.45)
                                : t.border,
                        width: isFocused ? 2 : 1.2,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: t.brand.withOpacity(0.22),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        autofocus: index == 0,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isFilled ? t.brand : t.textPrimary,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          hintText: '–',
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _handleChanged(value, index),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 28),

          // Timer + resend
          Column(
            children: [
              // Countdown display
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: timerExpired
                    ? const SizedBox.shrink()
                    : Container(
                        key: const ValueKey('timer'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: t.surfaceAlt,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: t.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined,
                                size: 15, color: t.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: GoogleFonts.inter(
                        fontSize: 14, color: t.textSecondary),
                  ),
                  TextButton(
                    onPressed: timerExpired ? _resendCode : null,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          timerExpired ? t.brand : t.textMuted,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: timerExpired ? t.brand : t.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 28),

          // Verify button with gradient
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
                    color: t.brand.withOpacity(0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
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
                            strokeWidth: 2.2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Verify & Proceed',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}
