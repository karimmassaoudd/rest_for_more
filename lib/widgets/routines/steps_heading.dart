import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// "YOUR STEPS" with the number of open steps on the right.
class StepsHeading extends StatelessWidget {
  const StepsHeading({
    super.key,
    required this.remaining,
    required this.palette,
  });

  final int remaining;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'YOUR STEPS',
          style: TextStyle(
            color: palette.text,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.55,
          ),
        ),
        // Fades when the number changes.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            '$remaining ${remaining == 1 ? 'step' : 'steps'} remaining',
            key: ValueKey(remaining),
            style: TextStyle(
              color: palette.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
