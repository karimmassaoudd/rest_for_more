// Fitht version moon navbar with smooth animation and liquid swoop line
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppNavItem {
  final IconData icon;
  final String label; // used for accessibility only
  const AppNavItem({required this.icon, required this.label});
}

/// The four tabs, in order.
const List<AppNavItem> kAppNavItems = [
  AppNavItem(icon: Icons.home_rounded, label: 'Today'),
  AppNavItem(icon: Icons.auto_graph_rounded, label: 'Progress'),
  AppNavItem(icon: Icons.tune_rounded, label: 'Settings'),
  AppNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
];

/// The floating pill-shaped navigation bar with a liquid swoop line and a crescent moon above the selected tab.
class AppBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Colour of the crescent moon.
  final Color moonColor;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.moonColor = const Color(0xFFFFC857),
  });

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  static const double _barHeight = 66;
  static const double _barPadding = 6;
  static const double _barRadius = 16;
  static const double _iconBottomOffset = 6;

  static const double _swoopHalfWidth = 32;
  static const double _swoopDepth = 14; // resting depth of the dip
  static const double _lineWidth = 1;

  static const double _moonSize = 21;
  static const double _moonGap = 5;
  static const double _moonTilt = -0.5; // radians, negative = tilted left

  /// How much thicker the selected icon looks (in logical pixels).
  static const double _iconBoldness = 0.5;

  late final AnimationController _controller;

  /// Fractional tab positions the liquid travels between.
  late double _from;
  late double _to;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.currentIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 1, // start settled on the current tab
    );
  }

  @override
  void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Start from wherever the liquid visually is right now, so quick
      // taps flow smoothly instead of jumping.
      final p = Curves.easeInOutSine.transform(_controller.value);
      _from = _from + (_to - _from) * p;
      _to = widget.currentIndex.toDouble();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Everything about the swoop/moon at the current animation frame, in the coordinate space of the bar's inner (padded) area.
  _Swoop _geometry(double itemWidth) {
    final t = _controller.value;
    final p = Curves.easeInOutSine.transform(t);
    final distance = (_to - _from) * itemWidth;
    final direction = distance.sign;
    final center = (_from + (_to - _from) * p + 0.5) * itemWidth;

    // Smoothly fades in/out, so the shape is exactly at rest at either end.
    final envelope = math.pow(math.sin(math.pi * t), 2).toDouble();
    final travelScale = (distance.abs() / (itemWidth * 1.5)).clamp(0.0, 1.0);
    final wave = math.sin(3.5 * math.pi * t);
    final secondaryWave = math.sin(5 * math.pi * t + 0.7);

    // The blob grows as it pours down, then contracts while climbing back up.
    final widthPulse = envelope * travelScale * (7 + 2.5 * wave);
    final halfWidth = _swoopHalfWidth + widthPulse;
    final skew = direction * envelope * travelScale * (5 + 3 * wave);
    final depth =
        _swoopDepth +
        envelope * travelScale * (8 + 2.5 * wave + 1.2 * secondaryWave);

    return _Swoop(
      left: center - halfWidth + skew * 0.25,
      right: center + halfWidth + skew * 0.25,
      bottomX: center + skew,
      depth: depth,
      moonCenter: center + skew * 0.15,
      hop: envelope * (2.5 + 1.2 * wave),
      lean: direction * envelope * 0.10,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Space reserved for the phone's system navigation area.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Keep space above the bar for the crescent moon.
      // No side or bottom margins.
      padding: const EdgeInsets.only(top: _moonSize + _moonGap + 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - _barPadding * 2;

          final itemWidth = contentWidth / kAppNavItems.length;

          final tabs = Row(
            children: [
              for (int i = 0; i < kAppNavItems.length; i++)
                Expanded(child: _buildItem(i)),
            ],
          );

          return SizedBox(
            // Extend the painted bar into the system bottom area.
            height: _barHeight + bottomInset,
            child: AnimatedBuilder(
              animation: _controller,
              child: tabs,
              builder: (context, tabs) {
                final swoop = _geometry(itemWidth);

                return CustomPaint(
                  painter: _PillPainter(
                    swoop: swoop,
                    barPadding: _barPadding,
                    lineWidth: _lineWidth,
                    radius: _barRadius,
                    background: AppColors.background,
                    borderColor: AppColors.surface,
                    shadowColor: AppColors.darkbrown.withValues(alpha: 0.12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      _barPadding,
                      _barPadding,
                      _barPadding,
                      _barPadding + bottomInset,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: IgnorePointer(
                            child: _buildLiquid(swoop, contentWidth),
                          ),
                        ),
                        tabs!,
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiquid(_Swoop swoop, double contentWidth) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: -_barPadding,
          width: contentWidth,
          height: _swoopDepth + 16 + _lineWidth,
          child: CustomPaint(
            painter: _SwoopLinePainter(
              swoop: swoop,
              color: AppColors.mediumbrown,
              strokeWidth: _lineWidth,
            ),
          ),
        ),
        Positioned(
          left: swoop.moonCenter - _moonSize / 2,
          top: -_barPadding - _moonGap - _moonSize - swoop.hop,
          width: _moonSize,
          height: _moonSize,
          child: Transform.rotate(
            angle: _moonTilt + swoop.lean,
            child: CustomPaint(
              painter: _CrescentPainter(color: widget.moonColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int index) {
    final selected = index == widget.currentIndex;
    final item = kAppNavItems[index];

    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(index),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, _iconBottomOffset),
            child: AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: selected ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 250),
                builder: (context, t, _) {
                  final color = Color.lerp(
                    AppColors.darkbrown,
                    AppColors.mediumbrown,
                    t,
                  )!;
                  final bold = _iconBoldness * t;

                  // Same-colour, zero-blur shadows nudged in four directions
                  // thicken the glyph strokes (a "faux bold" for icon fonts).
                  return Icon(
                    item.icon,
                    size: 24,
                    color: color,
                    shadows: t == 0
                        ? null
                        : [
                            Shadow(color: color, offset: Offset(bold, 0)),
                            Shadow(color: color, offset: Offset(-bold, 0)),
                            Shadow(color: color, offset: Offset(0, bold)),
                            Shadow(color: color, offset: Offset(0, -bold)),
                          ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snapshot of the swoop + moon for one animation frame.
class _Swoop {
  final double left;
  final double right;
  final double bottomX;
  final double depth;
  final double moonCenter;
  final double hop;
  final double lean;

  const _Swoop({
    required this.left,
    required this.right,
    required this.bottomX,
    required this.depth,
    required this.moonCenter,
    required this.hop,
    required this.lean,
  });

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

  /// The closed region between the top edge of the bar and the curve.
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

  bool sameAs(_Swoop o) =>
      o.left == left &&
      o.right == right &&
      o.bottomX == bottomX &&
      o.depth == depth;
}

/// Paints the pill with the swoop region cut out, so the area above the
/// brown line is transparent and the page shows through.
class _PillPainter extends CustomPainter {
  final _Swoop swoop;
  final double barPadding;
  final double lineWidth;
  final double radius;
  final Color background;
  final Color borderColor;
  final Color shadowColor;

  _PillPainter({
    required this.swoop,
    required this.barPadding,
    required this.lineWidth,
    required this.radius,
    required this.background,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
      bottomLeft: Radius.zero,
      bottomRight: Radius.zero,
    );

    final notch = swoop.notchPath(dx: barPadding, y0: lineWidth / 2);
    final visible = Path.combine(
      PathOperation.difference,
      Path()
        ..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
      notch,
    );

    canvas.save();
    canvas.clipPath(visible);

    // Shadow, fill, border.
    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(rrect, Paint()..color = background);
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
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

/// Thin curved line that dips down from the top edge of the bar.
class _SwoopLinePainter extends CustomPainter {
  final _Swoop swoop;
  final Color color;
  final double strokeWidth;

  _SwoopLinePainter({
    required this.swoop,
    required this.color,
    required this.strokeWidth,
  });

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
  final Color color;
  _CrescentPainter({required this.color});

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

// Fourth version moon navbar with smooth animation and liquid swoop line
// import 'dart:math' as math;

// import 'package:flutter/material.dart';

// import '../theme/app_colors.dart';

// class AppNavItem {
//   final IconData icon;
//   final String label; // used for accessibility only
//   const AppNavItem({required this.icon, required this.label});
// }

// /// The four tabs, in order.
// const List<AppNavItem> kAppNavItems = [
//   AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
//   AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
//   AppNavItem(icon: Icons.tune, label: 'Settings'),
//   AppNavItem(icon: Icons.person_outline, label: 'Profile'),
// ];

// /// The floating pill-shaped navigation bar with a liquid swoop line
// /// (cut out of the bar, so it's transparent above the line)
// /// and a crescent moon above the selected tab.
// class AppBottomNavBar extends StatefulWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   /// Colour of the crescent moon.
//   final Color moonColor;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.moonColor = const Color(0xFFFFC857),
//   });

//   @override
//   State<AppBottomNavBar> createState() => _AppBottomNavBarState();
// }

// class _AppBottomNavBarState extends State<AppBottomNavBar>
//     with SingleTickerProviderStateMixin {
//   static const double _barHeight = 66;
//   static const double _barPadding = 6;
//   static const double _barRadius = 30;

//   static const double _swoopHalfWidth = 32;
//   static const double _swoopDepth = 14; // resting depth of the dip
//   static const double _diveExtra = 7; // extra depth while travelling
//   static const double _lineWidth = 3;

//   static const double _moonSize = 21;
//   static const double _moonGap = 5;
//   static const double _moonTilt = -0.5; // radians, negative = tilted left

//   /// How much thicker the selected icon looks (in logical pixels).
//   static const double _iconBoldness = 0.7;

//   late final AnimationController _controller;

//   /// Fractional tab positions the liquid travels between.
//   late double _from;
//   late double _to;

//   @override
//   void initState() {
//     super.initState();
//     _from = _to = widget.currentIndex.toDouble();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 850),
//       value: 1, // start settled on the current tab
//     );
//   }

//   @override
//   void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.currentIndex != widget.currentIndex) {
//       // Start from wherever the liquid visually is right now, so quick
//       // taps flow smoothly instead of jumping.
//       final p = Curves.easeInOutSine.transform(_controller.value);
//       _from = _from + (_to - _from) * p;
//       _to = widget.currentIndex.toDouble();
//       _controller.forward(from: 0);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   /// Everything about the swoop/moon at the current animation frame,
//   /// in the coordinate space of the bar's inner (padded) area.
//   _Swoop _geometry(double itemWidth) {
//     // One continuous, eased movement, with a small fluid wake.
//     final p = Curves.easeInOutSine.transform(_controller.value);
//     final distance = (_to - _from) * itemWidth;
//     final center = (_from + (_to - _from) * p + 0.5) * itemWidth;
//     final direction = distance.sign;

//     // Zero at both ends: no sudden shape change when settling.
//     final flow = math.pow(math.sin(math.pi * p), 2).toDouble();
//     final stretch = math.min(distance.abs() / (itemWidth * 3), 1.0);
//     final halfWidth = _swoopHalfWidth + 6 * stretch * flow;
//     final wake = direction * 5 * stretch * flow;
//     final depth = _swoopDepth + _diveExtra * flow;

//     return _Swoop(
//       left: center - halfWidth + wake * 0.25,
//       right: center + halfWidth + wake * 0.25,
//       bottomX: center + wake,
//       depth: depth,
//       moonCenter: center,
//       hop: 3 * flow,
//       lean: direction * 0.12 * flow,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         // Extra top padding reserves room for the moon above the pill.
//         padding: const EdgeInsets.fromLTRB(
//           16,
//           _moonSize + _moonGap + 8,
//           16,
//           12,
//         ),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final contentWidth = constraints.maxWidth - _barPadding * 2;
//             final itemWidth = contentWidth / kAppNavItems.length;

//             final tabs = Row(
//               children: [
//                 for (int i = 0; i < kAppNavItems.length; i++)
//                   Expanded(child: _buildItem(i)),
//               ],
//             );

//             return SizedBox(
//               height: _barHeight,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 child: tabs,
//                 builder: (context, tabs) {
//                   final swoop = _geometry(itemWidth);

//                   return CustomPaint(
//                     painter: _PillPainter(
//                       swoop: swoop,
//                       barPadding: _barPadding,
//                       lineWidth: _lineWidth,
//                       radius: _barRadius,
//                       background: AppColors.background,
//                       borderColor: AppColors.surface,
//                       shadowColor: AppColors.darkbrown.withValues(alpha: 0.12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(_barPadding),
//                       child: Stack(
//                         clipBehavior: Clip.none,
//                         children: [
//                           Positioned.fill(
//                             child: IgnorePointer(
//                               child: _buildLiquid(swoop, contentWidth),
//                             ),
//                           ),
//                           tabs!,
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildLiquid(_Swoop swoop, double contentWidth) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Positioned(
//           left: 0,
//           top: -_barPadding,
//           width: contentWidth,
//           height: _swoopDepth + _diveExtra + _lineWidth,
//           child: CustomPaint(
//             painter: _SwoopLinePainter(
//               swoop: swoop,
//               color: AppColors.mediumbrown,
//               strokeWidth: _lineWidth,
//             ),
//           ),
//         ),
//         Positioned(
//           left: swoop.moonCenter - _moonSize / 2,
//           top: -_barPadding - _moonGap - _moonSize - swoop.hop,
//           width: _moonSize,
//           height: _moonSize,
//           child: Transform.rotate(
//             angle: _moonTilt + swoop.lean,
//             child: CustomPaint(
//               painter: _CrescentPainter(color: widget.moonColor),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildItem(int index) {
//     final selected = index == widget.currentIndex;
//     final item = kAppNavItems[index];

//     return Semantics(
//       label: item.label,
//       selected: selected,
//       button: true,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => widget.onTap(index),
//         child: Center(
//           child: AnimatedScale(
//             scale: selected ? 1.1 : 1.0,
//             duration: const Duration(milliseconds: 250),
//             curve: Curves.easeOut,
//             child: TweenAnimationBuilder<double>(
//               tween: Tween<double>(end: selected ? 1.0 : 0.0),
//               duration: const Duration(milliseconds: 250),
//               builder: (context, t, _) {
//                 final color = Color.lerp(
//                   AppColors.darkbrown,
//                   AppColors.mediumbrown,
//                   t,
//                 )!;
//                 final bold = _iconBoldness * t;

//                 // Same-colour, zero-blur shadows nudged in four directions
//                 // thicken the glyph strokes (a "faux bold" for icon fonts).
//                 return Icon(
//                   item.icon,
//                   size: 24,
//                   color: color,
//                   shadows: t == 0
//                       ? null
//                       : [
//                           Shadow(color: color, offset: Offset(bold, 0)),
//                           Shadow(color: color, offset: Offset(-bold, 0)),
//                           Shadow(color: color, offset: Offset(0, bold)),
//                           Shadow(color: color, offset: Offset(0, -bold)),
//                         ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Snapshot of the swoop + moon for one animation frame.
// class _Swoop {
//   final double left;
//   final double right;
//   final double bottomX;
//   final double depth;
//   final double moonCenter;
//   final double hop;
//   final double lean;

//   const _Swoop({
//     required this.left,
//     required this.right,
//     required this.bottomX,
//     required this.depth,
//     required this.moonCenter,
//     required this.hop,
//     required this.lean,
//   });

//   /// Adds the two curve segments; the path must already be at
//   /// (left + dx, y0).
//   void _appendCurve(Path p, double dx, double y0) {
//     final l = left + dx;
//     final r = right + dx;
//     final b = bottomX + dx;
//     final yb = y0 + depth;

//     p
//       ..cubicTo(l + (b - l) * 0.52, y0, b - (b - l) * 0.52, yb, b, yb)
//       ..cubicTo(b + (r - b) * 0.52, yb, r - (r - b) * 0.52, y0, r, y0);
//   }

//   /// Just the curved line.
//   Path linePath({double dx = 0, required double y0}) {
//     final p = Path()..moveTo(left + dx, y0);
//     _appendCurve(p, dx, y0);
//     return p;
//   }

//   /// The closed region between the top edge of the bar and the curve.
//   Path notchPath({double dx = 0, required double y0}) {
//     final p = Path()
//       ..moveTo(left + dx, -40)
//       ..lineTo(left + dx, y0);
//     _appendCurve(p, dx, y0);
//     p
//       ..lineTo(right + dx, -40)
//       ..close();
//     return p;
//   }

//   bool sameAs(_Swoop o) =>
//       o.left == left &&
//       o.right == right &&
//       o.bottomX == bottomX &&
//       o.depth == depth;
// }

// /// Paints the pill with the swoop region cut out, so the area above the
// /// brown line is transparent and the page shows through.
// class _PillPainter extends CustomPainter {
//   final _Swoop swoop;
//   final double barPadding;
//   final double lineWidth;
//   final double radius;
//   final Color background;
//   final Color borderColor;
//   final Color shadowColor;

//   _PillPainter({
//     required this.swoop,
//     required this.barPadding,
//     required this.lineWidth,
//     required this.radius,
//     required this.background,
//     required this.borderColor,
//     required this.shadowColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rrect = RRect.fromRectAndRadius(
//       Offset.zero & size,
//       Radius.circular(radius),
//     );

//     final notch = swoop.notchPath(dx: barPadding, y0: lineWidth / 2);
//     final visible = Path.combine(
//       PathOperation.difference,
//       Path()
//         ..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
//       notch,
//     );

//     canvas.save();
//     canvas.clipPath(visible);

//     // Shadow, fill, border.
//     canvas.drawRRect(
//       rrect.shift(const Offset(0, 4)),
//       Paint()
//         ..color = shadowColor
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//     );
//     canvas.drawRRect(rrect, Paint()..color = background);
//     canvas.drawRRect(
//       rrect.deflate(0.5),
//       Paint()
//         ..color = borderColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1,
//     );

//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(covariant _PillPainter old) =>
//       !old.swoop.sameAs(swoop) ||
//       old.background != background ||
//       old.borderColor != borderColor ||
//       old.shadowColor != shadowColor;
// }

// /// Thin curved line that dips down from the top edge of the bar.
// class _SwoopLinePainter extends CustomPainter {
//   final _Swoop swoop;
//   final Color color;
//   final double strokeWidth;

//   _SwoopLinePainter({
//     required this.swoop,
//     required this.color,
//     required this.strokeWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawPath(
//       swoop.linePath(y0: strokeWidth / 2),
//       Paint()
//         ..color = color
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round
//         ..isAntiAlias = true,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _SwoopLinePainter old) =>
//       !old.swoop.sameAs(swoop) ||
//       old.color != color ||
//       old.strokeWidth != strokeWidth;
// }

// /// Small crescent moon: a circle with a shifted circle cut out of it.
// class _CrescentPainter extends CustomPainter {
//   final Color color;
//   _CrescentPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = size.width / 2;
//     final outer = Path()
//       ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
//     final cut = Path()
//       ..addOval(
//         Rect.fromCircle(
//           center: Offset(r + r * 0.55, r - r * 0.25),
//           radius: r * 0.85,
//         ),
//       );

//     canvas.drawPath(
//       Path.combine(PathOperation.difference, outer, cut),
//       Paint()..color = color,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _CrescentPainter old) => old.color != color;
// }

// Third version moon navbar with smooth animation and liquid swoop line
// import 'dart:math' as math;

// import 'package:flutter/material.dart';

// import '../theme/app_colors.dart';

// class AppNavItem {
//   final IconData icon;
//   final String label; // used for accessibility only
//   const AppNavItem({required this.icon, required this.label});
// }

// /// The four tabs, in order.
// const List<AppNavItem> kAppNavItems = [
//   AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
//   AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
//   AppNavItem(icon: Icons.tune, label: 'Settings'),
//   AppNavItem(icon: Icons.person_outline, label: 'Profile'),
// ];

// /// The floating pill-shaped navigation bar with a liquid swoop line
// /// (cut out of the bar, so it's transparent above the line)
// /// and a crescent moon above the selected tab.
// class AppBottomNavBar extends StatefulWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   /// Colour of the crescent moon.
//   final Color moonColor;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.moonColor = const Color(0xFFFFC857),
//   });

//   @override
//   State<AppBottomNavBar> createState() => _AppBottomNavBarState();
// }

// class _AppBottomNavBarState extends State<AppBottomNavBar>
//     with SingleTickerProviderStateMixin {
//   static const double _barHeight = 66;
//   static const double _barPadding = 6;
//   static const double _barRadius = 30;

//   static const double _swoopHalfWidth = 32;
//   static const double _swoopDepth = 14; // resting depth of the dip
//   static const double _diveExtra = 10; // extra depth while travelling
//   static const double _lineWidth = 3;

//   static const double _moonSize = 21;
//   static const double _moonGap = 5;
//   static const double _moonTilt = -0.5; // radians, negative = tilted left

//   /// How much thicker the selected icon looks (in logical pixels).
//   static const double _iconBoldness = 0.7;

//   late final AnimationController _controller;

//   /// Fractional tab positions the liquid travels between.
//   late double _from;
//   late double _to;

//   @override
//   void initState() {
//     super.initState();
//     _from = _to = widget.currentIndex.toDouble();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//       value: 1, // start settled on the current tab
//     );
//   }

//   @override
//   void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.currentIndex != widget.currentIndex) {
//       // Start from wherever the liquid visually is right now, so quick
//       // taps flow smoothly instead of jumping.
//       final p = _controller.value;
//       final lead = Curves.easeOutCubic.transform(p);
//       final trail = Curves.easeInOutCubic.transform(p);
//       _from = _from + (_to - _from) * ((lead + trail) / 2);
//       _to = widget.currentIndex.toDouble();
//       _controller.forward(from: 0);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   /// Everything about the swoop/moon at the current animation frame,
//   /// in the coordinate space of the bar's inner (padded) area.
//   _Swoop _geometry(double itemWidth) {
//     final p = _controller.value;
//     final dir = (_to - _from) >= 0 ? 1.0 : -1.0;

//     // The leading edge rushes ahead while the trailing edge lags behind,
//     // so the curve stretches and then snaps back together like liquid.
//     final lead = Curves.easeOutCubic.transform(p);
//     final trail = Curves.easeInOutCubic.transform(p);

//     final cFrom = _from * itemWidth + itemWidth / 2;
//     final cTo = _to * itemWidth + itemWidth / 2;
//     final leadCenter = cFrom + (cTo - cFrom) * lead;
//     final trailCenter = cFrom + (cTo - cFrom) * trail;

//     final double left;
//     final double right;
//     if (dir > 0) {
//       right = leadCenter + _swoopHalfWidth;
//       left = trailCenter - _swoopHalfWidth;
//     } else {
//       left = leadCenter - _swoopHalfWidth;
//       right = trailCenter + _swoopHalfWidth;
//     }

//     final stretch = (lead - trail).abs(); // 0 when settled
//     final dive = math.sin(math.pi * p); // 0 -> 1 -> 0 over the animation

//     // Goes down while travelling, then rises back up to its resting depth.
//     final depth = _swoopDepth * (1 - 0.4 * stretch) + _diveExtra * dive;
//     final bottomX =
//         (left + right) / 2 + dir * stretch * (cTo - cFrom).abs() * 0.25;

//     return _Swoop(
//       left: left,
//       right: right,
//       bottomX: bottomX,
//       depth: depth,
//       moonCenter: (left + right) / 2,
//       hop: dive * 5,
//       lean: dir * 0.3 * dive,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         // Extra top padding reserves room for the moon above the pill.
//         padding: const EdgeInsets.fromLTRB(
//           16,
//           _moonSize + _moonGap + 8,
//           16,
//           12,
//         ),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             final contentWidth = constraints.maxWidth - _barPadding * 2;
//             final itemWidth = contentWidth / kAppNavItems.length;

//             final tabs = Row(
//               children: [
//                 for (int i = 0; i < kAppNavItems.length; i++)
//                   Expanded(child: _buildItem(i)),
//               ],
//             );

//             return SizedBox(
//               height: _barHeight,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 child: tabs,
//                 builder: (context, tabs) {
//                   final swoop = _geometry(itemWidth);

//                   return CustomPaint(
//                     painter: _PillPainter(
//                       swoop: swoop,
//                       barPadding: _barPadding,
//                       lineWidth: _lineWidth,
//                       radius: _barRadius,
//                       background: AppColors.background,
//                       borderColor: AppColors.surface,
//                       shadowColor: AppColors.darkbrown.withValues(alpha: 0.12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(_barPadding),
//                       child: Stack(
//                         clipBehavior: Clip.none,
//                         children: [
//                           Positioned.fill(
//                             child: IgnorePointer(
//                               child: _buildLiquid(swoop, contentWidth),
//                             ),
//                           ),
//                           tabs!,
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildLiquid(_Swoop swoop, double contentWidth) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Positioned(
//           left: 0,
//           top: -_barPadding,
//           width: contentWidth,
//           height: _swoopDepth + _diveExtra + _lineWidth,
//           child: CustomPaint(
//             painter: _SwoopLinePainter(
//               swoop: swoop,
//               color: AppColors.mediumbrown,
//               strokeWidth: _lineWidth,
//             ),
//           ),
//         ),
//         Positioned(
//           left: swoop.moonCenter - _moonSize / 2,
//           top: -_barPadding - _moonGap - _moonSize - swoop.hop,
//           width: _moonSize,
//           height: _moonSize,
//           child: Transform.rotate(
//             angle: _moonTilt + swoop.lean,
//             child: CustomPaint(
//               painter: _CrescentPainter(color: widget.moonColor),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildItem(int index) {
//     final selected = index == widget.currentIndex;
//     final item = kAppNavItems[index];

//     return Semantics(
//       label: item.label,
//       selected: selected,
//       button: true,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => widget.onTap(index),
//         child: Center(
//           child: AnimatedScale(
//             scale: selected ? 1.1 : 1.0,
//             duration: const Duration(milliseconds: 250),
//             curve: Curves.easeOut,
//             child: TweenAnimationBuilder<double>(
//               tween: Tween<double>(end: selected ? 1.0 : 0.0),
//               duration: const Duration(milliseconds: 250),
//               builder: (context, t, _) {
//                 final color = Color.lerp(
//                   AppColors.darkbrown,
//                   AppColors.mediumbrown,
//                   t,
//                 )!;
//                 final bold = _iconBoldness * t;

//                 // Same-colour, zero-blur shadows nudged in four directions
//                 // thicken the glyph strokes (a "faux bold" for icon fonts).
//                 return Icon(
//                   item.icon,
//                   size: 24,
//                   color: color,
//                   shadows: t == 0
//                       ? null
//                       : [
//                           Shadow(color: color, offset: Offset(bold, 0)),
//                           Shadow(color: color, offset: Offset(-bold, 0)),
//                           Shadow(color: color, offset: Offset(0, bold)),
//                           Shadow(color: color, offset: Offset(0, -bold)),
//                         ],
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Snapshot of the swoop + moon for one animation frame.
// class _Swoop {
//   final double left;
//   final double right;
//   final double bottomX;
//   final double depth;
//   final double moonCenter;
//   final double hop;
//   final double lean;

//   const _Swoop({
//     required this.left,
//     required this.right,
//     required this.bottomX,
//     required this.depth,
//     required this.moonCenter,
//     required this.hop,
//     required this.lean,
//   });

//   /// Adds the two curve segments; the path must already be at
//   /// (left + dx, y0).
//   void _appendCurve(Path p, double dx, double y0) {
//     final l = left + dx;
//     final r = right + dx;
//     final b = bottomX + dx;
//     final yb = y0 + depth;

//     p
//       ..cubicTo(l + (b - l) * 0.5, y0, l + (b - l) * 0.6, yb, b, yb)
//       ..cubicTo(b + (r - b) * 0.4, yb, b + (r - b) * 0.5, y0, r, y0);
//   }

//   /// Just the curved line.
//   Path linePath({double dx = 0, required double y0}) {
//     final p = Path()..moveTo(left + dx, y0);
//     _appendCurve(p, dx, y0);
//     return p;
//   }

//   /// The closed region between the top edge of the bar and the curve.
//   Path notchPath({double dx = 0, required double y0}) {
//     final p = Path()
//       ..moveTo(left + dx, -40)
//       ..lineTo(left + dx, y0);
//     _appendCurve(p, dx, y0);
//     p
//       ..lineTo(right + dx, -40)
//       ..close();
//     return p;
//   }

//   bool sameAs(_Swoop o) =>
//       o.left == left &&
//       o.right == right &&
//       o.bottomX == bottomX &&
//       o.depth == depth;
// }

// /// Paints the pill with the swoop region cut out, so the area above the
// /// brown line is transparent and the page shows through.
// class _PillPainter extends CustomPainter {
//   final _Swoop swoop;
//   final double barPadding;
//   final double lineWidth;
//   final double radius;
//   final Color background;
//   final Color borderColor;
//   final Color shadowColor;

//   _PillPainter({
//     required this.swoop,
//     required this.barPadding,
//     required this.lineWidth,
//     required this.radius,
//     required this.background,
//     required this.borderColor,
//     required this.shadowColor,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final rrect = RRect.fromRectAndRadius(
//       Offset.zero & size,
//       Radius.circular(radius),
//     );

//     final notch = swoop.notchPath(dx: barPadding, y0: lineWidth / 2);
//     final visible = Path.combine(
//       PathOperation.difference,
//       Path()
//         ..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
//       notch,
//     );

//     canvas.save();
//     canvas.clipPath(visible);

//     // Shadow, fill, border.
//     canvas.drawRRect(
//       rrect.shift(const Offset(0, 4)),
//       Paint()
//         ..color = shadowColor
//         ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
//     );
//     canvas.drawRRect(rrect, Paint()..color = background);
//     canvas.drawRRect(
//       rrect.deflate(0.5),
//       Paint()
//         ..color = borderColor
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1,
//     );

//     canvas.restore();
//   }

//   @override
//   bool shouldRepaint(covariant _PillPainter old) =>
//       !old.swoop.sameAs(swoop) ||
//       old.background != background ||
//       old.borderColor != borderColor ||
//       old.shadowColor != shadowColor;
// }

// /// Thin curved line that dips down from the top edge of the bar.
// class _SwoopLinePainter extends CustomPainter {
//   final _Swoop swoop;
//   final Color color;
//   final double strokeWidth;

//   _SwoopLinePainter({
//     required this.swoop,
//     required this.color,
//     required this.strokeWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     canvas.drawPath(
//       swoop.linePath(y0: strokeWidth / 2),
//       Paint()
//         ..color = color
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round
//         ..isAntiAlias = true,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _SwoopLinePainter old) =>
//       !old.swoop.sameAs(swoop) ||
//       old.color != color ||
//       old.strokeWidth != strokeWidth;
// }

// /// Small crescent moon: a circle with a shifted circle cut out of it.
// class _CrescentPainter extends CustomPainter {
//   final Color color;
//   _CrescentPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = size.width / 2;
//     final outer = Path()
//       ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
//     final cut = Path()
//       ..addOval(
//         Rect.fromCircle(
//           center: Offset(r + r * 0.55, r - r * 0.25),
//           radius: r * 0.85,
//         ),
//       );

//     canvas.drawPath(
//       Path.combine(PathOperation.difference, outer, cut),
//       Paint()..color = color,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _CrescentPainter old) => old.color != color;
// }

// Second version moon navbar with smooth animation
// import 'dart:math' as math;

// import 'package:flutter/material.dart';

// import '../theme/app_colors.dart';

// class AppNavItem {
//   final IconData icon;
//   final String label; // used for accessibility only
//   const AppNavItem({required this.icon, required this.label});
// }

// /// The four tabs, in order.
// const List<AppNavItem> kAppNavItems = [
//   AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
//   AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
//   AppNavItem(icon: Icons.tune, label: 'Settings'),
//   AppNavItem(icon: Icons.person_outline, label: 'Profile'),
// ];

// /// The floating pill-shaped navigation bar with a liquid swoop line
// /// and a crescent moon above the selected tab.
// class AppBottomNavBar extends StatefulWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   /// Colour of the crescent moon.
//   final Color moonColor;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.moonColor = const Color(0xFFFFC857),
//   });

//   @override
//   State<AppBottomNavBar> createState() => _AppBottomNavBarState();
// }

// class _AppBottomNavBarState extends State<AppBottomNavBar>
//     with SingleTickerProviderStateMixin {
//   static const double _barPadding = 6;
//   static const double _swoopHalfWidth = 32;
//   static const double _swoopDepth = 14;
//   static const double _lineWidth = 3;
//   static const double _moonSize = 21;
//   static const double _moonGap = 5;
//   static const double _moonTilt = -0.5; // radians, negative = tilted left

//   late final AnimationController _controller;

//   /// Fractional tab positions the liquid travels between.
//   late double _from;
//   late double _to;

//   @override
//   void initState() {
//     super.initState();
//     _from = _to = widget.currentIndex.toDouble();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//       value: 1, // start settled on the current tab
//     );
//   }

//   @override
//   void didUpdateWidget(covariant AppBottomNavBar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.currentIndex != widget.currentIndex) {
//       // Start from wherever the liquid visually is right now, so quick
//       // taps flow smoothly instead of jumping.
//       final p = _controller.value;
//       final lead = Curves.easeOutCubic.transform(p);
//       final trail = Curves.easeInOutCubic.transform(p);
//       _from = _from + (_to - _from) * ((lead + trail) / 2);
//       _to = widget.currentIndex.toDouble();
//       _controller.forward(from: 0);
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         // Extra top padding reserves room for the moon above the pill.
//         padding: const EdgeInsets.fromLTRB(
//           16,
//           _moonSize + _moonGap + 8,
//           16,
//           12,
//         ),
//         child: Container(
//           height: 66,
//           padding: const EdgeInsets.all(_barPadding),
//           decoration: BoxDecoration(
//             color: AppColors.background,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(color: AppColors.surface, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.darkbrown.withValues(alpha: 0.12),
//                 blurRadius: 16,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final width = constraints.maxWidth;
//               final itemWidth = width / kAppNavItems.length;

//               return Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   // Liquid swoop line + moon, both driven by the controller.
//                   Positioned.fill(
//                     child: IgnorePointer(
//                       child: AnimatedBuilder(
//                         animation: _controller,
//                         builder: (context, _) => _buildLiquid(width, itemWidth),
//                       ),
//                     ),
//                   ),

//                   // Tabs.
//                   Row(
//                     children: [
//                       for (int i = 0; i < kAppNavItems.length; i++)
//                         Expanded(child: _buildItem(i)),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLiquid(double width, double itemWidth) {
//     final p = _controller.value;
//     final dir = (_to - _from) >= 0 ? 1.0 : -1.0;

//     // The leading edge rushes ahead while the trailing edge lags behind,
//     // so the curve stretches and then snaps back together like liquid.
//     final lead = Curves.easeOutCubic.transform(p);
//     final trail = Curves.easeInOutCubic.transform(p);

//     final cFrom = _from * itemWidth + itemWidth / 2;
//     final cTo = _to * itemWidth + itemWidth / 2;
//     final leadCenter = cFrom + (cTo - cFrom) * lead;
//     final trailCenter = cFrom + (cTo - cFrom) * trail;

//     final double left;
//     final double right;
//     if (dir > 0) {
//       right = leadCenter + _swoopHalfWidth;
//       left = trailCenter - _swoopHalfWidth;
//     } else {
//       left = leadCenter - _swoopHalfWidth;
//       right = trailCenter + _swoopHalfWidth;
//     }

//     final stretch = (lead - trail).abs(); // 0 when settled
//     final depth = _swoopDepth * (1 - 0.8 * stretch); // flattens while moving
//     final bottomX =
//         (left + right) / 2 + dir * stretch * (cTo - cFrom).abs() * 0.25;

//     // Moon rides along with the middle of the liquid and hops a little.
//     final moonCenter = (left + right) / 2;
//     final hop = math.sin(math.pi * p) * 5;
//     final lean = dir * 0.3 * math.sin(math.pi * p);

//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Positioned(
//           left: 0,
//           top: -_barPadding,
//           width: width,
//           height: _swoopDepth + _lineWidth,
//           child: CustomPaint(
//             painter: _SwoopLinePainter(
//               left: left,
//               right: right,
//               bottomX: bottomX,
//               depth: depth,
//               color: AppColors.mediumbrown,
//               strokeWidth: _lineWidth,
//             ),
//           ),
//         ),
//         Positioned(
//           left: moonCenter - _moonSize / 2,
//           top: -_barPadding - _moonGap - _moonSize - hop,
//           width: _moonSize,
//           height: _moonSize,
//           child: Transform.rotate(
//             angle: _moonTilt + lean,
//             child: CustomPaint(
//               painter: _CrescentPainter(color: widget.moonColor),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildItem(int index) {
//     final selected = index == widget.currentIndex;
//     final item = kAppNavItems[index];

//     return Semantics(
//       label: item.label,
//       selected: selected,
//       button: true,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => widget.onTap(index),
//         child: Center(
//           child: AnimatedScale(
//             scale: selected ? 1.15 : 1.0,
//             duration: const Duration(milliseconds: 250),
//             curve: Curves.easeOut,
//             child: TweenAnimationBuilder<Color?>(
//               tween: ColorTween(
//                 end: selected ? AppColors.mediumbrown : AppColors.darkbrown,
//               ),
//               duration: const Duration(milliseconds: 250),
//               builder: (context, color, _) =>
//                   Icon(item.icon, size: 24, color: color),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Thin curved line that dips down from the top edge of the bar.
// class _SwoopLinePainter extends CustomPainter {
//   final double left;
//   final double right;
//   final double bottomX;
//   final double depth;
//   final Color color;
//   final double strokeWidth;

//   _SwoopLinePainter({
//     required this.left,
//     required this.right,
//     required this.bottomX,
//     required this.depth,
//     required this.color,
//     required this.strokeWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final y0 = strokeWidth / 2;
//     final yb = y0 + depth;

//     final path = Path()
//       ..moveTo(left, y0)
//       ..cubicTo(
//         left + (bottomX - left) * 0.5,
//         y0,
//         left + (bottomX - left) * 0.6,
//         yb,
//         bottomX,
//         yb,
//       )
//       ..cubicTo(
//         bottomX + (right - bottomX) * 0.4,
//         yb,
//         bottomX + (right - bottomX) * 0.5,
//         y0,
//         right,
//         y0,
//       );

//     canvas.drawPath(
//       path,
//       Paint()
//         ..color = color
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = strokeWidth
//         ..strokeCap = StrokeCap.round
//         ..strokeJoin = StrokeJoin.round
//         ..isAntiAlias = true,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _SwoopLinePainter old) =>
//       old.left != left ||
//       old.right != right ||
//       old.bottomX != bottomX ||
//       old.depth != depth ||
//       old.color != color ||
//       old.strokeWidth != strokeWidth;
// }

// /// Small crescent moon: a circle with a shifted circle cut out of it.
// class _CrescentPainter extends CustomPainter {
//   final Color color;
//   _CrescentPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = size.width / 2;
//     final outer = Path()
//       ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
//     final cut = Path()
//       ..addOval(
//         Rect.fromCircle(
//           center: Offset(r + r * 0.55, r - r * 0.25),
//           radius: r * 0.85,
//         ),
//       );

//     canvas.drawPath(
//       Path.combine(PathOperation.difference, outer, cut),
//       Paint()..color = color,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _CrescentPainter old) => old.color != color;
// }

// First version moon navbar
// import 'package:flutter/material.dart';

// import '../theme/app_colors.dart';

// class AppNavItem {
//   final IconData icon;
//   final String label; // used for accessibility only
//   const AppNavItem({required this.icon, required this.label});
// }

// /// The four tabs, in order.
// const List<AppNavItem> kAppNavItems = [
//   AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
//   AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
//   AppNavItem(icon: Icons.tune, label: 'Settings'),
//   AppNavItem(icon: Icons.person_outline, label: 'Profile'),
// ];

// /// The floating pill-shaped navigation bar with a sliding swoop
// /// and a crescent moon above the selected tab.
// class AppBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   /// Colour of the crescent moon.
//   final Color moonColor;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//     this.moonColor = const Color(0xFFFFC857),
//   });

//   static const double _barPadding = 6;
//   static const double _swoopWidth = 60;
//   static const double _swoopDepth = 13;
//   static const double _moonSize = 14;
//   static const double _moonGap = 4;
//   static const Duration _slide = Duration(milliseconds: 380);

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         // Extra top padding reserves room for the moon above the pill.
//         padding: const EdgeInsets.fromLTRB(
//           16,
//           _moonSize + _moonGap + 4,
//           16,
//           12,
//         ),
//         child: Container(
//           height: 66,
//           padding: const EdgeInsets.all(_barPadding),
//           decoration: BoxDecoration(
//             color: AppColors.background,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(color: AppColors.surface, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.darkbrown.withValues(alpha: 0.12),
//                 blurRadius: 16,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final itemWidth = constraints.maxWidth / kAppNavItems.length;
//               final centerX = itemWidth * currentIndex + itemWidth / 2;

//               return Stack(
//                 clipBehavior: Clip.none,
//                 children: [
//                   // Swoop hanging from the top edge of the pill.
//                   AnimatedPositioned(
//                     duration: _slide,
//                     curve: Curves.easeOutCubic,
//                     left: centerX - _swoopWidth / 2,
//                     top: -_barPadding,
//                     child: IgnorePointer(
//                       child: CustomPaint(
//                         size: const Size(_swoopWidth, _swoopDepth),
//                         painter: _SwoopPainter(color: AppColors.mediumbrown),
//                       ),
//                     ),
//                   ),

//                   // Crescent moon floating above the selected tab.
//                   AnimatedPositioned(
//                     duration: _slide,
//                     curve: Curves.easeOutBack, // small overshoot = playful
//                     left: centerX - _moonSize / 2,
//                     top: -_barPadding - _moonGap - _moonSize,
//                     child: IgnorePointer(
//                       child: CustomPaint(
//                         size: const Size(_moonSize, _moonSize),
//                         painter: _CrescentPainter(color: moonColor),
//                       ),
//                     ),
//                   ),

//                   // Tabs.
//                   Row(
//                     children: [
//                       for (int i = 0; i < kAppNavItems.length; i++)
//                         Expanded(child: _buildItem(i)),
//                     ],
//                   ),
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildItem(int index) {
//     final selected = index == currentIndex;
//     final item = kAppNavItems[index];

//     return Semantics(
//       label: item.label,
//       selected: selected,
//       button: true,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => onTap(index),
//         child: Center(
//           child: AnimatedScale(
//             scale: selected ? 1.15 : 1.0,
//             duration: const Duration(milliseconds: 200),
//             curve: Curves.easeOut,
//             child: TweenAnimationBuilder<Color?>(
//               tween: ColorTween(
//                 end: selected ? AppColors.mediumbrown : AppColors.darkbrown,
//               ),
//               duration: const Duration(milliseconds: 200),
//               builder: (context, color, _) =>
//                   Icon(item.icon, size: 24, color: color),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Soft downward curve that hangs from the top edge of the bar.
// class _SwoopPainter extends CustomPainter {
//   final Color color;
//   _SwoopPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final w = size.width;
//     final h = size.height;

//     final path = Path()
//       ..moveTo(0, 0)
//       ..cubicTo(w * 0.25, 0, w * 0.30, h, w * 0.5, h)
//       ..cubicTo(w * 0.70, h, w * 0.75, 0, w, 0)
//       ..close();

//     canvas.drawPath(path, Paint()..color = color);
//   }

//   @override
//   bool shouldRepaint(covariant _SwoopPainter old) => old.color != color;
// }

// /// Small crescent moon: a circle with a shifted circle cut out of it.
// class _CrescentPainter extends CustomPainter {
//   final Color color;
//   _CrescentPainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final r = size.width / 2;
//     final outer = Path()
//       ..addOval(Rect.fromCircle(center: Offset(r, r), radius: r));
//     final cut = Path()
//       ..addOval(
//         Rect.fromCircle(
//           center: Offset(r + r * 0.55, r - r * 0.25),
//           radius: r * 0.85,
//         ),
//       );

//     canvas.drawPath(
//       Path.combine(PathOperation.difference, outer, cut),
//       Paint()..color = color,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant _CrescentPainter old) => old.color != color;
// }

// import 'package:flutter/material.dart';

// import '../theme/app_colors.dart';

// class AppNavItem {
//   final IconData icon;
//   final String label; // used for accessibility only
//   const AppNavItem({required this.icon, required this.label});
// }

// /// The four tabs, in order.
// const List<AppNavItem> kAppNavItems = [
//   AppNavItem(icon: Icons.wb_sunny_outlined, label: 'Today'),
//   AppNavItem(icon: Icons.auto_graph, label: 'Progress'),
//   AppNavItem(icon: Icons.tune, label: 'Settings'),
//   AppNavItem(icon: Icons.person_outline, label: 'Profile'),
// ];

// /// The floating pill-shaped navigation bar.
// class AppBottomNavBar extends StatelessWidget {
//   final int currentIndex;
//   final ValueChanged<int> onTap;

//   const AppBottomNavBar({
//     super.key,
//     required this.currentIndex,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
//         child: Container(
//           height: 66,
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: AppColors.background,
//             borderRadius: BorderRadius.circular(30),
//             border: Border.all(color: AppColors.surface, width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: AppColors.darkbrown.withValues(alpha: 0.12),
//                 blurRadius: 16,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               for (int i = 0; i < kAppNavItems.length; i++)
//                 Expanded(child: _buildItem(i)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildItem(int index) {
//     final selected = index == currentIndex;
//     final item = kAppNavItems[index];

//     return Semantics(
//       label: item.label,
//       selected: selected,
//       button: true,
//       child: GestureDetector(
//         behavior: HitTestBehavior.opaque,
//         onTap: () => onTap(index),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeOut,
//           margin: const EdgeInsets.symmetric(horizontal: 2),
//           decoration: BoxDecoration(
//             color: selected ? AppColors.mediumbrown : Colors.transparent,
//             borderRadius: BorderRadius.circular(22),
//           ),
//           child: Icon(
//             item.icon,
//             size: 24,
//             color: selected ? AppColors.background : AppColors.mediumbrown,
//           ),
//         ),
//       ),
//     );
//   }
// }
