import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RoutineProgressIndicator extends StatelessWidget {
  const RoutineProgressIndicator({
    super.key,
    required this.completed,
    required this.total,
    required this.palette,
  });
  final int completed;
  final int total;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return SizedBox(
      width: 82,
      height: 82,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress,
          trackColor: palette.border,
          progressColor: palette.accent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$completed/$total',
              key: const Key('hero-progress'),
              style: TextStyle(
                color: palette.text,
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DONE',
              style: TextStyle(
                color: palette.muted,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });
  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 7) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    final foreground = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.progressColor != progressColor;
}
