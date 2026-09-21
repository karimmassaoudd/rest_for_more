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
      height: 57,
      child: FilledButton.icon(
        key: const Key('focus-mode-button'),
        onPressed: onEnterFocusMode,
        icon: const Icon(Icons.play_arrow_rounded, size: 20),
        label: Text(morning ? 'Enter Focus Mode' : 'Enter Sleep Flow'),
        style: FilledButton.styleFrom(
          backgroundColor: palette.button,
          foregroundColor: palette.buttonText,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
