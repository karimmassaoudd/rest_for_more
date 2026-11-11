import 'package:flutter/material.dart';

/// ● ○ ○ ○ — shows which card is visible; tapping a dot jumps to that card.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final int count;
  final int active;
  final Color color;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == active,
            label: 'Card ${i + 1} of $count',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == active ? color : color.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
