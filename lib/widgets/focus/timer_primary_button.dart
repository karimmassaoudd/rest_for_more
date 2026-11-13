import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Full-width brown button on the timer screen ("Start", "Pause (1 left)").
/// Pass a null [onPressed] to show it greyed out and disabled.
class TimerPrimaryButton extends StatelessWidget {
  const TimerPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.accent,
          disabledBackgroundColor: palette.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: AppFonts.manrope(
            size: 15,
            color: onPressed == null ? palette.muted : palette.onAccent,
          ),
        ),
      ),
    );
  }
}
