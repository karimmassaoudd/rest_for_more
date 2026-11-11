import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Consistent circular timer dial used by every routine activity.
class ActivityTimer extends StatelessWidget {
  const ActivityTimer({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.palette,
    this.size = 270,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final ActivityTimerPalette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (secondsRemaining % 60).toString().padLeft(2, '0');
    final progress = totalSeconds == 0
        ? 1.0
        : (1 - secondsRemaining / totalSeconds).clamp(0.0, 1.0);

    return Semantics(
      label: 'Timer, $minutes minutes and $seconds seconds remaining',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _TimerTicksPainter(
            progress: progress,
            activeColor: palette.active,
            inactiveColor: palette.inactive,
          ),
          child: Center(
            child: Text(
              '$minutes:$seconds',
              key: const Key('activity-timer-value'),
              style: TextStyle(
                color: palette.text,
                fontFamily: 'serif',
                fontSize: 54,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActivityTimerPalette {
  const ActivityTimerPalette({
    required this.active,
    required this.inactive,
    required this.text,
  });

  final Color active;
  final Color inactive;
  final Color text;
}

class _TimerTicksPainter extends CustomPainter {
  const _TimerTicksPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  static const _tickCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;
    final paint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final activeTicks = (progress * _tickCount).round();

    for (var index = 0; index < _tickCount; index++) {
      final angle = -math.pi / 2 + (2 * math.pi * index / _tickCount);
      final outer = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 25),
        center.dy + math.sin(angle) * (radius - 25),
      );
      paint.color = index < activeTicks ? activeColor : inactiveColor;
      canvas.drawLine(inner, outer, paint);
    }
  }

  @override
  bool shouldRepaint(_TimerTicksPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      activeColor != oldDelegate.activeColor ||
      inactiveColor != oldDelegate.inactiveColor;
}
