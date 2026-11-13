import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// Grid of duration buttons (3 per row) on the timer screen.
/// Scrolls when there are more than about four rows of presets.
class DurationPresetGrid extends StatelessWidget {
  const DurationPresetGrid({
    super.key,
    required this.presets,
    required this.selectedMillis,
    required this.onSelected,
  });

  /// Durations in minutes.
  final List<int> presets;

  /// The currently chosen duration; the matching button is highlighted.
  final int selectedMillis;

  /// Called with the tapped duration in minutes.
  final ValueChanged<int> onSelected;

  static const _perRow = 3;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var start = 0; start < presets.length; start += _perRow) {
      final cells = <Widget>[];
      for (var c = 0; c < _perRow; c++) {
        final index = start + c;
        if (c > 0) cells.add(const SizedBox(width: _gap));
        // Empty cells keep the last row's buttons the same width.
        cells.add(
          Expanded(
            child: index < presets.length
                ? _PresetButton(
                    minutes: presets[index],
                    selected: selectedMillis == presets[index] * 60 * 1000,
                    onTap: () => onSelected(presets[index]),
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
      rows.add(Row(children: cells));
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 152),
      child: SingleChildScrollView(child: Column(children: rows)),
    );
  }
}

/// One duration button, e.g. "30 min" or "1h 30m".
class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.minutes,
    required this.selected,
    required this.onTap,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  String get _label {
    if (minutes < 60) return '$minutes min';
    final rest = minutes % 60;
    return '${minutes ~/ 60}h${rest > 0 ? " ${rest}m" : ""}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: selected ? palette.accent : palette.surface,
      elevation: selected ? 0 : 3,
      shadowColor: palette.text.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? null
                : Border.all(color: palette.muted, width: 1),
          ),
          child: Text(
            _label,
            style: AppFonts.manrope(
              size: 13,
              color: selected ? palette.onAccent : palette.accent,
            ),
          ),
        ),
      ),
    );
  }
}

/// Square "+" button that opens the custom time page.
class AddPresetButton extends StatelessWidget {
  const AddPresetButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      elevation: 3,
      shadowColor: palette.text.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.palette.muted, width: 1),
          ),
          child: Icon(Icons.add, size: 28, color: palette.accent),
        ),
      ),
    );
  }
}
