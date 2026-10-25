import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/routine_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // The app can still use its local database if Firebase is unavailable.
  }
  runApp(const RestForMeApp());
}

class RestForMeApp extends StatelessWidget {
  const RestForMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest For Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const RoutineScreen(),
    );
  }
}
