import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

/// Row of thin bars at the top of the tutorial ("page 2 of 4"): the bars up
/// to and including [step] use the accent colour, the rest the surface.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.total,
  });

  /// The current page, starting at 1.
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page $step of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step
                      ? context.palette.accent
                      : context.palette.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < total) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
