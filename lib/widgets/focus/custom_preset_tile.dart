import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// One saved custom preset on the custom time page, with a delete button.
class CustomPresetTile extends StatelessWidget {
  const CustomPresetTile({
    super.key,
    required this.minutes,
    required this.onDelete,
  });

  final int minutes;
  final VoidCallback onDelete;

  /// "45 Min", or "1h 30m" from one hour.
  String get _label {
    final hours = minutes ~/ 60;
    return hours > 0 ? '${hours}h ${minutes % 60}m' : '$minutes Min';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _label,
            style: AppFonts.manrope(
              size: 16,
              weight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: palette.accent),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
