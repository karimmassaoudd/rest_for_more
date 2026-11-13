import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/focus/keep_timer_running.dart';
import 'app_bottom_nav_bar.dart';

/// The frame around the four main tabs: the current tab's page with the
/// bottom navigation bar under it.
///
/// Also keeps the app-wide session clock up to date: restored when the
/// app starts, recalculated when it comes back to the foreground.
class AppNavShell extends StatefulWidget {
  const AppNavShell({super.key, required this.navigationShell});

  /// From go_router: the tab pages and which one is shown.
  final StatefulNavigationShell navigationShell;

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Restore the saved timer after a complete app restart.
    KeepRunningTimerClock.instance.restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate the time left after the app was in the background.
      KeepRunningTimerClock.instance.refresh();
    }
  }

  /// Switches tab; tapping the current tab again goes back to its first page.
  void _onNavigationTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets the page show through the cut-out above the nav bar's curve.
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}
