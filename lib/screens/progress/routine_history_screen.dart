import 'package:flutter/material.dart';

import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../widgets/progress/routine_calendar.dart';

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
          'Progress',
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
              RoutineCalendar(
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
                    (record) => RoutineProgressRecordCard(
                      record: record,
                      palette: palette,
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
