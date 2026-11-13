import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// The small Rest For More logo: a yellow crescent moon above "RFM".
/// [textColor] lets it sit on both light and dark backgrounds.
class RfmLogo extends StatelessWidget {
  const RfmLogo({super.key, required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'RFM home',
      child: SizedBox(
        key: const Key('rfm-logo'),
        width: 64,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 25,
              height: 20,
              child: CustomPaint(painter: _CrescentPainter()),
            ),
            const SizedBox(height: 1),
            Text(
              'RFM',
              style: AppFonts.manrope(
                size: 17,
                weight: FontWeight.w800,
                color: textColor,
              ).copyWith(height: 1, letterSpacing: -0.4),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logo's moon: a circle with a smaller circle cut out at the top right.
class _CrescentPainter extends CustomPainter {
  const _CrescentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final moon = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.46, size.height * 0.53),
          radius: size.height * 0.48,
        ),
      );
    final cutout = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.67, size.height * 0.32),
          radius: size.height * 0.45,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, moon, cutout),
      Paint()..color = AppColors.moon,
    );
  }

  // Nothing about it ever changes.
  @override
  bool shouldRepaint(covariant _CrescentPainter oldDelegate) => false;
}
