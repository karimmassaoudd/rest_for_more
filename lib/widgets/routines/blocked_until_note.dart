import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_session_controller.dart';
import '../../theme/app_palette.dart';

/// "Apps stay blocked until 8:15 so you can start your day without your
/// phone." Only shown while this period's apps are blocked.
class BlockedUntilNote extends StatelessWidget {
  const BlockedUntilNote({super.key, required this.period});

  final RoutinePeriod period;

  @override
  Widget build(BuildContext context) {
    final session = RoutineSessionController.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final until = session.blockedUntil;
        if (!session.isRunningFor(period) ||
            !session.isBlockingApps ||
            until == null) {
          return const SizedBox.shrink();
        }
        final palette = context.palette;
        final time = MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(until),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
        final why = period == RoutinePeriod.morning
            ? 'so you can start your day without your phone.'
            : 'so you can fall asleep faster without your phone.';

        return Container(
          key: const Key('blocked-until-note'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.accentSoft.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_clock_outlined, size: 18, color: palette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Apps stay blocked until $time $why',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
