import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class RoutineItemCard extends StatelessWidget {
  const RoutineItemCard({
    super.key,
    required this.step,
    required this.index,
    required this.isActive,
    required this.period,
    required this.palette,
    required this.onToggle,
  });

  final RoutineStep step;
  final int index;
  final bool isActive;
  final RoutinePeriod period;
  final RoutinePalette palette;
  final VoidCallback onToggle;

  IconData _iconForStep() {
    final title = step.title.toLowerCase();
    if (title.contains('water') ||
        title.contains('matcha') ||
        title.contains('chamomile')) {
      return Icons.local_drink_outlined;
    }
    if (title.contains('shower')) return Icons.shower_outlined;
    if (title.contains('breath') || title.contains('stretch')) {
      return Icons.self_improvement_outlined;
    }
    if (title.contains('journal')) return Icons.edit_note_rounded;
    if (title.contains('phone') || title.contains('screen')) {
      return Icons.phone_iphone_rounded;
    }
    if (title.contains('priority')) return Icons.checklist_rounded;
    if (title.contains('skincare')) return Icons.spa_outlined;
    return Icons.circle_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final completed = step.isCompleted;
    final evening = period == RoutinePeriod.evening;

    return Semantics(
      button: true,
      checked: completed,
      label: '${step.title}, ${step.time}, ${step.duration}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: isActive && !completed ? Key('check-button-$index') : null,
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            decoration: BoxDecoration(
              color: evening
                  ? palette.card
                  : completed
                  ? palette.accentSoft.withValues(alpha: 0.38)
                  : isActive
                  ? palette.card.withValues(alpha: 0.72)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? palette.accent.withValues(alpha: 0.38)
                    : evening
                    ? Colors.transparent
                    : palette.border.withValues(alpha: 0.18),
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: palette.text.withValues(alpha: 0.045),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 52,
                  child: Text(
                    step.time.replaceAll(' AM', '').replaceAll(' PM', ''),
                    style: TextStyle(
                      color: completed ? palette.muted : palette.text,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CompletionControl(
                  key: Key('routine-toggle-$index'),
                  completed: completed,
                  active: isActive,
                  icon: _iconForStep(),
                  palette: palette,
                  onTap: onToggle,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: completed ? palette.muted : palette.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.duration,
                        style: TextStyle(color: palette.muted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                if (completed)
                  Text(
                    'Done',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    key: Key('routine-menu-$index'),
                    tooltip: 'Task options',
                    padding: EdgeInsets.zero,
                    color: palette.background,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: palette.muted,
                      size: 17,
                    ),
                    onSelected: (_) => onToggle(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              color: palette.accent,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Mark as complete',
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
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
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final bool completed;
  final bool active;
  final IconData icon;
  final RoutinePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: completed ? palette.accent : palette.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: active && !completed
                ? Border.all(color: palette.accent, width: 1.2)
                : null,
          ),
          child: Icon(
            completed ? Icons.check_rounded : icon,
            size: 15,
            color: completed ? palette.buttonText : palette.muted,
          ),
        ),
      ),
    );
  }
}
