import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav_bar.dart';

/// The frame around the four main tabs: the current tab's page with the
/// bottom navigation bar under it.
class AppNavShell extends StatelessWidget {
  const AppNavShell({super.key, required this.navigationShell});

  /// From go_router: the tab pages and which one is shown.
  final StatefulNavigationShell navigationShell;

  /// Switches tab; tapping the current tab again goes back to its first page.
  void _onNavigationTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets the page show through the cut-out above the nav bar's curve.
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
