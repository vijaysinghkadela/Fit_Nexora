import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/extensions.dart';
import '../../config/theme.dart';
import '../../widgets/glassmorphic_card.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _scanned = false;
  bool _isScanning = false;

  // Simulated food result
  final _foodResult = const _FoodResult(
    name: 'Amul Gold Full Cream Milk',
    brand: 'Amul',
    calories: 67,
    protein: 3.2,
    carbs: 4.9,
    fat: 3.8,
    servingSize: '100ml',
  );

  void _simulateScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _isScanning = false;
        _scanned = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fitTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated camera background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A12),
                    const Color(0xFF050508),
                  ],
                ),
              ),
            ),
          ),

          // Viewfinder area
          if (!_scanned)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  _ViewfinderBox(
                    isScanning: _isScanning,
                    accentColor: t.accent,
                    brandColor: t.brand,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isScanning
                        ? 'Scanning barcode…'
                        : 'Point camera at barcode',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ).animate(key: ValueKey(_isScanning)).fadeIn(duration: 300.ms),
                  const SizedBox(height: 8),
                  Text(
                    'Align the barcode within the frame',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),

          // Food result card
          if (_scanned)
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 120),
                child: _FoodResultCard(
                  result: _foodResult,
                  themeTokens: t,
                  onAddToLog: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${_foodResult.name} added to log',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: t.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onScanAgain: () => setState(() => _scanned = false),
                ),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                    color: Colors.white,
                    bgColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  const Spacer(),
                  Text(
                    'Scan Barcode',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.flashlight_on_rounded,
                    onTap: () {},
                    color: Colors.white,
                    bgColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_scanned) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isScanning ? null : _simulateScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.brand,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                t.brand.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isScanning
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Simulate Scan',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.edit_rounded,
                            size: 16, color: t.textSecondary),
                        label: Text(
                          'Enter food manually instead',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                    ],
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

// ── Viewfinder ──────────────────────────────────────────────────────────────

class _ViewfinderBox extends StatelessWidget {
  final bool isScanning;
  final Color accentColor;
  final Color brandColor;

  const _ViewfinderBox({
    required this.isScanning,
    required this.accentColor,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Dark overlay with cutout effect
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // Corner brackets
          ..._buildCorners(size, isScanning ? accentColor : brandColor),

          // Scan line
          if (isScanning)
            _ScanLine(color: accentColor, size: size),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(double size, Color color) {
    const cornerSize = 28.0;
    const thickness = 3.5;
    const radius = 4.0;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(
          color: color,
          size: cornerSize,
          thickness: thickness,
          radius: radius,
          top: true,
          left: true,
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(
          color: color,
          size: cornerSize,
          thickness: thickness,
          radius: radius,
          top: true,
          left: false,
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(
          color: color,
          size: cornerSize,
          thickness: thickness,
          radius: radius,
          top: false,
          left: true,
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(
          color: color,
          size: cornerSize,
          thickness: thickness,
          radius: radius,
          top: false,
          left: false,
        ),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final double size;
  final double thickness;
  final double radius;
  final bool top;
  final bool left;

  const _Corner({
    required this.color,
    required this.size,
    required this.thickness,
    required this.radius,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CornerPainter(
        color: color,
        thickness: thickness,
        radius: radius,
        top: top,
        left: left,
      )),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final double radius;
  final bool top;
  final bool left;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.radius,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, radius), paint);
      canvas.drawLine(Offset(radius, 0), Offset(w, 0), paint);
      canvas.drawArc(
        Rect.fromLTWH(0, 0, radius * 2, radius * 2),
        3.14159,
        3.14159 / 2,
        false,
        paint,
      );
    } else if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w - radius, 0), paint);
      canvas.drawLine(Offset(w, radius), Offset(w, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - radius * 2, 0, radius * 2, radius * 2),
        -3.14159 / 2,
        3.14159 / 2,
        false,
        paint,
      );
    } else if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h - radius), paint);
      canvas.drawLine(Offset(radius, h), Offset(w, h), paint);
      canvas.drawArc(
        Rect.fromLTWH(0, h - radius * 2, radius * 2, radius * 2),
        3.14159 / 2,
        3.14159 / 2,
        false,
        paint,
      );
    } else {
      canvas.drawLine(Offset(0, h), Offset(w - radius, h), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h - radius), paint);
      canvas.drawArc(
        Rect.fromLTWH(w - radius * 2, h - radius * 2, radius * 2, radius * 2),
        0,
        3.14159 / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

class _ScanLine extends StatelessWidget {
  final Color color;
  final double size;

  const _ScanLine({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        final yPos = value * (size - 4);
        return Positioned(
          top: yPos,
          left: 8,
          right: 8,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0),
                  color,
                  color.withValues(alpha: 0),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }
}

// ── Food Result Card ─────────────────────────────────────────────────────────

class _FoodResultCard extends StatelessWidget {
  final _FoodResult result;
  final FitNexoraThemeTokens themeTokens;
  final VoidCallback onAddToLog;
  final VoidCallback onScanAgain;

  const _FoodResultCard({
    required this.result,
    required this.themeTokens,
    required this.onAddToLog,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final t = themeTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barcode Scanned',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.accent,
            letterSpacing: 0.5,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: t.brand.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restaurant_rounded,
                          color: t.brand, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${result.brand} · ${result.servingSize}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${result.calories} kcal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: t.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _MacroChip(
                      label: 'Protein',
                      value: '${result.protein}g',
                      color: t.info,
                    ),
                    const SizedBox(width: 10),
                    _MacroChip(
                      label: 'Carbs',
                      value: '${result.carbs}g',
                      color: t.warning,
                    ),
                    const SizedBox(width: 10),
                    _MacroChip(
                      label: 'Fat',
                      value: '${result.fat}g',
                      color: t.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onScanAgain,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: t.textSecondary,
                          side: BorderSide(color: t.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Scan Again',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onAddToLog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: t.accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add to Log',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
        const SizedBox(height: 16),
        GlassmorphicCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: t.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nutritional data per ${result.servingSize}. '
                    'Adjust serving size before adding.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 350.ms),
      ],
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: color.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color bgColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _FoodResult {
  final String name;
  final String brand;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;

  const _FoodResult({
    required this.name,
    required this.brand,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
  });
}
