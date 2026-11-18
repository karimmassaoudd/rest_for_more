import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_session_controller.dart';
import '../../theme/app_palette.dart';
import '../focus/no_apps_dialog.dart';

/// While this period's routine runs:
/// - apps blocked: "Apps stay blocked until 8:15 so you can start your day
///   without your phone."
/// - nothing blocked (permission refused, or no apps chosen):
///   "No apps are blocked during this routine. [Turn on]"
class BlockedUntilNote extends StatelessWidget {
  const BlockedUntilNote({super.key, required this.period});

  final RoutinePeriod period;

  Future<void> _turnOn(BuildContext context) async {
    final go = await confirmBlockedApps(
      context,
      period.name,
      sessionName: '${routineName(period)} routine',
    );
    if (!go || !context.mounted) return;
    await RoutineSessionController.instance.retryBlocking(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = RoutineSessionController.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        if (!session.isRunningFor(period)) return const SizedBox.shrink();
        final palette = context.palette;
        final until = session.blockedUntil;

        if (!session.isBlockingApps || until == null) {
          return _box(
            palette,
            key: const Key('blocking-off-note'),
            icon: Icons.lock_open_rounded,
            text: 'No apps are blocked during this routine.',
            action: TextButton(
              key: const Key('turn-on-blocking-button'),
              onPressed: () => _turnOn(context),
              child: Text(
                'Turn on',
                style: TextStyle(
                  color: palette.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        final time = MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(until),
          alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
        );
        final why = period == RoutinePeriod.morning
            ? 'so you can start your day without your phone.'
            : 'so you can fall asleep faster without your phone.';
        return _box(
          palette,
          key: const Key('blocked-until-note'),
          icon: Icons.lock_clock_outlined,
          text: 'Apps stay blocked until $time $why',
        );
      },
    );
  }

  Widget _box(
    AppPalette palette, {
    required Key key,
    required IconData icon,
    required String text,
    Widget? action,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, action == null ? 14 : 4, 12),
      decoration: BoxDecoration(
        color: palette.accentSoft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: palette.text,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}
