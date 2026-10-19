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

  final rounded14 = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.darkbrown,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppFonts.montserrat(size: 16),
    ),

    // ----- buttons -----
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

    // ----- surfaces -----
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
      contentTextStyle: AppFonts.manrope(size: 14, color: AppColors.lightbrown),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surface,
      thickness: 1,
      space: 1,
    ),

    // ----- lists and inputs -----
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.mediumbrown, width: 1.5),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.mediumbrown,
      selectionHandleColor: AppColors.mediumbrown,
    ),

    // ----- feedback -----
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkbrown,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: AppFonts.manrope(size: 14, color: AppColors.background),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
