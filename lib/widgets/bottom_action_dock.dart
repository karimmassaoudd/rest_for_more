import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class BottomActionDock extends StatelessWidget {
  const BottomActionDock({
    super.key,
    required this.period,
    required this.palette,
  });
  final RoutinePeriod period;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 57,
          child: FilledButton.icon(
            onPressed: () {},
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
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Routine'),
              style: _textButtonStyle(),
            ),
            Container(
              width: 1,
              height: 16,
              color: palette.border,
              margin: const EdgeInsets.symmetric(horizontal: 3),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded, size: 15),
              label: const Text('Routine Settings'),
              style: _textButtonStyle(),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _textButtonStyle() => TextButton.styleFrom(
    foregroundColor: palette.muted,
    textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
  );
}
