import 'package:flutter/material.dart';

import 'services/profile_bootstrap.dart';
import 'theme/app_theme.dart';
import 'services/timer_notification_service.dart';

import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimerNotificationService.instance.init();
  await ensureCoreProfiles();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Rest For More',
    theme: buildAppTheme(),
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  );
}
