import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'router.dart';
import 'services/auth/auth_service.dart';
import 'services/focus/active_focus_profile.dart';
import 'services/focus/focus_notification_navigation.dart';
import 'services/focus/profile_bootstrap.dart';
import 'services/focus/timer_notification_service.dart';
import 'services/onboarding/welcome_choice_store.dart';
import 'services/settings/locale_controller.dart';
import 'services/settings/theme_controller.dart';
import 'theme/app_theme.dart';

/// App entry point.
///
/// Loads everything the first screen needs before `runApp`: the saved
/// language and theme, the notification channel, the default focus
/// profiles and the welcome choice. Clerk sign-in starts in the
/// background and is not awaited, so the app also opens offline.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (clerkPublishableKey.isEmpty) {
    throw StateError(
      'Missing CLERK_PUBLISHABLE_KEY. '
      'Run with --dart-define-from-file=clerk.json',
    );
  }

  await LocaleController.instance.initialize();
  await ThemeController.instance.initialize();

  AuthService.instance.start();

  await TimerNotificationService.instance.init();
  await ensureCoreProfiles();
  await WelcomeChoiceStore.instance.load();

  runApp(const MyApp());
}

/// Root widget.
///
/// Rebuilds MaterialApp when the language or theme changes, and opens
/// the countdown screen when the user taps the running-timer
/// notification.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settings = Listenable.merge([
    LocaleController.instance,
    ThemeController.instance,
  ]);

  @override
  void initState() {
    super.initState();
    FocusNotificationNavigation.instance.start(openTimer: _openActiveTimer);
  }

  @override
  void dispose() {
    FocusNotificationNavigation.instance.stop();
    super.dispose();
  }

  Future<void> _openActiveTimer() async {
    try {
      final profile = await loadActiveFocusProfile();
      if (!mounted || profile == null) return;
      router.go('/countdown', extra: profile);
    } catch (error) {
      debugPrint('Failed to open active timer: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Rest For More',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(brightness: Brightness.light),
          darkTheme: buildAppTheme(brightness: Brightness.dark),
          themeMode: ThemeController.instance.themeMode,
          locale: LocaleController.instance.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        );
      },
    );
  }
}
