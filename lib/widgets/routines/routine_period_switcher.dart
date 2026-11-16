import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class RoutinePeriodSwitcher extends StatelessWidget {
  const RoutinePeriodSwitcher({
    super.key,
    required this.period,
    required this.palette,
    required this.onChanged,
  });
  final RoutinePeriod period;
  final RoutinePalette palette;
  final ValueChanged<RoutinePeriod> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: palette.border.withValues(alpha: .45)),
    ),
    child: Row(
      children: [
        _PeriodButton(
          label: 'Morning',
          icon: Icons.wb_sunny_outlined,
          selected: period == RoutinePeriod.morning,
          palette: palette,
          onPressed: () => onChanged(RoutinePeriod.morning),
        ),
        _PeriodButton(
          label: 'Evening',
          icon: Icons.nightlight_outlined,
          selected: period == RoutinePeriod.evening,
          palette: palette,
          onPressed: () => onChanged(RoutinePeriod.evening),
        ),
      ],
    ),
  );
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final RoutinePalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: selected ? palette.accentSoft : Colors.transparent,
        foregroundColor: selected ? palette.text : palette.muted,
        textStyle: AppFonts.manrope(size: 12, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
