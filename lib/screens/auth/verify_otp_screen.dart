import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

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
    _controllers = List.generate(_digitCount, (_) => TextEditingController());
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
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

  String get _code => _controllers.map((controller) => controller.text).join();

  Future<void> _submit() async {
    if (_code.length != _digitCount) {
      _showMessage('Enter the 4-digit code to continue.');
      return;
    }

    final email = widget.initialEmail?.trim();
    if (email == null || email.isEmpty) {
      _showMessage('Start the recovery flow again so we know which account to verify.');
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      _showMessage('Start the recovery flow again so we know which account to verify.');
      return;
    }

    try {
      await ref.read(currentUserProvider.notifier).resetPassword(email);
      if (!mounted) return;
      _startTimer();
      _showMessage('A new recovery code has been requested.');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FitNexoraThemeTokens.dark();
    final email = (widget.initialEmail ?? '').trim();

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -90,
            child: _OtpGlow(color: colors.brand.withValues(alpha: 0.18), size: 260),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _OtpGlow(color: colors.brand.withValues(alpha: 0.12), size: 240),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Verify Code',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        height: 1.5,
                        color: colors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'We\'ve sent a 4-digit code to '),
                        TextSpan(
                          text: email.isEmpty ? 'your email address' : email,
                          style: TextStyle(
                            color: colors.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: List.generate(_digitCount, (index) {
                      final isFocused = _focusNodes[index].hasFocus;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index == _digitCount - 1 ? 0 : 12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isFocused ? colors.brand : Colors.transparent,
                                width: isFocused ? 2.2 : 1,
                              ),
                              boxShadow: [
                                if (isFocused)
                                  BoxShadow(
                                    color: colors.brand.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: Center(
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                autofocus: index == 0,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.inter(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2A2240),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  counterText: '',
                                  hintText: '-',
                                ),
                                onChanged: (value) => _handleChanged(value, index),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 26),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Didn\'t receive the code?',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _secondsRemaining == 0
                              ? _resendCode
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Resend Code',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _secondsRemaining == 0
                                      ? colors.brand
                                      : colors.brand.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.brand, colors.brandSecondary],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: colors.brand.withValues(alpha: 0.34),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Verify & Proceed',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: colors.brand,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'FitNexora',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PREMIUM FITNESS ECOSYSTEM',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: colors.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpGlow extends StatelessWidget {
  const _OtpGlow({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

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
