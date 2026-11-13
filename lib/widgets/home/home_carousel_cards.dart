import 'package:flutter/material.dart';

import '../../models/home/home_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';

/// The four cards in the Home carousel, in this order:
/// 0 = start a rest, 1 = morning routine, 2 = evening routine, 3 = 14-day plan.
///
/// The screen passes in what each button does, so this file only holds
/// the texts and the theme colours.
List<HomeCard> buildHomeCarouselCards({
  required BuildContext context,
  required VoidCallback onStartFocus,
  required VoidCallback onMorningRoutine,
  required VoidCallback onEveningRoutine,
  required VoidCallback onStartPlan,
}) {
  final palette = context.palette;

  return [
    HomeCard(
      icon: Icons.self_improvement_rounded,
      iconColor: palette.highlight,
      eyebrow: 'Ready for a quiet moment?',
      title: 'Put your phone down and focus on what’s important.',
      buttonLabel: 'Start focusing',
      background: palette.card,
      textColor: palette.text,
      buttonColor: palette.accent,
      buttonTextColor: palette.onAccent,
      buttonBorder: palette.border,
      onPressed: onStartFocus,
    ),
    HomeCard(
      icon: Icons.wb_twilight_rounded,
      iconColor: palette.highlight,
      eyebrow: 'Ready to start the day?',
      title: 'Good morning, start the day by being productive.',
      buttonLabel: 'Start Morning Routine',
      background: palette.card,
      textColor: palette.text,
      buttonColor: palette.highlight,
      // Dark text on the yellow button in both themes.
      buttonTextColor: AppColors.darkBrown,
      buttonBorder: palette.highlight,
      onPressed: onMorningRoutine,
    ),
    HomeCard(
      icon: Icons.nights_stay_rounded,
      iconColor: palette.highlight,
      eyebrow: 'Ready to end the day?',
      title: 'Good evening, end the day on a good note.',
      buttonLabel: 'Start Evening Routine',
      background: palette.card,
      textColor: palette.text,
      buttonColor: palette.accent,
      buttonTextColor: palette.onAccent,
      buttonBorder: palette.border,
      onPressed: onEveningRoutine,
    ),
    HomeCard(
      icon: Icons.today_rounded,
      iconColor: palette.highlight,
      eyebrow: 'Don’t have a routine yet?',
      title: 'Start your 14-day plan, made to fit your day.',
      buttonLabel: 'Answer a few questions',
      background: palette.card,
      textColor: palette.text,
      buttonColor: palette.accent,
      buttonTextColor: palette.onAccent,
      buttonBorder: palette.border,
      onPressed: onStartPlan,
    ),
  ];
}

/// Which carousel card to show first at [time]:
/// morning card 07:00–08:59, evening card 20:00–20:59, otherwise "start a rest".
int homeCarouselIndexFor(DateTime time) {
  final hour = time.hour;
  if (hour >= 7 && hour < 9) return 1;
  if (hour >= 20 && hour < 21) return 2;
  return 0;
}
