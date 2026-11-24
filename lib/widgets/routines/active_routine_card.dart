import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The card at the top of the routine screen: how many steps are done
/// and a progress bar.
class ActiveRoutineCard extends StatelessWidget {
  const ActiveRoutineCard({
    super.key,
    required this.palette,
    required this.completed,
    required this.total,
  });

  final RoutinePalette palette;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: palette.border.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: palette.text.withValues(alpha: 0.055),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$completed/$total',
                key: const Key('hero-progress'),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'activities done',
                style: TextStyle(color: palette.muted, fontSize: 10.5),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress,
              backgroundColor: palette.background,
              valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
            ),
          ),
        ],
      ),
    );
  }
}
