import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_palette.dart';

/// The app-wide theme. Every screen inherits it.
///
/// Builds the light or dark version from [AppPalette] and registers the
/// palette as an extension, which is what `context.palette` reads.
/// `main.dart` calls this twice: once for `theme`, once for `darkTheme`.
///
/// Fields, buttons, dialogs and sheets are styled here once, so screens
/// don't need their own borders or button styles.
ThemeData buildAppTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final palette = isDark ? AppPalette.dark : AppPalette.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.muted,
    onSecondary: palette.onAccent,
    surface: palette.surface,
    onSurface: palette.text,
    error: AppColors.error,
    onError: AppColors.buttonText,
  );

  // Shared shapes, so every field and button has the same corners.
  OutlineInputBorder field(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  final buttonText = AppFonts.manrope(
    size: 15,
    weight: FontWeight.w600,
    color: palette.onAccent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[palette],
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    cardColor: palette.card,
    dividerColor: palette.border,

    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),

    iconTheme: IconThemeData(color: palette.text),

    textTheme: ThemeData(brightness: brightness).textTheme.apply(
      fontFamily: 'Manrope',
      bodyColor: palette.text,
      displayColor: palette.text,
    ),

    // ----- buttons -----
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        disabledBackgroundColor: palette.muted,
        disabledForegroundColor: palette.text,
        elevation: 0,
        textStyle: buttonText,
        shape: buttonShape,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        textStyle: buttonText,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.accent,
        side: BorderSide(color: palette.border),
        textStyle: buttonText.copyWith(color: palette.accent),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        textStyle: buttonText.copyWith(color: palette.accent),
      ),
    ),

    // ----- text fields -----
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppFonts.manrope(size: 15, color: palette.muted),
      labelStyle: AppFonts.manrope(size: 15, color: palette.muted),
      floatingLabelStyle: AppFonts.manrope(size: 13, color: palette.accent),
      border: field(palette.border),
      enabledBorder: field(palette.border),
      disabledBorder: field(palette.border.withValues(alpha: 0.4)),
      focusedBorder: field(palette.accent, 1.5),
      errorBorder: field(AppColors.error),
      focusedErrorBorder: field(AppColors.error, 1.5),
      errorStyle: AppFonts.manrope(size: 12, color: AppColors.error),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.accent,
      selectionHandleColor: palette.accent,
      selectionColor: palette.accent.withValues(alpha: 0.25),
    ),

    // ----- dialogs, sheets, snack bars -----
    dialogTheme: DialogThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      iconColor: palette.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppFonts.cormorant(
        size: 24,
        weight: FontWeight.w600,
        color: palette.text,
      ),
      contentTextStyle: AppFonts.manrope(size: 14, color: palette.muted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.text,
      contentTextStyle: AppFonts.manrope(size: 14, color: palette.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
