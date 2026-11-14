import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// "IK WIL SLAPEN OM" card at the top of the evening editor:
/// the chosen bedtime and a button to change it.
class SleepTimeCard extends StatelessWidget {
  const SleepTimeCard({
    super.key,
    required this.sleepTime,
    required this.onEdit,
  });

  /// "HH:mm".
  final String sleepTime;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 24, 17, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round, size: 14, color: palette.muted),
              const SizedBox(width: 9),
              Text(
                'IK WIL SLAPEN OM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 20),
              Text(
                sleepTime,
                style: AppFonts.cormorant(
                  size: 36,
                  weight: FontWeight.w500,
                  color: palette.text,
                ).copyWith(fontStyle: FontStyle.italic),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Bedtijd aanpassen',
                icon: const Icon(Icons.edit_outlined, size: 25),
                color: palette.accent,
                style: IconButton.styleFrom(
                  backgroundColor: palette.background,
                  side: BorderSide(color: palette.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }
}
