import 'package:flutter/material.dart';

import 'services/profile_bootstrap.dart';
import 'services/timer_notification_service.dart';
import 'services/focus_notification_navigation.dart';
import 'services/active_focus_profile.dart';
import 'theme/app_theme.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await TimerNotificationService.instance.init();
  await ensureCoreProfiles();

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
    return MaterialApp.router(
      title: 'Rest For More',
      theme: buildAppTheme(),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
