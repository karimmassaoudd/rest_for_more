import 'package:flutter/material.dart';

import '../models/routine_step.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFFAF8F3);
  static const surface = Color(0xFFF1EDE4);
  static const card = Color(0xFFEDE8DC);
  static const border = Color(0xFFD3BCA8);
  static const text = Color(0xFF51443B);
  static const muted = Color(0xFFA88670);
  static const brown = Color(0xFF8A6449);
  static const brownSoft = Color(0xFFE7DDD0);
  static const buttonText = Color(0xFFFFFCF8);

  static const morningBackground = background;
  static const morningCard = card;
  static const morningBorder = border;
  static const morningText = text;
  static const morningMuted = muted;
  static const sage = brown;
  static const sageSoft = brownSoft;
  static const amber = Color(0xFFB98965);
  static const amberSoft = brownSoft;

  static const eveningBackground = background;
  static const eveningSurface = surface;
  static const eveningCard = card;
  static const eveningBorder = border;
  static const eveningText = text;
  static const eveningMuted = muted;
  static const eveningAmber = brown;
  static const moonSage = brown;
  static const espresso = brown;
}

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

  factory RoutinePalette.forPeriod(RoutinePeriod period) {
    if (period == RoutinePeriod.morning) {
      return const RoutinePalette(
        background: AppColors.morningBackground,
        surface: AppColors.surface,
        card: AppColors.morningCard,
        border: AppColors.morningBorder,
        text: AppColors.morningText,
        muted: AppColors.morningMuted,
        accent: AppColors.sage,
        accentSoft: AppColors.sageSoft,
        button: AppColors.brown,
        buttonText: AppColors.buttonText,
      );
    }

    return const RoutinePalette(
      background: AppColors.eveningBackground,
      surface: AppColors.eveningSurface,
      card: AppColors.eveningCard,
      border: AppColors.eveningBorder,
      text: AppColors.eveningText,
      muted: AppColors.eveningMuted,
      accent: AppColors.eveningAmber,
      accentSoft: AppColors.brownSoft,
      button: AppColors.brown,
      buttonText: AppColors.buttonText,
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
