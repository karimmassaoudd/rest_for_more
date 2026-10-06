import 'package:flutter/material.dart';

class RfmLogo extends StatelessWidget {
  const RfmLogo({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: 'RFM home',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
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
                const Text(
                  'RFM',
                  style: TextStyle(
                  color: Color(0xFF8A6449),
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
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
    final crescent = Path.combine(PathOperation.difference, moon, cutout);
    canvas.drawPath(crescent, Paint()..color = const Color(0xFFFFCE4E));
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter oldDelegate) => false;
}
