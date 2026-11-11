import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

/// Thin progress bars for the tutorial pages ("page 2 of 4").
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.step,
    required this.total,
  });

  final int step; // 1-based
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
                  color: i <= step ? AppColors.mediumbrown : AppColors.surface,
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
