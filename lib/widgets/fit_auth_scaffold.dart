import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/extensions.dart';

class FitAuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final IconData heroIcon;
  final String heroLabel;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const FitAuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.heroIcon,
    this.heroLabel = 'Transformation starts here',
    this.footer,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned(
            top: -160,
            right: -110,
            child: _GlowOrb(color: colors.brand, size: 340),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _GlowOrb(color: colors.accent, size: 360),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      _buildHero(context),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 28),
                      child,
                      if (footer != null) ...[
                        const SizedBox(height: 24),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final colors = context.fitTheme;

    return Container(
      height: 284,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.backgroundAlt,
            colors.brand.withValues(alpha: 0.22),
            colors.backgroundAlt,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TopAction(
                  visible: showBack,
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 28,
            left: 28,
            right: 28,
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: colors.brandGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colors.glow.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Icon(heroIcon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(
                  'FitNexora',
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  heroLabel,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
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
            colors: [
              color.withValues(alpha: 0.18),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final bool visible;
  final IconData icon;
  final VoidCallback? onTap;

  const _TopAction({
    required this.visible,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.glassFill,
              shape: BoxShape.circle,
              border: Border.all(color: colors.glassBorder),
            ),
            child: Icon(icon, color: colors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}
