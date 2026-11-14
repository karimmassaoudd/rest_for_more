import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import 'sunburst_timer_painter.dart';

/// The round sunburst dial on the timer screen, with the time left in the middle.
///
/// [progress] runs from 1.0 (full) to 0.0 (done). During a break the dial
/// shows the break instead, with a small "Break" label above the time.
class TimerDial extends StatelessWidget {
  const TimerDial({
    super.key,
    required this.progress,
    required this.millisLeft,
    this.onBreak = false,
  });

  final double progress;
  final int millisLeft;
  final bool onBreak;

  /// "mm:ss", or "h:mm:ss" from one hour.
  /// Rounds up, so the last second shows 00:01 instead of 00:00.
  static String formatTime(int millis) {
    final safeMillis = millis < 0 ? 0 : millis;
    final totalSeconds = (safeMillis / 1000).ceil();
    final hours = totalSeconds ~/ 3600;
    final mm = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FittedBox(
      // Shrinks the dial on small screens instead of overflowing.
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 310,
        height: 310,
        child: CustomPaint(
          painter: SunburstTimerPainter(
            progress: progress,
            tickCount: 72,
            activeColorStart: palette.highlight,
            activeColorEnd: palette.text,
            inactiveColor: palette.surface,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBreak)
                  Text(
                    'Break',
                    style: AppFonts.montserrat(size: 14, color: palette.muted),
                  ),
                Text(
                  formatTime(millisLeft),
                  style:
                      AppFonts.manrope(
                        size: 64,
                        weight: FontWeight.w400,
                        color: palette.text,
                      ).copyWith(
                        // Every digit the same width, so the time doesn't
                        // jiggle sideways as it counts down.
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
