part of 'app_bottom_nav_bar.dart';

// The drawing for AppBottomNavBar: the bar with the swoop cut out,
// the curved line, and the crescent moon. A `part` of the nav bar file,
// so these classes stay private to it.

/// Snapshot of the swoop + moon for one animation frame.
class _Swoop {
  const _Swoop({
    required this.left,
    required this.right,
    required this.bottomX,
    required this.depth,
    required this.moonCenter,
    required this.hop,
    required this.lean,
  });

  /// Where the curve leaves and rejoins the top line.
  final double left;
  final double right;

  /// x of the lowest point (shifted sideways while moving).
  final double bottomX;
  final double depth;

  final double moonCenter;

  /// How far the moon jumps up while moving.
  final double hop;

  /// Extra moon rotation while moving (radians).
  final double lean;

  /// Adds the two curve segments; the path must already be at
  /// (left + dx, y0).
  void _appendCurve(Path p, double dx, double y0) {
    final l = left + dx;
    final r = right + dx;
    final b = bottomX + dx;
    final yb = y0 + depth;

    p
      ..cubicTo(l + (b - l) * 0.52, y0, b - (b - l) * 0.52, yb, b, yb)
      ..cubicTo(b + (r - b) * 0.52, yb, r - (r - b) * 0.52, y0, r, y0);
  }

  /// Just the curved line.
  Path linePath({double dx = 0, required double y0}) {
    final p = Path()..moveTo(left + dx, y0);
    _appendCurve(p, dx, y0);
    return p;
  }

  /// The closed region above the curve (cut out of the bar).
  Path notchPath({double dx = 0, required double y0}) {
    final p = Path()
      ..moveTo(left + dx, -40)
      ..lineTo(left + dx, y0);
    _appendCurve(p, dx, y0);
    p
      ..lineTo(right + dx, -40)
      ..close();
    return p;
  }

  /// Same curve shape (the moon fields don't matter for the painters).
  bool sameAs(_Swoop o) =>
      o.left == left &&
      o.right == right &&
      o.bottomX == bottomX &&
      o.depth == depth;
}

/// Paints the bar (shadow, background, top line) with the swoop region
/// cut out, so the area above the brown curve is transparent.
class _PillPainter extends CustomPainter {
  _PillPainter({
    required this.swoop,
    required this.barPadding,
    required this.lineWidth,
    required this.radius,
    required this.background,
    required this.borderColor,
    required this.shadowColor,
  });

  final _Swoop swoop;
  final double barPadding;
  final double lineWidth;

  /// Top corner radius (0 = square).
  final double radius;
  final Color background;
  final Color borderColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );

    // Everything except the notch above the curve.
    final notch = swoop.notchPath(dx: barPadding, y0: lineWidth / 2);
    final visible = Path.combine(
      PathOperation.difference,
      Path()
        ..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
      notch,
    );

    canvas.save();
    canvas.clipPath(visible);

    // Soft shadow, background, then the thin line along the top.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(rrect, Paint()..color = background);
    canvas.drawLine(
      Offset(0, lineWidth / 2),
      Offset(size.width, lineWidth / 2),
      Paint()
        ..color = borderColor
        ..strokeWidth = lineWidth
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PillPainter old) =>
      !old.swoop.sameAs(swoop) ||
      old.background != background ||
      old.borderColor != borderColor ||
      old.shadowColor != shadowColor;
}

/// The thin curved line that dips down from the top edge of the bar.
class _SwoopLinePainter extends CustomPainter {
  _SwoopLinePainter({
    required this.swoop,
    required this.color,
    required this.strokeWidth,
  });

  final _Swoop swoop;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      swoop.linePath(y0: strokeWidth / 2),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _SwoopLinePainter old) =>
      !old.swoop.sameAs(swoop) ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// Small crescent moon: a circle with a shifted circle cut out of it.
class _CrescentPainter extends CustomPainter {
  _CrescentPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final outer = Path()
      ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
    final cut = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(r + r * 0.55, r - r * 0.25),
          radius: r * 0.85,
        ),
      );

    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, cut),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter old) => old.color != color;
}
