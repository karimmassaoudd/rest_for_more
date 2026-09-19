import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class RoutineItemCard extends StatelessWidget {
  const RoutineItemCard({
    super.key,
    required this.step,
    required this.index,
    required this.isActive,
    required this.palette,
    required this.onToggle,
  });
  final RoutineStep step;
  final int index;
  final bool isActive;
  final RoutinePalette palette;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final completed = step.isCompleted;
    return Semantics(
      button: true,
      checked: completed,
      label: '${step.title}, ${step.time}, ${step.duration}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
        decoration: BoxDecoration(
          color: completed
              ? palette.accentSoft.withValues(alpha: 0.58)
              : palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? palette.accent.withValues(alpha: 0.68)
                : palette.border,
            width: isActive ? 1.35 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.13),
                    blurRadius: 22,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _CompletionControl(
              key: Key('routine-toggle-$index'),
              completed: completed,
              active: isActive,
              palette: palette,
              onTap: onToggle,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: completed
                          ? palette.muted.withValues(alpha: 0.92)
                          : palette.text,
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      decoration: completed ? TextDecoration.lineThrough : null,
                      decorationColor: palette.muted,
                      decorationThickness: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        step.time,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: palette.muted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: palette.muted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        step.duration,
                        style: TextStyle(
                          color: palette.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (completed)
              Text(
                'Done',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              )
            else if (isActive)
              Material(
                color: palette.accent,
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  key: Key('check-button-$index'),
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    child: Text(
                      'Check',
                      style: TextStyle(
                        color: palette.background,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletionControl extends StatelessWidget {
  const _CompletionControl({
    super.key,
    required this.completed,
    required this.active,
    required this.palette,
    required this.onTap,
  });
  final bool completed;
  final bool active;
  final RoutinePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: completed ? palette.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed || active ? palette.accent : palette.muted,
              width: active && !completed ? 2 : 1.3,
            ),
          ),
          child: completed
              ? Icon(Icons.check_rounded, size: 18, color: palette.background)
              : active
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: palette.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
