import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class RoutineHistoryScreen extends StatefulWidget {
  const RoutineHistoryScreen({
    super.key,
    this.storage = const RoutineProgressStorage(),
  });
  final RoutineProgressStorage storage;

  @override
  State<RoutineHistoryScreen> createState() => _RoutineHistoryScreenState();
}

class _RoutineHistoryScreenState extends State<RoutineHistoryScreen> {
  late Future<List<RoutineDayRecord>> _history;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _history = widget.storage.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(
          'Routine history',
          style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<RoutineDayRecord>>(
        future: _history,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: palette.accent),
            );
          }
          final records = {for (final item in snapshot.data!) item.date: item};
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Your routine calendar',
                style: AppFonts.cormorant(
                  size: 30,
                  weight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              _Calendar(
                month: _month,
                records: records,
                palette: palette,
                onMonth: (delta) => setState(
                  () => _month = DateTime(_month.year, _month.month + delta),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Recent days',
                style: AppFonts.montserrat(
                  size: 11,
                  weight: FontWeight.w800,
                  color: palette.muted,
                ),
              ),
              const SizedBox(height: 10),
              if (records.isEmpty)
                Text(
                  'No routine progress saved yet.',
                  style: AppFonts.manrope(size: 14, color: palette.muted),
                ),
              ...records.values
                  .toList()
                  .reversed
                  .take(14)
                  .map(
                    (record) => _RecordCard(record: record, palette: palette),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.palette});
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
