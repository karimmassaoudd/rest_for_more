import 'package:go_router/go_router.dart';

import 'package:app_blocker/app_blocker.dart';

import './screens/focus_profiles_screen.dart';
import './screens/home_screen.dart';
import './screens/countdown_timer_screen.dart';
import './screens/placeholder_screen.dart';
import './widgets/app_nav_shell.dart';
import './screens/settings_screen.dart';
import './screens/focus_profile_detail_screen.dart';
import './screens/edit_blocked_apps_screen.dart';
import './screens/edit_always_available_apps_screen.dart';
import './screens/custom_time_screen.dart';

import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/countdown',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) => state.extra is BlockProfile ? null : '/',
      builder: (context, state) =>
          CountdownTimerPage(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/settings/focus-profiles',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const FocusProfilesScreen(),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          state.extra is BlockProfile ? null : '/settings/focus-profiles',
      builder: (context, state) =>
          FocusProfileDetailScreen(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail/blocked-apps',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          state.extra is BlockProfile ? null : '/settings/focus-profiles',
      builder: (context, state) =>
          EditBlockedAppsScreen(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail/always-available',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          state.extra is BlockProfile ? null : '/settings/focus-profiles',
      builder: (context, state) =>
          EditAlwaysAvailableAppsScreen(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/custom-time',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CustomTimePage(
        customPresets: (state.extra as List?)?.cast<int>() ?? const <int>[],
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppNavShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Progress'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Profile'),
            ),
          ],
        ),
      ],
    ),
  ],
);
