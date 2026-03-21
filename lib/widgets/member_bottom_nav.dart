// lib/widgets/member_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';

const _tabs = [
  _Tab(label: 'Home', icon: Icons.home_rounded, route: '/member'),
  _Tab(label: 'Workouts', icon: Icons.fitness_center_rounded, route: '/member/workout'),
  _Tab(label: 'Nutrition', icon: Icons.restaurant_rounded, route: '/member/diet'),
  _Tab(label: 'Progress', icon: Icons.bar_chart_rounded, route: '/member/progress'),
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
    final currentLocation = location ?? GoRouterState.of(context).matchedLocation;

    int selectedIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (currentLocation.startsWith(_tabs[i].route) &&
          (_tabs[i].route != '/member' || currentLocation == '/member')) {
        selectedIndex = i;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isActive = i == selectedIndex;
              final color = isActive ? t.brand : t.textMuted;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!isActive) context.go(tab.route);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(tab.icon, color: color, size: 24),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tab.label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
