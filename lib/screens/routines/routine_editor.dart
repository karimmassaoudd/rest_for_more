import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/routines/activity.dart';
import '../../models/routines/routine_time.dart';
import '../../services/routines/save_activities.dart';

import '../../theme/app_palette.dart';

import '../../widgets/routines/activity_sheet.dart';
import '../../widgets/routines/activity_tile.dart';
import '../../widgets/routines/sleep_time_card.dart';

/// Name of the bedtime activity; it always follows the chosen bedtime
/// and is always shown last. Must match default_evening_activities.dart.
const _sleepActivityName = 'Slapen';

/// Editor for the evening routine (Settings → Edit routines):
/// set the bedtime, and add, edit or delete evening activities.
///
/// Only the bedtime is saved for now; activity changes last until the
/// page is closed.
class EveningPage extends StatefulWidget {
  const EveningPage({
    super.key,
    this.activitiesStorage = const SaveActivities(),
  });

  /// Replaceable in tests.
  final SaveActivities activitiesStorage;

  @override
  State<EveningPage> createState() => _EveningPageState();
}

class _EveningPageState extends State<EveningPage> {
  late final List<Activity> _activities;
  String _sleepTime = defaultRoutineSleepTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _activities = widget.activitiesStorage.getActivities();
    unawaited(_loadSleepTime());
  }

  /// Bedtime last, everything else by time.
  List<Activity> get _sortedActivities {
    final sorted = [..._activities];
    sorted.sort((a, b) {
      final aIsSleep = a.name == _sleepActivityName;
      final bIsSleep = b.name == _sleepActivityName;
      if (aIsSleep && !bIsSleep) return 1;
      if (!aIsSleep && bIsSleep) return -1;
      return a.time.compareTo(b.time);
    });
    return sorted;
  }

  // ------------------------------------------------------------------
  // Bedtime
  // ------------------------------------------------------------------

  Future<void> _loadSleepTime() async {
    try {
      final sleepTime = await widget.activitiesStorage.loadRoutineSleepTime();
      if (!mounted) return;
      setState(() {
        _sleepTime = sleepTime;
        _updateSleepActivityTime();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bedtijd laden is mislukt: $error')),
      );
    }
  }

  Future<void> _chooseSleepTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: parseTime24h(_sleepTime),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      _sleepTime = formatTime24h(time);
      _updateSleepActivityTime();
    });
  }

  /// Moves the "Slapen" activity to the chosen bedtime. Call inside setState.
  void _updateSleepActivityTime() {
    for (final activity in _activities) {
      if (activity.name == _sleepActivityName) {
        activity.time = _sleepTime;
        return;
      }
    }
  }

  Future<void> _saveRoutine() async {
    setState(() => _isSaving = true);
    try {
      await widget.activitiesStorage.saveRoutineSleepTime(_sleepTime);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Routine opgeslagen.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Routine opslaan is mislukt: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ------------------------------------------------------------------
  // Activities
  // ------------------------------------------------------------------

  /// Opens the add/edit sheet; returns the new activity, or null when cancelled.
  Future<Activity?> _openActivitySheet([Activity? activity]) {
    return showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.background,
      builder: (_) => ActivitySheet(activity: activity, sleepTime: _sleepTime),
    );
  }

  Future<void> _addActivity() async {
    final activity = await _openActivitySheet();
    if (activity != null && mounted) {
      setState(() => _activities.add(activity));
    }
  }

  Future<void> _editActivity(Activity source) async {
    final updated = await _openActivitySheet(source);
    if (updated != null && mounted) {
      setState(() {
        final index = _activities.indexOf(source);
        if (index != -1) _activities[index] = updated;
      });
    }
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 17, 23, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TopBar(),
                    const SizedBox(height: 19),
                    SleepTimeCard(
                      sleepTime: _sleepTime,
                      onEdit: _chooseSleepTime,
                    ),
                    const SizedBox(height: 21),
                    Text(
                      'JOUW AVOND',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.palette.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final activity in _sortedActivities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: ActivityTile(
                          activity: activity,
                          onEdit: () => _editActivity(activity),
                          onDelete: () =>
                              setState(() => _activities.remove(activity)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 3, 25, 10),
              child: Column(
                children: [
                  _OutlinedAction(
                    label: '+  Activiteit toevoegen',
                    onPressed: _addActivity,
                  ),
                  const SizedBox(height: 9),
                  _FilledAction(
                    label: _isSaving ? 'Opslaan...' : 'Routine opslaan',
                    onPressed: _isSaving ? null : _saveRoutine,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back arrow and the page title.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, size: 19, color: palette.text),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 25),
        Text(
          'Avond',
          style: TextStyle(
            color: palette.muted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Placeholder: the menu has no actions yet.
        Icon(Icons.more_vert, size: 21, color: palette.text),
      ],
    );
  }
}

/// "+ Activiteit toevoegen" button.

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

/// "Routine opslaan" button; disabled (null [onPressed]) while saving.
class _FilledAction extends StatelessWidget {
  const _FilledAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 41,
      width: double.infinity,
      child: FilledButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
