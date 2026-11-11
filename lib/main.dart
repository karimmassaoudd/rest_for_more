import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'services/auth/auth_service.dart';
import 'services/onboarding/welcome_choice_store.dart';
import 'services/settings/locale_controller.dart';

import 'services/focus/profile_bootstrap.dart';
import 'services/focus/timer_notification_service.dart';
import 'services/focus/focus_notification_navigation.dart';
import 'services/focus/active_focus_profile.dart';

import 'theme/app_theme.dart';
import 'router.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (clerkPublishableKey.isEmpty) {
    throw StateError(
      'Missing CLERK_PUBLISHABLE_KEY. '
      'Run with --dart-define-from-file=clerk.json',
    );
  }

  // Initialize global language preference.
  await LocaleController.instance.initialize();

  AuthService.instance.start();

  await TimerNotificationService.instance.init();
  await ensureCoreProfiles();
  await WelcomeChoiceStore.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FocusNotificationNavigation.instance.start(openTimer: _openActiveTimer);
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
  void dispose() {
    FocusNotificationNavigation.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeController = LocaleController.instance;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Rest For More',
          theme: buildAppTheme(),
          debugShowCheckedModeBanner: false,

          // Global language setting.
          locale: localeController.locale,

          // English and Dutch.
          supportedLocales: const [Locale('en'), Locale('nl')],

          // Flutter localization support.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Preserve your existing navigation.
          routerConfig: router,
        );
      },
    );
  }
}

// import 'package:flutter/material.dart';

// import 'services/auth/auth_service.dart';
// import 'services/onboarding/welcome_choice_store.dart';

// import 'services/focus/profile_bootstrap.dart';
// import 'services/focus/timer_notification_service.dart';
// import 'services/focus/focus_notification_navigation.dart';
// import 'services/focus/active_focus_profile.dart';
// import 'theme/app_theme.dart';

// import 'router.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   if (clerkPublishableKey.isEmpty) {
//     throw StateError(
//       'Missing CLERK_PUBLISHABLE_KEY. Run with --dart-define-from-file=clerk.json',
//     );
//   }
//   AuthService.instance.start(); // background, never awaited

//   await TimerNotificationService.instance.init();
//   await ensureCoreProfiles();
//   await WelcomeChoiceStore.instance.load();

//   runApp(const MyApp());
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   @override
//   void initState() {
//     super.initState();

//     FocusNotificationNavigation.instance.start(openTimer: _openActiveTimer);
//   }

//   Future<void> _openActiveTimer() async {
//     try {
//       final profile = await loadActiveFocusProfile();

//       if (!mounted || profile == null) return;

//       router.go('/countdown', extra: profile);
//     } catch (error) {
//       debugPrint('Failed to open active timer: $error');
//     }
//   }

//   @override
//   void dispose() {
//     FocusNotificationNavigation.instance.stop();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp.router(
//       title: 'Rest For More',
//       theme: buildAppTheme(),
//       debugShowCheckedModeBanner: false,
//       routerConfig: router,
//     );
//   }
// }
