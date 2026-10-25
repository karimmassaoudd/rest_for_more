import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get base => light;

  static ThemeData get light {
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

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.eveningBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.eveningButton,
        brightness: Brightness.dark,
        surface: AppColors.eveningSurface,
      ),
      splashFactory: InkRipple.splashFactory,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'sans-serif',
          color: AppColors.eveningText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'sans-serif',
          color: AppColors.eveningText,
        ),
      ),
    );
  }
}
