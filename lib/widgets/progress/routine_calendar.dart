import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Displays a month of saved routine completion data in the Progress tab.
class RoutineCalendar extends StatelessWidget {
  const RoutineCalendar({
    super.key,
    required this.month,
    required this.records,
    required this.palette,
    required this.onMonth,
  });

  final DateTime month;
  final Map<String, RoutineDayRecord> records;
  final RoutinePalette palette;
  final ValueChanged<int> onMonth;

  String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month).weekday - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border.withValues(alpha: .4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  MaterialLocalizations.of(context).formatMonthYear(month),
                  textAlign: TextAlign.center,
                  style: AppFonts.cormorant(
                    size: 23,
                    weight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + count,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox();
              final day = index - leading + 1;
              final record =
                  records[_key(DateTime(month.year, month.month, day))];
              final progress = record == null
                  ? 0.0
                  : (record.morningProgress + record.eveningProgress) / 2;
              return Center(
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: record == null
                        ? Colors.transparent
                        : palette.accent.withValues(alpha: .15 + progress * .7),
                  ),
                  child: Text(
                    '$day',
                    style: AppFonts.montserrat(
                      size: 11,
                      weight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Shows one saved day below the calendar in the Progress tab.
class RoutineProgressRecordCard extends StatelessWidget {
  const RoutineProgressRecordCard({
    super.key,
    required this.record,
    required this.palette,
  });

  final RoutineDayRecord record;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.date,
            style: AppFonts.manrope(
              size: 14,
              weight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Morning ${record.morningCompleted}/${record.morningTotal} · Evening ${record.eveningCompleted}/${record.eveningTotal}',
            style: AppFonts.manrope(size: 12, color: palette.muted),
          ),
        ],
      ),
    ),
  );
}
