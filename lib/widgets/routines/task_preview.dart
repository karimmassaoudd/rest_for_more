import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../theme/app_colors.dart';

/// Small card with the current and the next open routine step.
class TaskPreview extends StatelessWidget {
  const TaskPreview({
    super.key,
    required this.currentStep,
    required this.nextStep,
    required this.palette,
  });

  /// Null when the routine is complete.
  final RoutineStep? currentStep;
  final RoutineStep? nextStep;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewRow(
            icon: Icons.play_circle_outline_rounded,
            label: 'Current task',
            value: currentStep?.title ?? 'Routine complete',
            palette: palette,
          ),
          const SizedBox(height: 8),
          _PreviewRow(
            icon: Icons.arrow_forward_rounded,
            label: 'Next task',
            value: nextStep?.title ?? 'Routine complete',
            palette: palette,
          ),
        ],
      ),
    );
  }
}

/// "Current task: Sensory Shower". The value text gets a key made from
/// the label ('current-task' / 'next-task') for widget tests.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final String value;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: palette.accent, size: 15),
        const SizedBox(width: 9),
        SizedBox(
          width: 76,
          child: Text(
            '$label:',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            key: Key(label.toLowerCase().replaceAll(' ', '-')),
            style: TextStyle(
              color: palette.text,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
