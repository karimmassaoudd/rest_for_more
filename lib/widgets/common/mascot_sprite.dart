import 'package:flutter/material.dart';

/// One sheep from a mascot sprite sheet: a 3 × 3 grid of poses in one image
/// (e.g. assets/mascot/sheep-reactions.webp).
///
/// Shows only cell [cell] of the sheet, scaled to [size] × [size].
class MascotSprite extends StatelessWidget {
  const MascotSprite({
    super.key,
    required this.sheet,
    required this.cell,
    this.size = 140,
  });

  /// Asset path of the sprite sheet.
  final String sheet;

  /// Which pose: 0–8, counted row by row from the top left.
  final int cell;
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = cell % 3;
    final row = cell ~/ 3;

    return SizedBox.square(
      dimension: size,
      // Draw the whole sheet at 3× size, shift it so the wanted cell sits
      // in the visible square, and clip off the rest.
      child: ClipRect(
        child: OverflowBox(
          maxWidth: size * 3,
          maxHeight: size * 3,
          // -1, 0 or 1 per axis = left/top, middle, right/bottom cell.
          alignment: Alignment(col - 1.0, row - 1.0),
          child: Image.asset(
            sheet,
            width: size * 3,
            height: size * 3,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
