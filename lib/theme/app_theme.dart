import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Global theme: every screen inherits it.
ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.mediumbrown,
      primary: AppColors.mediumbrown,
      onPrimary: AppColors.background,
      secondary: AppColors.lightbrown,
      surface: AppColors.background,
      onSurface: AppColors.darkbrown,
      surfaceContainerHighest: AppColors.surface,
      outline: AppColors.lightbrown,
    ),
  );

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
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.mediumbrown,
        textStyle: AppFonts.manrope(size: 16, weight: FontWeight.w600),
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
