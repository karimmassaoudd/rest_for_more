import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Shown under the steps once every step of the routine is done.
class CompletionBanner extends StatelessWidget {
  const CompletionBanner({
    super.key,
    required this.period,
    required this.palette,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            morning ? Icons.check_circle_rounded : Icons.nightlight_round,
            color: palette.accent,
            size: 18,
          ),
          const SizedBox(width: 9),

          Text(
            morning ? 'Morning Routine Complete' : 'Sleep Mode Activated',
            style: AppFonts.cormorant(
              size: 17,
              weight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
