// lib/screens/gym/qr_checkin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../core/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/traffic_provider.dart';

class QrCheckinScreen extends ConsumerStatefulWidget {
  final bool isCheckOut;
  final String? checkInId;

  const QrCheckinScreen({
    super.key,
    this.isCheckOut = false,
    this.checkInId,
  });

  @override
  ConsumerState<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends ConsumerState<QrCheckinScreen> {
  final _controller = MobileScannerController();
  bool _scanned = false;
  bool _success = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // Validate gym_id format — expect a UUID
    final uuidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (!uuidPattern.hasMatch(raw)) {
      setState(() {
        _scanned = true;
        _success = false;
        _errorMessage = 'Invalid QR code. Please scan a FitNexora gym QR.';
      });
      return;
    }

    setState(() => _scanned = true);

    try {
      final userId = ref.read(currentUserProvider).value?.id;
      if (userId == null) throw Exception('Not logged in');

      final db = ref.read(databaseServiceProvider);
      if (widget.isCheckOut) {
        if (widget.checkInId == null) throw Exception('No active check-in ID found');
        await db.checkOutFromGym(widget.checkInId!);
      } else {
        await Supabase.instance.client.from('gym_checkins').insert({
          'gym_id': raw,
          'user_id': userId,
          'checked_in_at': DateTime.now().toIso8601String(),
        });
      }

      ref.invalidate(activeCheckInProvider((raw, userId)));

      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _success = false;
          _errorMessage = '${widget.isCheckOut ? 'Check-out' : 'Check-in'} failed. Try again.';
        });
      }
    }
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _success = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          if (!_scanned)
            MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),

          // Overlay frame
          if (!_scanned) _ScanOverlay(t: t),

          // AppBar overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Text(
                      widget.isCheckOut ? 'Gym Check-Out' : 'Gym Check-In',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.flash_on_rounded,
                          color: Colors.white),
                      onPressed: () => _controller.toggleTorch(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Result overlay
          if (_scanned)
            Container(
              color: t.background,
              child: Center(
                child: _success
                    ? _SuccessView(t: t, isCheckOut: widget.isCheckOut)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8))
                    : _ErrorView(
                        message: _errorMessage ?? 'Unknown error',
                        onRetry: _reset,
                        t: t,
                      ).animate().fadeIn(duration: 300.ms),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Scan overlay frame ───────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final FitNexoraThemeTokens t;
  const _ScanOverlay({required this.t});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: t.brand, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Point camera at gym QR code',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Success view ─────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final FitNexoraThemeTokens t;
  final bool isCheckOut;
  const _SuccessView({required this.t, required this.isCheckOut});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.success.withOpacity(0.15),
            border: Border.all(color: t.success, width: 2),
          ),
          child: Icon(Icons.check_rounded, size: 56, color: t.success),
        ),
        const SizedBox(height: 24),
        Text(
          isCheckOut ? 'Checked Out!' : 'Checked In!',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isCheckOut ? 'Workout complete. See you next time!' : 'Welcome to the gym. Have a great workout!',
          style: GoogleFonts.inter(fontSize: 15, color: t.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: t.brand,
            foregroundColor: t.textPrimary,
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.of(context).maybePop(),
          child: Text(
            'Done',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final FitNexoraThemeTokens t;

  const _ErrorView(
      {required this.message, required this.onRetry, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.danger.withOpacity(0.15),
            border: Border.all(color: t.danger, width: 2),
          ),
          child: Icon(Icons.close_rounded, size: 56, color: t.danger),
        ),
        const SizedBox(height: 24),
        Text(
          'Check-In Failed',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            message,
            style: GoogleFonts.inter(fontSize: 14, color: t.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: t.textSecondary,
                side: BorderSide(color: t.border),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.brand,
                foregroundColor: t.textPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ],
    );
  }
}
