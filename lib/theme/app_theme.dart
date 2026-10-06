import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get base {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.morningBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brown,
        brightness: Brightness.light,
        surface: AppColors.morningBackground,
      ),
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'sans-serif',
          color: AppColors.morningText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'sans-serif',
          color: AppColors.morningText,
        ),
      ),
    );
  }
}
