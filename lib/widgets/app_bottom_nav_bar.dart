import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppNavItem {
  final IconData icon;
  final String label; // used for accessibility only
  const AppNavItem({required this.icon, required this.label});
}

/// The four tabs, in order.
const List<AppNavItem> kAppNavItems = [
  AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
  AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
  AppNavItem(icon: Icons.tune, label: 'Settings'),
  AppNavItem(icon: Icons.person_outline, label: 'Profile'),
];

/// The floating pill-shaped navigation bar.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 66,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.surface, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkbrown.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (int i = 0; i < kAppNavItems.length; i++)
                Expanded(child: _buildItem(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final selected = index == currentIndex;
    final item = kAppNavItems[index];

    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.mediumbrown : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Icon(
            item.icon,
            size: 24,
            color: selected ? AppColors.background : AppColors.mediumbrown,
          ),
        ),
      ),
    );
  }
}
