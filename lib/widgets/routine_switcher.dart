import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class RoutineSwitcher extends StatelessWidget {
  const RoutineSwitcher({
    super.key,
    required this.selected,
    required this.palette,
    required this.onChanged,
  });

  final RoutinePeriod selected;
  final RoutinePalette palette;
  final ValueChanged<RoutinePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Routine time',
      child: Container(
        height: 58,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: palette.border.withValues(alpha: 0.75)),
        ),
        child: Row(
          children: [
            _SwitcherOption(
              key: const Key('morning-switch'),
              label: 'Morning',
              icon: Icons.wb_sunny_outlined,
              selected: selected == RoutinePeriod.morning,
              palette: palette,
              onTap: () => onChanged(RoutinePeriod.morning),
            ),
            _SwitcherOption(
              key: const Key('evening-switch'),
              label: 'Evening',
              icon: Icons.nightlight_round,
              selected: selected == RoutinePeriod.evening,
              palette: palette,
              onTap: () => onChanged(RoutinePeriod.evening),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitcherOption extends StatelessWidget {
  const _SwitcherOption({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final RoutinePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 230),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? palette.card : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? palette.accent : palette.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? palette.text : palette.muted,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
