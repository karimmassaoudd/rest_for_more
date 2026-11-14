import 'package:flutter/cupertino.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// iOS-style scroll wheel with the numbers 0 to [count] - 1,
/// each followed by [suffix] (e.g. "15 min").
class TimeWheel extends StatelessWidget {
  const TimeWheel({
    super.key,
    required this.controller,
    required this.count,
    required this.suffix,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final String suffix;

  /// Called with the selected number when the wheel stops on it.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      itemExtent: 40,
      scrollController: controller,
      onSelectedItemChanged: onChanged,
      children: List.generate(
        count,
        (index) => Center(
          child: Text(
            '$index $suffix',
            style: AppFonts.manrope(
              size: 20,
              weight: FontWeight.bold,
              color: context.palette.text,
            ),
          ),
        ),
      ),
    );
  }
}
