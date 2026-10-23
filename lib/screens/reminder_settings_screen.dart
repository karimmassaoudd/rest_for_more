import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../services/routine_reminder_service.dart';
import '../theme/app_colors.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({
    super.key,
    required this.morningRemaining,
    required this.eveningRemaining,
    this.service,
  });

  final int morningRemaining;
  final int eveningRemaining;
  final RoutineReminderService? service;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late final RoutineReminderService _service;
  bool _enabled = false;
  bool _loading = true;
  TimeOfDay _morning = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _evening = const TimeOfDay(hour: 21, minute: 40);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? RoutineReminderService();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    if (!mounted) return;
    setState(() {
      _enabled = settings.enabled;
      _morning = TimeOfDay(
        hour: settings.morningHour,
        minute: settings.morningMinute,
      );
      _evening = TimeOfDay(
        hour: settings.eveningHour,
        minute: settings.eveningMinute,
      );
      _loading = false;
    });
  }

  Future<void> _pick(bool morning) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _evening,
    );
    if (selected == null || !mounted) return;
    setState(() => morning ? _morning = selected : _evening = selected);
  }

  Future<void> _save() async {
    if (_enabled) {
      final granted = await _service.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission was not granted.'),
          ),
        );
        return;
      }
    }
    await _service.saveAndSchedule(
      settings: ReminderSettings(
        enabled: _enabled,
        morningHour: _morning.hour,
        morningMinute: _morning.minute,
        eveningHour: _evening.hour,
        eveningMinute: _evening.minute,
      ),
      morningRemaining: widget.morningRemaining,
      eveningRemaining: widget.eveningRemaining,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.forPeriod(RoutinePeriod.morning);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('Routine reminders'),
        backgroundColor: palette.background,
        foregroundColor: palette.text,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SwitchListTile(
                  key: const Key('reminders-enabled'),
                  value: _enabled,
                  title: const Text('Enable daily reminders'),
                  subtitle: const Text(
                    'Notifications can appear while the app is closed.',
                  ),
                  onChanged: (value) => setState(() => _enabled = value),
                ),
                ListTile(
                  title: const Text('Morning Routine'),
                  subtitle: Text(_morning.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _enabled ? () => _pick(true) : null,
                ),
                ListTile(
                  title: const Text('Evening Routine'),
                  subtitle: Text(_evening.format(context)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _enabled ? () => _pick(false) : null,
                ),
                const SizedBox(height: 16),
                Text(
                  'A routine-ready reminder is followed one hour later by an unfinished-task check-in. Delivery time can vary slightly because Android battery optimization may delay inexact alarms.',
                  style: TextStyle(color: palette.muted, height: 1.4),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Save reminders'),
                ),
              ],
            ),
    );
  }
}
