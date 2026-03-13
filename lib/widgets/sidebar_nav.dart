import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

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
    final width = isCollapsed ? 72.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo header
          _buildHeader(),
          const Divider(color: AppColors.divider, height: 1),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(items[index], index);
              },
            ),
          ),

          // User section
          const Divider(color: AppColors.divider, height: 1),
          _buildUserSection(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 16 : 20,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(width: 12),
            Text(
              'GymOS',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(SidebarItem item, int index) {
    final isSelected = index == selectedIndex;

    return Tooltip(
      message: isCollapsed ? item.label : '',
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onItemTap(index),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 16 : 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? const Border(
                        left: BorderSide(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 14),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
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

  Widget _buildUserSection() {
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 12 : 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                color: AppColors.primary,
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
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    userEmail,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.textMuted, size: 18),
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
