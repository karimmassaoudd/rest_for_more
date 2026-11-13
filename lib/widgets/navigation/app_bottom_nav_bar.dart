import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_palette.dart';

part 'app_bottom_nav_bar_painters.dart';

/// One tab of the bottom navigation bar.
class AppNavItem {
  const AppNavItem({required this.icon, required this.label});

  final IconData icon;

  /// Not shown; read out by screen readers.
  final String label;
}

/// The four tabs, in the same order as the router's branches.
const List<AppNavItem> kAppNavItems = [
  AppNavItem(icon: Icons.home_outlined, label: 'Today'),
  AppNavItem(icon: Icons.auto_graph_rounded, label: 'Progress'),
  AppNavItem(icon: Icons.tune_rounded, label: 'Settings'),
  AppNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
];

/// Full-width bottom navigation bar with a thin accent-coloured line on top.
///
/// Above the selected tab the line dips into a curve (the "swoop"), and a
/// crescent moon floats above it. Switching tabs moves the swoop and the
/// moon over like liquid: it stretches, dips deeper and settles again.
/// The area above the curve is cut out, so the page shows through.
class AppBottomNavBar extends StatefulWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.moonColor = AppColors.moon,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Colour of the crescent moon.
  final Color moonColor;

  @override
  State<AppBottomNavBar> createState() => _AppBottomNavBarState();
}

class _AppBottomNavBarState extends State<AppBottomNavBar>
    with SingleTickerProviderStateMixin {
  // ----- bar -----
  static const double _barHeight = 66;
  static const double _barPadding = 6;
  static const double _barRadius = 0; // square corners: full-width bar
  static const double _iconBottomOffset = 9; // pushes icons below the swoop
  static const double _iconSize = 26;

  // ----- swoop (the dip in the line) -----
  static const double _swoopHalfWidth = 38;
  static const double _swoopDepth = 16; // resting depth of the dip
  static const double _swoopMaxExtraDepth = 16; // room for the dip while moving
  static const double _lineWidth = 1;

  // ----- moon -----
  static const double _moonSize = 21;
  static const double _moonGap = -2; // negative: the moon dips into the swoop
  static const double _moonTilt = -0.5; // radians, negative = tilted left

  /// How much thicker the selected icon looks (in logical pixels).
  static const double _iconBoldness = 0.2;

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

  /// The swoop and moon at the current animation frame, in the coordinate
  /// space of the bar's inner (padded) area.
  _Swoop _geometry(double itemWidth) {
    final t = _controller.value;
    final p = Curves.easeInOutSine.transform(t);
    final distance = (_to - _from) * itemWidth;
    final direction = distance.sign;
    final center = (_from + (_to - _from) * p + 0.5) * itemWidth;

    // 0 at the start and end of the animation, so the shape is exactly
    // at rest on either tab; peaks halfway.
    final envelope = math.pow(math.sin(math.pi * t), 2).toDouble();
    // Longer jumps wobble more (capped at 1.5 tabs).
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
    // Space for the phone's system navigation area (gesture bar).
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Room above the bar for the moon (+ 8 for its hop).
      padding: const EdgeInsets.only(top: _moonSize + _moonGap + 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - _barPadding * 2;
          final itemWidth = contentWidth / kAppNavItems.length;

          // Built once and passed through the AnimatedBuilder, so the tabs
          // don't rebuild on every animation frame.
          final tabs = Row(
            children: [
              for (int i = 0; i < kAppNavItems.length; i++)
                Expanded(child: _buildItem(i)),
            ],
          );

          return SizedBox(
            // The bar's background runs down behind the system area.
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
                    background: context.palette.background,
                    borderColor: context.palette.accent,
                    shadowColor: context.palette.text.withValues(alpha: 0.12),
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

  /// The curved line and the moon above it.
  Widget _buildLiquid(_Swoop swoop, double contentWidth) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: -_barPadding,
          width: contentWidth,
          height: _swoopDepth + _swoopMaxExtraDepth + _lineWidth,
          child: CustomPaint(
            painter: _SwoopLinePainter(
              swoop: swoop,
              color: context.palette.accent,
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

  /// One tab: the selected one is slightly bigger, accent-coloured and bolder.
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
                    context.palette.text,
                    context.palette.accent,
                    t,
                  )!;
                  final bold = _iconBoldness * t;

                  // Same-colour, zero-blur shadows nudged in four directions
                  // thicken the glyph strokes (a "faux bold" for icon fonts).
                  return Icon(
                    item.icon,
                    size: _iconSize,
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
