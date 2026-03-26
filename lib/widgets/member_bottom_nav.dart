// lib/widgets/member_bottom_nav.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import '../providers/performance_provider.dart';

const _tabs = [
  _Tab(label: 'Home', icon: Icons.home_rounded, route: '/member'),
  _Tab(
      label: 'Workouts',
      icon: Icons.fitness_center_rounded,
      route: '/member/workout'),
  _Tab(
      label: 'Nutrition',
      icon: Icons.restaurant_rounded,
      route: '/member/diet'),
  _Tab(
      label: 'Progress',
      icon: Icons.bar_chart_rounded,
      route: '/member/progress'),
  _Tab(label: 'Profile', icon: Icons.person_rounded, route: '/member/profile'),
];

class _Tab {
  final String label;
  final IconData icon;
  final String route;
  const _Tab({required this.label, required this.icon, required this.route});
}

class MemberBottomNav extends ConsumerWidget {
  final String? location;
  const MemberBottomNav({super.key, this.location});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.fitTheme;
    final isLowPerf = ref.watch(performanceProvider);
    final currentLocation =
        location ?? GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (currentLocation.startsWith(_tabs[i].route) &&
          (_tabs[i].route != '/member' || currentLocation == '/member')) {
        selectedIndex = i;
        break;
      }
    }

    Widget content = Container(
      decoration: BoxDecoration(
        color: isLowPerf ? t.surface : t.surface.withOpacity(0.85),
        border: Border(top: BorderSide(color: t.border, width: 0.5)),
        boxShadow: isLowPerf
            ? null
            : [
                BoxShadow(
                  color: t.glow.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == selectedIndex;
              final color = isActive ? t.brand : t.textMuted;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isActive
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          context.go(tab.route);
                        },
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive
                            ? t.brand.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: isActive ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            child: Icon(tab.icon, color: color, size: 22),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w400,
                              color: color,
                            ),
                            child: Text(tab.label),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );

    if (isLowPerf) return content;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}
