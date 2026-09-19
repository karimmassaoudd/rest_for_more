import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';
import 'routine_progress_indicator.dart';

class ActiveRoutineCard extends StatelessWidget {
  const ActiveRoutineCard({
    super.key,
    required this.period,
    required this.palette,
    required this.completed,
    required this.total,
  });
  final RoutinePeriod period;
  final RoutinePalette palette;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    final isComplete = completed == total;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: morning ? 0.045 : 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(
                      label: isComplete
                          ? 'ROUTINE COMPLETE'
                          : morning
                          ? 'IN FLOW'
                          : 'READY TO BEGIN',
                      palette: palette,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      morning ? 'Mindful\nAwakening' : 'Restorative\nWind-Down',
                      style: TextStyle(
                        color: palette.text,
                        fontFamily: 'serif',
                        fontSize: 27,
                        height: 1.02,
                        letterSpacing: -0.55,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      morning
                          ? 'Estimated finish · 7:50 AM'
                          : 'Estimated finish · 10:15 PM',
                      style: TextStyle(
                        color: palette.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!morning) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Start by 9:40 PM',
                        style: TextStyle(
                          color: palette.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RoutineProgressIndicator(
                completed: completed,
                total: total,
                palette: palette,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: palette.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 17,
                  color: palette.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  morning
                      ? 'Forest Dawn Soundscape'
                      : 'Deep Cedar & Night Crickets',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Playing',
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.palette});
  final String label;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: palette.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: palette.accent,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
