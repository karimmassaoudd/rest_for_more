import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../models/routines/routine_step.dart';
import '../../theme/app_colors.dart';

/// One step in the routine list: time, a round to-do circle with an icon
/// picked from the title, name and duration.
///
/// Tap opens the step. Swipe right ticks it off, or unticks it when it's
/// already done. When done, the icon stays: the circle gets an accent ring
/// and a small ✓ badge.
class RoutineItemCard extends StatelessWidget {
  const RoutineItemCard({
    super.key,
    required this.step,
    required this.index,
    required this.isActive,
    required this.period,
    required this.palette,
    required this.onOpen,
    required this.onToggle,
  });

  final RoutineStep step;
  final int index;
  final bool isActive;
  final RoutinePeriod period;
  final RoutinePalette palette;

  /// Tap: open this step's activity screen.
  final VoidCallback onOpen;

  /// Swipe (or the screen-reader action): tick or untick the step.
  final VoidCallback onToggle;

  /// Picks an icon from words in the title ("shower", "journal", …).
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey('routine-swipe-${step.title}'),
        // Swipe either way: right-handed and left-handed both work.
        direction: DismissDirection.horizontal,
        // The card never leaves the list: a swipe only ticks or unticks it.
        confirmDismiss: (_) async {
          onToggle();
          return false;
        },
        background: _SwipeBackground(completed: completed, palette: palette),
        secondaryBackground: _SwipeBackground(
          completed: completed,
          palette: palette,
          alignEnd: true,
        ),
        child: Semantics(
          button: true,
          checked: completed,
          label: '${step.title}, ${step.time}, ${step.duration}',
          onTapHint: 'Open activity',
          customSemanticsActions: {
            CustomSemanticsAction(
              label: completed ? 'Mark as not done' : 'Mark as done',
            ): onToggle,
          },
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('routine-step-$index'),
              onTap: onOpen,
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: completed
                      ? palette.accentSoft.withValues(alpha: 0.38)
                      : palette.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? palette.accent.withValues(alpha: 0.38)
                        : Colors.transparent,
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
                    _StepIcon(
                      key: Key('routine-step-icon-$index'),
                      icon: _iconForStep(),
                      completed: completed,
                      active: isActive,
                      palette: palette,
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
                            style: TextStyle(
                              color: palette.muted,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The round to-do circle: the step's icon always stays visible.
/// Done: accent ring + a small ✓ badge in the corner.
class _StepIcon extends StatelessWidget {
  const _StepIcon({
    super.key,
    required this.icon,
    required this.completed,
    required this.active,
    required this.palette,
  });

  final IconData icon;
  final bool completed;
  final bool active;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 33,
      height: 33,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? palette.accentSoft : palette.surface,
              border: Border.all(
                color: completed || active
                    ? palette.accent
                    : palette.border.withValues(alpha: 0.5),
                width: completed ? 1.6 : 1.2,
              ),
            ),
            child: Icon(
              icon,
              size: 15,
              color: completed ? palette.accent : palette.muted,
            ),
          ),
          if (completed)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.background, width: 1.5),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 9,
                  color: palette.buttonText,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What shows behind the card while it's swiped: "Done" or "Undo".
class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.completed,
    required this.palette,
    this.alignEnd = false,
  });

  final bool completed;
  final RoutinePalette palette;

  /// True for a swipe to the left: the label sits on the right.
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            completed ? Icons.undo_rounded : Icons.check_rounded,
            color: palette.accent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            completed ? 'Undo' : 'Done',
            style: TextStyle(
              color: palette.accent,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
