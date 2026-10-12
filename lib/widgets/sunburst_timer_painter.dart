import 'dart:math';

import 'package:flutter/material.dart';

class SunburstTimerPainter extends CustomPainter {
  final double progress;
  final int tickCount;
  final Color activeColorStart;
  final Color activeColorEnd;
  final Color inactiveColor;

  SunburstTimerPainter({
    required this.progress,
    required this.tickCount,
    required this.activeColorStart,
    required this.activeColorEnd,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 2;
    const tickLength = 22.0;
    const strokeWidth = 3.0;

    final activePaint = Paint()
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    int activeTicks = (progress.clamp(0.0, 1.0) * tickCount).round();

    for (int i = 0; i < tickCount; i++) {
      double angle = -pi / 2 - (i * 2 * pi / tickCount);

      Offset innerPoint = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      Offset outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );

      if (i < activeTicks) {
        double t = Curves.easeIn.transform(i / tickCount);
        activePaint.color = Color.lerp(activeColorStart, activeColorEnd, t)!;
        canvas.drawLine(innerPoint, outerPoint, activePaint);
      } else {
        canvas.drawLine(innerPoint, outerPoint, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SunburstTimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
