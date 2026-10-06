import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class BottomActionDock extends StatelessWidget {
  const BottomActionDock({
    super.key,
    required this.period,
    required this.palette,
    required this.onEnterFocusMode,
  });
  final RoutinePeriod period;
  final RoutinePalette palette;
  final VoidCallback onEnterFocusMode;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        key: const Key('focus-mode-button'),
        onPressed: onEnterFocusMode,
        style: FilledButton.styleFrom(
          backgroundColor: palette.button,
          foregroundColor: palette.buttonText,
          elevation: 2,
          shadowColor: palette.button.withValues(alpha: 0.28),
          textStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              morning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(morning ? 'Start your morning' : 'Start evening'),
          ],
        ),
      ),
    );
  }
}
