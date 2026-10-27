import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav_bar.dart';
import '../services/keep_timer_running.dart';

class AppNavShell extends StatefulWidget {
  const AppNavShell({super.key, required this.navigationShell});

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
      // Recalculate the timer after returning to the app.
      KeepRunningTimerClock.instance.refresh();
    }
  }

  void _onNavigationTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,

      // Always use the updated lava-lamp navigation bar.
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'app_bottom_nav_bar.dart';

// class AppNavShell extends StatelessWidget {
//   const AppNavShell({super.key, required this.navigationShell});

//   final StatefulNavigationShell navigationShell;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: navigationShell,
//       bottomNavigationBar: AppBottomNavBar(
//         currentIndex: navigationShell.currentIndex,
//         onTap: (i) => navigationShell.goBranch(
//           i,
//           initialLocation: i == navigationShell.currentIndex,
//         ),
//       ),
//     );
//   }
// }
