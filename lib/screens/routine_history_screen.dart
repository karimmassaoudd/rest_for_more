import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../services/routine_progress_storage.dart';
import '../theme/app_colors.dart';

enum _HistoryFilter { both, morning, evening }

class RoutineHistoryScreen extends StatefulWidget {
  const RoutineHistoryScreen({super.key, required this.storage});

  final RoutineProgressStorage storage;

  @override
  State<RoutineHistoryScreen> createState() => _RoutineHistoryScreenState();
}

class _RoutineHistoryScreenState extends State<RoutineHistoryScreen> {
  late Future<List<RoutineDayRecord>> _history;
  late DateTime _visibleMonth;
  late String _selectedDate;
  _HistoryFilter _filter = _HistoryFilter.both;
  int _rangeDays = 7;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDate = _key(now);
    _history = widget.storage.loadHistory();
  }

  String _key(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  void _changeMonth(int offset) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
      final now = DateTime.now();
      final day =
          now.year == _visibleMonth.year && now.month == _visibleMonth.month
          ? now.day
          : 1;
      _selectedDate = _key(
        DateTime(_visibleMonth.year, _visibleMonth.month, day),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.forPeriod(RoutinePeriod.morning);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Routine history'),
        backgroundColor: palette.background,
        foregroundColor: palette.text,
      ),
      body: FutureBuilder<List<RoutineDayRecord>>(
        future: _history,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final byDate = {for (final record in records) record.date: record};
          final selected = byDate[_selectedDate];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _SectionCard(
                palette: palette,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          key: const Key('previous-history-month'),
                          tooltip: 'Previous month',
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: palette.text,
                              fontFamily: 'serif',
                              fontSize: 23,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('next-history-month'),
                          tooltip: 'Next month',
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .map(
                            (day) => Expanded(
                              child: Text(
                                day,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 6),
                    _CalendarGrid(
                      month: _visibleMonth,
                      selectedDate: _selectedDate,
                      records: byDate,
                      palette: palette,
                      dateKey: _key,
                      onSelected: (date) {
                        setState(() => _selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LegendDot(color: const Color(0xFFD69A2D)),
                        const SizedBox(width: 5),
                        Text(
                          'Morning',
                          style: TextStyle(color: palette.muted, fontSize: 10),
                        ),
                        const SizedBox(width: 16),
                        _LegendDot(color: const Color(0xFF7267A8)),
                        const SizedBox(width: 5),
                        Text(
                          'Evening',
                          style: TextStyle(color: palette.muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Show progress for',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              SegmentedButton<_HistoryFilter>(
                key: const Key('history-period-filter'),
                segments: const [
                  ButtonSegment(
                    value: _HistoryFilter.both,
                    label: Text('Both'),
                  ),
                  ButtonSegment(
                    value: _HistoryFilter.morning,
                    label: Text('Morning'),
                  ),
                  ButtonSegment(
                    value: _HistoryFilter.evening,
                    label: Text('Evening'),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (value) {
                  setState(() => _filter = value.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: WidgetStatePropertyAll(palette.text),
                ),
              ),
              const SizedBox(height: 18),
              _SelectedDayCard(
                date: _selectedDate,
                record: selected,
                filter: _filter,
                palette: palette,
                onReturnToRoutine: () => Navigator.pop(context),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Progress over time',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  DropdownButton<int>(
                    key: const Key('history-range-filter'),
                    value: _rangeDays,
                    dropdownColor: palette.card,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Last 7 days')),
                      DropdownMenuItem(value: 30, child: Text('Last 30 days')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _rangeDays = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _HistoryList(
                records: records,
                rangeDays: _rangeDays,
                filter: _filter,
                palette: palette,
              ),
            ],
          );
        },
      ),
    );
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.selectedDate,
    required this.records,
    required this.palette,
    required this.dateKey,
    required this.onSelected,
  });

  final DateTime month;
  final String selectedDate;
  final Map<String, RoutineDayRecord> records;
  final RoutinePalette palette;
  final String Function(DateTime) dateKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final days = DateTime(month.year, month.month + 1, 0).day;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: firstDay.weekday - 1 + days,
      itemBuilder: (context, index) {
        final day = index - (firstDay.weekday - 2);
        if (day < 1) return const SizedBox.shrink();
        final key = dateKey(DateTime(month.year, month.month, day));
        final record = records[key];
        final selected = selectedDate == key;
        return InkWell(
          key: Key('history-day-$key'),
          onTap: () => onSelected(key),
          borderRadius: BorderRadius.circular(9),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? palette.accent : palette.card,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? palette.buttonText : palette.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (record != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProgressDot(
                        progress: record.morningProgress,
                        color: const Color(0xFFD69A2D),
                      ),
                      const SizedBox(width: 3),
                      _ProgressDot(
                        progress: record.eveningProgress,
                        color: const Color(0xFF7267A8),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  const _SelectedDayCard({
    required this.date,
    required this.record,
    required this.filter,
    required this.palette,
    required this.onReturnToRoutine,
  });

  final String date;
  final RoutineDayRecord? record;
  final _HistoryFilter filter;
  final RoutinePalette palette;
  final VoidCallback onReturnToRoutine;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (record == null) ...[
            Icon(Icons.event_note_outlined, color: palette.accent, size: 30),
            const SizedBox(height: 9),
            Text(
              'No routine activity yet',
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Complete or edit a task on this day and its real progress will appear here.',
              style: TextStyle(color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onReturnToRoutine,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go to routine'),
            ),
          ] else ...[
            if (filter != _HistoryFilter.evening)
              _ProgressBar(
                label: 'Morning',
                completed: record!.morningCompleted,
                total: record!.morningTotal,
                color: const Color(0xFFD69A2D),
              ),
            if (filter == _HistoryFilter.both) const SizedBox(height: 14),
            if (filter != _HistoryFilter.morning)
              _ProgressBar(
                label: 'Evening',
                completed: record!.eveningCompleted,
                total: record!.eveningTotal,
                color: const Color(0xFF7267A8),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.records,
    required this.rangeDays,
    required this.filter,
    required this.palette,
  });
  final List<RoutineDayRecord> records;
  final int rangeDays;
  final _HistoryFilter filter;
  final RoutinePalette palette;

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(Duration(days: rangeDays - 1));
    final visible = records
        .where((record) {
          final date = DateTime.tryParse(record.date);
          return date != null &&
              !date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
        })
        .toList()
        .reversed
        .toList();
    if (visible.isEmpty) {
      return Text(
        'No saved activity in the last $rangeDays days.',
        style: TextStyle(color: palette.muted),
      );
    }
    return Column(
      children: visible.map((record) {
        final progress = switch (filter) {
          _HistoryFilter.morning => record.morningProgress,
          _HistoryFilter.evening => record.eveningProgress,
          _HistoryFilter.both =>
            (record.morningProgress + record.eveningProgress) / 2,
        };
        final completed = switch (filter) {
          _HistoryFilter.morning => record.morningCompleted,
          _HistoryFilter.evening => record.eveningCompleted,
          _HistoryFilter.both =>
            record.morningCompleted + record.eveningCompleted,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.date,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$completed tasks  ${(progress * 100).round()}%',
                    style: TextStyle(
                      color: palette.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(99),
                color: palette.accent,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.palette, required this.child});
  final RoutinePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: palette.surface.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: palette.border.withValues(alpha: 0.55)),
    ),
    child: child,
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25 + progress * 0.75),
      shape: BoxShape.circle,
    ),
  );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });
  final String label;
  final int completed;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$completed/$total  ${(progress * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          minHeight: 12,
          color: color,
          borderRadius: BorderRadius.circular(99),
        ),
      ],
    );
  }
}
