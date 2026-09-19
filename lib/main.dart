import 'package:flutter/material.dart';

import 'screens/routine_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RestForMeApp());
}

class RestForMeApp extends StatelessWidget {
  const RestForMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest For Me',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.base,
      home: const RoutineScreen(),
    );
  }
}
