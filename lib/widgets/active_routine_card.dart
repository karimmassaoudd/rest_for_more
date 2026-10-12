import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class ActiveRoutineCard extends StatelessWidget {
  const ActiveRoutineCard({
    super.key,
    required this.period,
    required this.palette,
    required this.completed,
    required this.total,
    required this.totalMinutes,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;
  final int completed;
  final int total;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final morning = period == RoutinePeriod.morning;
    final progress = total == 0 ? 0.0 : completed / total;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, morning ? 13 : 17, 16, 14),
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
          if (morning)
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.alarm_rounded,
                    color: palette.accent,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I usually wake up at',
                        style: TextStyle(color: palette.muted, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '07:00 AM',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalMinutes min routine',
                        style: TextStyle(color: palette.muted, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: palette.muted,
                  size: 18,
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(Icons.nightlight_round, color: palette.accent, size: 15),
                const SizedBox(width: 8),
                Text(
                  'I WANT TO SLEEP AT',
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '10:30 PM',
              style: TextStyle(
                color: palette.text,
                fontFamily: 'serif',
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Your evening begins at 9:40 PM · $totalMinutes min',
              style: TextStyle(color: palette.muted, fontSize: 10.5),
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: palette.border.withValues(alpha: 0.5)),
          const SizedBox(height: 11),
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
                'tasks completed',
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
