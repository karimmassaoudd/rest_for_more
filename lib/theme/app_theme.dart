import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

ThemeData buildAppTheme() => AppTheme.light;

class AppTheme {
  const AppTheme._();

  static const instance = AppTheme._();

  static ThemeData get base => light;

  static ThemeData get light {
    final theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.morningBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brown,
        brightness: Brightness.light,
        surface: AppColors.morningBackground,
      ),
    );
    final rounded14 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.darkbrown,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppFonts.montserrat(size: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mediumbrown,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.surface,
          disabledForegroundColor: AppColors.lightbrown,
          elevation: 0,
          textStyle: AppFonts.manrope(size: 16, weight: FontWeight.w600),
          shape: rounded14,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.mediumbrown,
          textStyle: AppFonts.manrope(size: 16, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.mediumbrown,
          side: const BorderSide(color: AppColors.lightbrown),
          textStyle: AppFonts.manrope(size: 16, weight: FontWeight.w600),
          shape: rounded14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightbrown, width: 0.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: AppFonts.cormorant(size: 24, weight: FontWeight.w600),
        contentTextStyle: AppFonts.manrope(
          size: 14,
          color: AppColors.lightbrown,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surface,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.mediumbrown,
        textColor: AppColors.darkbrown,
        titleTextStyle: AppFonts.manrope(size: 15, weight: FontWeight.w600),
        subtitleTextStyle: AppFonts.manrope(
          size: 13,
          color: AppColors.lightbrown,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.mediumbrown
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(AppColors.background),
        side: const BorderSide(color: AppColors.lightbrown, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppFonts.manrope(size: 14, color: AppColors.lightbrown),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.mediumbrown,
            width: 1.5,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.mediumbrown,
        selectionHandleColor: AppColors.mediumbrown,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkbrown,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppFonts.manrope(
          size: 14,
          color: AppColors.background,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData get dark {
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
