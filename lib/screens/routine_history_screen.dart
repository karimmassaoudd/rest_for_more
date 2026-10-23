import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../services/routine_progress_storage.dart';
import '../theme/app_colors.dart';

class RoutineHistoryScreen extends StatefulWidget {
  const RoutineHistoryScreen({super.key, required this.storage});

  final RoutineProgressStorage storage;

  @override
  State<RoutineHistoryScreen> createState() => _RoutineHistoryScreenState();
}

class _RoutineHistoryScreenState extends State<RoutineHistoryScreen> {
  late Future<List<RoutineDayRecord>> _history;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _history = widget.storage.loadHistory();
  }

  String _key(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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
          final now = DateTime.now();
          final firstDay = DateTime(now.year, now.month, 1);
          final days = DateTime(now.year, now.month + 1, 0).day;
          final selected = byDate[_selectedDate ?? _key(now)];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${_monthName(now.month)} ${now.year}',
                style: TextStyle(
                  color: palette.text,
                  fontFamily: 'serif',
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemCount: firstDay.weekday - 1 + days,
                itemBuilder: (context, index) {
                  final day = index - (firstDay.weekday - 2);
                  if (day < 1) return const SizedBox.shrink();
                  final date = DateTime(now.year, now.month, day);
                  final dateKey = _key(date);
                  final record = byDate[dateKey];
                  final selectedDay = (_selectedDate ?? _key(now)) == dateKey;
                  return InkWell(
                    key: Key('history-day-$dateKey'),
                    onTap: () => setState(() => _selectedDate = dateKey),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedDay ? palette.accent : palette.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: selectedDay
                                  ? palette.buttonText
                                  : palette.text,
                            ),
                          ),
                          if (record != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(
                                  record.morningProgress,
                                  const Color(0xFFD69A2D),
                                ),
                                const SizedBox(width: 3),
                                _dot(
                                  record.eveningProgress,
                                  const Color(0xFF7267A8),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Morning vs Evening',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (selected == null)
                Text(
                  'No routine activity saved for this day.',
                  style: TextStyle(color: palette.muted),
                )
              else ...[
                _ProgressBar(
                  label: 'Morning',
                  completed: selected.morningCompleted,
                  total: selected.morningTotal,
                  color: const Color(0xFFD69A2D),
                ),
                const SizedBox(height: 14),
                _ProgressBar(
                  label: 'Evening',
                  completed: selected.eveningCompleted,
                  total: selected.eveningTotal,
                  color: const Color(0xFF7267A8),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Recent days',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final record in records.reversed.take(7))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    record.date,
                    style: TextStyle(color: palette.text),
                  ),
                  subtitle: Text(
                    '${record.morningCompleted + record.eveningCompleted} tasks completed',
                    style: TextStyle(color: palette.muted),
                  ),
                  trailing: Text(
                    'M ${(record.morningProgress * 100).round()}%  E ${(record.eveningProgress * 100).round()}%',
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(double progress, Color color) => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.25 + progress * 0.75),
      shape: BoxShape.circle,
    ),
  );

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
