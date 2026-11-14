import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Rest For More colours: the six brand colours, a few role names built
/// from them, and supporting colours that never change with the theme.
///
/// Inside widgets, prefer `context.palette` so colours follow light/dark
/// mode. Use [AppColors] directly only for fixed colours (error, the
/// moon, text on yellow) and in services, which have no `context`.
abstract final class AppColors {
  // ----- Brand -----
  static const backgroundWhite = Color(0xFFFAF8F4);
  static const surface = Color(0xFFEBE6DA);
  static const lightBrown = Color(0xFF9F755C);
  static const mediumBrown = Color(0xFF7B563D);
  static const darkBrown = Color(0xFF4E3B31);
  static const highlightYellow = Color(0xFFFFB60A);

  // ----- Roles (light mode) -----
  static const text = darkBrown;
  static const muted = lightBrown;
  static const border = lightBrown;
  static const buttonText = backgroundWhite;

  // ----- Supporting -----
  static const moon = Color(0xFFFFC857);
  static const error = Color(0xFFB0473A);
}

/// Routine colours, taken from the app theme (light or dark), so morning
/// and evening routines are light in light mode and dark in dark mode.
class RoutinePalette {
  const RoutinePalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.button,
    required this.buttonText,
  });

  factory RoutinePalette.of(BuildContext context) {
    final p = context.palette;
    return RoutinePalette(
      background: p.background,
      surface: p.surface,
      card: p.card,
      border: p.border,
      text: p.text,
      muted: p.muted,
      accent: p.accent,
      accentSoft: p.accentSoft,
      button: p.accent,
      buttonText: p.onAccent,
    );
  }

  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color accentSoft;
  final Color button;
  final Color buttonText;
}
