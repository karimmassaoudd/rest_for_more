import 'package:flutter/material.dart';

import '../models/routine_step.dart';

class AppColors {
  const AppColors._();

  static const morningBackground = Color(0xFFF7F4EE);
  static const morningCard = Color(0xFFFFFFFF);
  static const morningBorder = Color(0xFFECE7DF);
  static const morningText = Color(0xFF211D19);
  static const morningMuted = Color(0xFF847B72);
  static const sage = Color(0xFF60745D);
  static const sageSoft = Color(0xFFE5EBE2);
  static const amber = Color(0xFFD8A35F);
  static const amberSoft = Color(0xFFF5E8D2);

  static const eveningBackground = Color(0xFF251E1A);
  static const eveningSurface = Color(0xFF2C241E);
  static const eveningCard = Color(0xFF352C26);
  static const eveningBorder = Color(0xFF4A3E36);
  static const eveningText = Color(0xFFF7F0E7);
  static const eveningMuted = Color(0xFFB9AA9A);
  static const eveningAmber = Color(0xFFE6B072);
  static const moonSage = Color(0xFF8FA08A);
  static const espresso = Color(0xFF2B2520);
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
        surface: Color(0xFFEDE9E1),
        card: AppColors.morningCard,
        border: AppColors.morningBorder,
        text: AppColors.morningText,
        muted: AppColors.morningMuted,
        accent: AppColors.sage,
        accentSoft: AppColors.sageSoft,
        button: AppColors.espresso,
        buttonText: Color(0xFFFFFBF5),
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
      accentSoft: Color(0xFF493B2E),
      button: Color(0xFFF0C58F),
      buttonText: Color(0xFF2A211B),
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
