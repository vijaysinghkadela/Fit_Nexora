import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/extensions.dart';
import 'sidebar_nav.dart';

class FitShellDestination {
  final IconData icon;
  final String label;
  final String route;

  const FitShellDestination({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class FitShellCenterAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FitShellCenterAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Shared scaffold for owner and trainer management surfaces.
class FitManagementScaffold extends StatelessWidget {
  const FitManagementScaffold({
    super.key,
    required this.currentRoute,
    required this.destinations,
    required this.userName,
    required this.userEmail,
    required this.child,
    this.mobileDestinations,
    this.centerAction,
    this.onSignOut,
  });

  final String currentRoute;
  final List<FitShellDestination> destinations;
  final List<FitShellDestination>? mobileDestinations;
  final String userName;
  final String userEmail;
  final Widget child;
  final FitShellCenterAction? centerAction;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final useSidebar = context.isTablet || context.isDesktop;

    return Scaffold(
      backgroundColor: colors.background,
      extendBody: !useSidebar,
      bottomNavigationBar: useSidebar
          ? null
          : _FitMobileNavigationBar(
              currentRoute: currentRoute,
              destinations: mobileDestinations ?? destinations.take(4).toList(),
              centerAction: centerAction,
            ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.backgroundAlt.withValues(alpha: 0.9),
              colors.background,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -140,
              left: -60,
              child: _GlowOrb(
                color: colors.brand.withValues(alpha: 0.16),
                size: 300,
              ),
            ),
            Positioned(
              top: 180,
              right: -110,
              child: _GlowOrb(
                color: colors.accent.withValues(alpha: 0.09),
                size: 260,
              ),
            ),
            SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (useSidebar)
                    SidebarNav(
                      items: destinations
                          .map(
                            (destination) => SidebarItem(
                              icon: destination.icon,
                              label: destination.label,
                            ),
                          )
                          .toList(),
                      selectedIndex: _selectedIndex(destinations),
                      onItemTap: (index) => _goTo(context, destinations[index]),
                      isCollapsed: context.isTablet && !context.isDesktop,
                      userName: userName,
                      userEmail: userEmail,
                      onSignOut: onSignOut ?? () {},
                    ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex(List<FitShellDestination> items) {
    final index =
        items.indexWhere((item) => _routeMatches(item.route, currentRoute));
    return index < 0 ? 0 : index;
  }

  void _goTo(BuildContext context, FitShellDestination destination) {
    if (_routeMatches(destination.route, currentRoute)) return;
    context.go(destination.route);
  }

  bool _routeMatches(String route, String activeRoute) {
    return activeRoute == route || activeRoute.startsWith('$route/');
  }
}

class _FitMobileNavigationBar extends StatelessWidget {
  const _FitMobileNavigationBar({
    required this.currentRoute,
    required this.destinations,
    this.centerAction,
  });

  final String currentRoute;
  final List<FitShellDestination> destinations;
  final FitShellCenterAction? centerAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final tabs = destinations.take(4).toList();
    final hasCenterAction = centerAction != null && tabs.length == 4;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: colors.border)),
        boxShadow: [
          BoxShadow(
            color: colors.background.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + MediaQuery.paddingOf(context).bottom),
      child: hasCenterAction
          ? Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FitMobileNavItem(
                        destination: tabs[0],
                        isSelected: _routeMatches(tabs[0].route, currentRoute),
                      ),
                      _FitMobileNavItem(
                        destination: tabs[1],
                        isSelected: _routeMatches(tabs[1].route, currentRoute),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _CenterActionButton(action: centerAction!),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FitMobileNavItem(
                        destination: tabs[2],
                        isSelected: _routeMatches(tabs[2].route, currentRoute),
                      ),
                      _FitMobileNavItem(
                        destination: tabs[3],
                        isSelected: _routeMatches(tabs[3].route, currentRoute),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: tabs
                  .map(
                    (tab) => _FitMobileNavItem(
                      destination: tab,
                      isSelected: _routeMatches(tab.route, currentRoute),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  bool _routeMatches(String route, String activeRoute) {
    return activeRoute == route || activeRoute.startsWith('$route/');
  }
}

class _FitMobileNavItem extends StatelessWidget {
  const _FitMobileNavItem({
    required this.destination,
    required this.isSelected,
  });

  final FitShellDestination destination;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return InkWell(
      onTap: () => context.go(destination.route),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              destination.icon,
              size: 20,
              color: isSelected ? colors.brand : colors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.brand : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({required this.action});

  final FitShellCenterAction action;

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;

    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: colors.brandGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.glow.withValues(alpha: 0.34),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(action.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            action.label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
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
