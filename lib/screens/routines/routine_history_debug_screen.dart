import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/routines/routine_step.dart';
import '../../services/routines/routine_progress_storage.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/rfm_app_bar.dart';

/// Developer page (debug builds only): every saved routine day as plain
/// text, newest first, plus a button that copies the raw JSON.
///
/// Opened by long-pressing "Your morning" / "Your evening" on the routine
/// page. Not the Progress tab: just a way to check what's being saved.
class RoutineHistoryDebugScreen extends StatefulWidget {
  const RoutineHistoryDebugScreen({
    super.key,
    this.storage = const RoutineProgressStorage(),
  });

  final RoutineProgressStorage storage;

  @override
  State<RoutineHistoryDebugScreen> createState() =>
      _RoutineHistoryDebugScreenState();
}

class _RoutineHistoryDebugScreenState extends State<RoutineHistoryDebugScreen> {
  late final Future<List<RoutineDayRecord>> _history = widget.storage
      .loadHistory();

  Future<void> _copyJson(List<RoutineDayRecord> days) async {
    final json = const JsonEncoder.withIndent('  ')
        .convert([for (final day in days) day.toJson()]);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('History copied as JSON')));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: rfmScaffoldAppBar(title: 'History (debug)'),
      body: FutureBuilder<List<RoutineDayRecord>>(
        future: _history,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final days = snapshot.data!.reversed.toList(); // newest first
          if (days.isEmpty) {
            return Center(
              child: Text(
                'No history yet.',
                style: TextStyle(color: palette.muted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _copyJson(days),
                  icon: Icon(Icons.copy_rounded, color: palette.accent),
                  label: Text(
                    'Copy JSON',
                    style: TextStyle(color: palette.accent),
                  ),
                ),
              ),
              for (final day in days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SelectableText(
                    _dayText(day),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.45,
                      color: palette.text,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _dayText(RoutineDayRecord day) => [
    day.date,
    _routineText(
      'Morning',
      day.morningCompleted,
      day.morningTotal,
      day.morningSteps,
    ),
    _routineText(
      'Evening',
      day.eveningCompleted,
      day.eveningTotal,
      day.eveningSteps,
    ),
  ].join('\n');

  String _routineText(
    String name,
    int done,
    int total,
    List<RoutineStepResult> steps,
  ) {
    final lines = ['$name  $done/$total'];
    if (steps.isEmpty) {
      lines.add('  (no step details: saved before snapshots)');
    }
    for (final step in steps) {
      lines.add('  ${step.done ? '✓' : '✗'} ${step.title}');
    }
    return lines.join('\n');
  }
}
