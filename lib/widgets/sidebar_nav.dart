import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/extensions.dart';

/// Sidebar item data.
class SidebarItem {
  final IconData icon;
  final String label;
  const SidebarItem({required this.icon, required this.label});
}

/// Desktop sidebar navigation.
class SidebarNav extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final bool isCollapsed;
  final String userName;
  final String userEmail;
  final VoidCallback onSignOut;

  const SidebarNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
    this.isCollapsed = false,
    required this.userName,
    required this.userEmail,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.fitTheme;
    final width = isCollapsed ? 78.0 : 272.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          right: BorderSide(color: colors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.glow.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(12, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Divider(color: colors.divider, height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(context, items[index], index);
              },
            ),
          ),
          Divider(color: colors.divider, height: 1),
          _buildUserSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.fitTheme;
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 18 : 22),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: colors.brandGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: colors.glow.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'FitNexora',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, SidebarItem item, int index) {
    final colors = context.fitTheme;
    final isSelected = index == selectedIndex;

    return Tooltip(
      message: isCollapsed ? item.label : '',
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemTap(index),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 18 : 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.brand.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colors.brand.withOpacity(0.24)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 21,
                    color: isSelected ? colors.brand : colors.textMuted,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected ? colors.brand : colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final colors = context.fitTheme;
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 12 : 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.brand.withOpacity(0.18),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                color: colors.brand,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: colors.textMuted,
                size: 18,
              ),
              onPressed: onSignOut,
              tooltip: 'Sign out',
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
