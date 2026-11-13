import 'package:app_blocker/app_blocker.dart';
import 'package:go_router/go_router.dart';

import 'models/routines/routine_step.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/log_in_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/focus/countdown_timer_screen.dart';
import 'screens/focus/custom_time_screen.dart';
import 'screens/focus/edit_always_available_apps_screen.dart';
import 'screens/focus/edit_blocked_apps_screen.dart';
import 'screens/focus/focus_profile_detail_screen.dart';
import 'screens/focus/focus_profiles_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/cloud_save_screen.dart';
import 'screens/onboarding/language_screen.dart';
import 'screens/onboarding/questions_screen.dart';
import 'screens/onboarding/tutorial_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/routines/routine_editor.dart';
import 'screens/routines/routine_screen.dart';
import 'screens/settings/placeholder_screen.dart';
import 'screens/settings/routine_settings_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/onboarding/welcome_choice_store.dart';
import 'widgets/navigation/app_nav_shell.dart';

/// Onboarding and account screens. These are reachable before the user
/// has made a welcome choice; everything else redirects to Welcome.
const _onboardingPaths = {
  '/onboarding/language',
  '/welcome',
  '/sign-up',
  '/verify',
  '/log-in',
  '/onboarding/questions',
  '/onboarding/tutorial',
  '/onboarding/cloud',
};

/// Sends the user back to [fallback] when a screen that needs a
/// [BlockProfile] is opened without one (for example after a hot restart).
String? _requireProfile(GoRouterState state, String fallback) =>
    state.extra is BlockProfile ? null : fallback;

/// All app routes.
///
/// Top-level routes open full screen, above the bottom navigation bar.
/// The four tabs (Home, Progress, Settings, Profile) live in the shell
/// route at the bottom and each keep their own navigation stack.
final GoRouter router = GoRouter(
  // Until the user chose create account, log in or guest, every other
  // screen redirects to Welcome. Local check, so it works offline.
  redirect: (context, state) {
    if (!WelcomeChoiceStore.instance.hasChosen &&
        !_onboardingPaths.contains(state.matchedLocation)) {
      return '/welcome';
    }
    return null;
  },
  routes: [
    // ----- Onboarding and account -----
    GoRoute(
      path: '/onboarding/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/sign-up',
      builder: (context, state) => const CreateAccountScreen(),
    ),
    GoRoute(
      path: '/verify',
      redirect: (context, state) =>
          state.extra is VerifyArgs ? null : '/welcome',
      builder: (context, state) =>
          VerifyEmailScreen(args: state.extra as VerifyArgs),
    ),
    GoRoute(path: '/log-in', builder: (context, state) => const LogInScreen()),
    GoRoute(
      path: '/onboarding/questions',
      builder: (context, state) => const QuestionsScreen(),
    ),
    GoRoute(
      path: '/onboarding/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/manual',
      builder: (context, state) => const TutorialScreen(asManual: true),
    ),
    GoRoute(
      path: '/onboarding/cloud',
      builder: (context, state) => const CloudSaveScreen(),
    ),

    // ----- Focus -----
    GoRoute(
      path: '/countdown',
      redirect: (context, state) => _requireProfile(state, '/'),
      builder: (context, state) =>
          CountdownTimerPage(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/custom-time',
      builder: (context, state) => CustomTimePage(
        customPresets: (state.extra as List?)?.cast<int>() ?? const <int>[],
      ),
    ),
    GoRoute(
      path: '/settings/focus-profiles',
      builder: (context, state) => const FocusProfilesScreen(),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail',
      redirect: (context, state) =>
          _requireProfile(state, '/settings/focus-profiles'),
      builder: (context, state) =>
          FocusProfileDetailScreen(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail/blocked-apps',
      redirect: (context, state) =>
          _requireProfile(state, '/settings/focus-profiles'),
      builder: (context, state) =>
          EditBlockedAppsScreen(profile: state.extra as BlockProfile),
    ),
    GoRoute(
      path: '/settings/focus-profiles/detail/always-available',
      redirect: (context, state) =>
          _requireProfile(state, '/settings/focus-profiles'),
      builder: (context, state) =>
          EditAlwaysAvailableAppsScreen(profile: state.extra as BlockProfile),
    ),

    // ----- Routines -----
    GoRoute(
      path: '/routine/morning',
      builder: (context, state) =>
          const RoutineScreen(initialPeriod: RoutinePeriod.morning),
    ),
    GoRoute(
      path: '/routine/evening',
      builder: (context, state) =>
          const RoutineScreen(initialPeriod: RoutinePeriod.evening),
    ),
    GoRoute(
      path: '/settings/routines',
      builder: (context, state) => const RoutineSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/routines/evening',
      builder: (context, state) => const EveningPage(),
    ),

    // ----- Not built yet -----
    GoRoute(
      path: '/programme/intake',
      builder: (context, state) =>
          const PlaceholderScreen(title: '14-day plan'),
    ),

    // ----- Bottom navigation tabs -----
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
