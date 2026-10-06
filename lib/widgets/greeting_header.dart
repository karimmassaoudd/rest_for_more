import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';
import 'rfm_logo.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    required this.period,
    required this.palette,
    required this.onBack,
    required this.onAction,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;
  final VoidCallback onBack;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isMorning = period == RoutinePeriod.morning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RfmLogo(textColor: palette.text, onTap: onBack),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isMorning ? 'Morning' : 'Evening',
                key: ValueKey('header-${period.name}'),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: isMorning ? 'Refresh routine' : 'Routine settings',
              onPressed: onAction,
              icon: Icon(
                isMorning ? Icons.refresh_rounded : Icons.more_vert_rounded,
                color: palette.text,
                size: 19,
              ),
            ),
          ],
        ),
        if (isMorning) ...[
          const SizedBox(height: 18),
          Text(
            'Your morning',
            style: TextStyle(
              color: palette.text,
              fontFamily: 'serif',
              fontSize: 27,
              height: 1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Set everything ready for the day ahead. Put your phone away and let yourself start slowly.',
            style: TextStyle(
              color: palette.muted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}
