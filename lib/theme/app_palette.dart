import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Colours that follow light / dark mode.
///
/// Registered on the theme as a [ThemeExtension] in `buildAppTheme`, so a
/// widget reads `context.palette.text` and gets the right colour for the
/// current mode. Both modes use only the brand colours from [AppColors].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.text,
    required this.muted,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.highlight,
    required this.onAccent,
  });

  /// Screen background.
  final Color background;

  /// Fields, sheets and other raised areas.
  final Color surface;

  /// Card background.
  final Color card;

  /// Main text and icons.
  final Color text;

  /// Secondary text and icons.
  final Color muted;

  /// Buttons and selected states.
  final Color accent;

  /// Soft fill behind accented content.
  final Color accentSoft;

  /// Outlines and dividers.
  final Color border;

  /// Yellow for small emphasis.
  final Color highlight;

  /// Text and icons on top of [accent].
  final Color onAccent;

  static const light = AppPalette(
    background: AppColors.backgroundWhite,
    surface: AppColors.surface,
    card: AppColors.surface,
    text: AppColors.darkBrown,
    muted: AppColors.lightBrown,
    accent: AppColors.mediumBrown,
    accentSoft: AppColors.surface,
    border: AppColors.lightBrown,
    highlight: AppColors.highlightYellow,
    onAccent: AppColors.backgroundWhite,
  );

  static const dark = AppPalette(
    background: AppColors.darkBrown,
    surface: AppColors.mediumBrown,
    card: AppColors.mediumBrown,
    text: AppColors.backgroundWhite,
    muted: AppColors.surface,
    accent: AppColors.highlightYellow,
    accentSoft: AppColors.lightBrown,
    border: AppColors.lightBrown,
    highlight: AppColors.highlightYellow,
    onAccent: AppColors.darkBrown,
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? text,
    Color? muted,
    Color? accent,
    Color? accentSoft,
    Color? border,
    Color? highlight,
    Color? onAccent,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      border: border ?? this.border,
      highlight: highlight ?? this.highlight,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;

    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// Shortcut: `context.palette.text` instead of
/// `Theme.of(context).extension<AppPalette>()!.text`.
extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
