import 'package:go_router/go_router.dart';

import 'package:app_blocker/app_blocker.dart';

import 'screens/focus/focus_profiles_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/focus/countdown_timer_screen.dart';
import 'screens/settings/placeholder_screen.dart';
import 'widgets/navigation/app_nav_shell.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/focus/focus_profile_detail_screen.dart';
import 'screens/focus/edit_blocked_apps_screen.dart';
import 'screens/focus/edit_always_available_apps_screen.dart';
import 'screens/focus/custom_time_screen.dart';
import 'screens/routines/routine_screen.dart';
import 'screens/routines/routine_editor.dart';
import 'models/routines/routine_step.dart';

import 'screens/profile/profile_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import './screens/auth/create_account_screen.dart';
import './screens/auth/verify_email_screen.dart';
import './screens/auth/log_in_screen.dart';
import 'services/onboarding/welcome_choice_store.dart';

import './screens/onboarding/language_screen.dart';
import './screens/onboarding/questions_screen.dart';
import './screens/onboarding/tutorial_screen.dart';
import './screens/onboarding/cloud_save_screen.dart';

import 'package:flutter/widgets.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Account screens (Sprint 4). Full-screen, no bottom navigation bar.
const _authPaths = {
  '/onboarding/language',
  '/welcome',
  '/sign-up',
  '/verify',
  '/log-in',
  '/onboarding/questions',
  '/onboarding/tutorial',
  '/onboarding/cloud',
};

final GoRouter router = GoRouter(
  navigatorKey: rootNavigatorKey,
  // REST-96: until the user chose create account / log in / guest,
  // every other screen redirects to Welcome. Local check, works offline.
  redirect: (context, state) {
    if (!WelcomeChoiceStore.instance.hasChosen &&
        !_authPaths.contains(state.matchedLocation)) {
      return '/welcome';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/onboarding/language',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/verify',
      parentNavigatorKey: rootNavigatorKey,
      redirect: (context, state) =>
          state.extra is VerifyArgs ? null : '/welcome',
      builder: (context, state) =>
          VerifyEmailScreen(args: state.extra as VerifyArgs),
    ),
    GoRoute(
      path: '/log-in',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LogInScreen(),
    ),
    GoRoute(
      path: '/onboarding/questions',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const QuestionsScreen(),
    ),
    GoRoute(
      path: '/onboarding/tutorial',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/onboarding/cloud',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CloudSaveScreen(),
    ),
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
    GoRoute(
      path: '/routine/morning',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          const RoutineScreen(initialPeriod: RoutinePeriod.morning),
    ),
    GoRoute(
      path: '/routine/evening',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          const RoutineScreen(initialPeriod: RoutinePeriod.evening),
    ),
    GoRoute(
      path: '/programme/intake',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) =>
          const PlaceholderScreen(title: '14-day plan'),
    ),
    GoRoute(
      path: '/settings/routines',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const EveningPage(),
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
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
