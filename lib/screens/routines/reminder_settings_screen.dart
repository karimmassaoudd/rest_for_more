import 'package:flutter/material.dart';

import '../../services/routines/routine_reminder_service.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key, this.service});
  final RoutineReminderService? service;

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  late final RoutineReminderService _service;
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
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
    final value = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _evening,
    );
    if (value != null && mounted) {
      setState(() {
        if (morning) {
          _morning = value;
        } else {
          _evening = value;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    if (_enabled && !await _service.requestPermission()) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission was not granted.'),
          ),
        );
      }
      return;
    }
    try {
      await _service.saveAndSchedule(
        RoutineReminderSettings(
          enabled: _enabled,
          morningHour: _morning.hour,
          morningMinute: _morning.minute,
          eveningHour: _evening.hour,
          eveningMinute: _evening.minute,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled ? 'Daily reminders saved.' : 'Reminders turned off.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save reminder settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Routine reminders',
          style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: palette.accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Choose a gentle daily prompt for each routine.',
                  style: AppFonts.manrope(size: 14, color: palette.muted),
                ),
                const SizedBox(height: 18),
                _Card(
                  child: SwitchListTile(
                    value: _enabled,
                    onChanged: (value) => setState(() => _enabled = value),
                    title: Text(
                      'Daily reminders',
                      style: AppFonts.manrope(
                        weight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    subtitle: Text(
                      _enabled
                          ? 'Notifications are scheduled every day.'
                          : 'Turn on to choose reminder times.',
                      style: AppFonts.manrope(size: 12, color: palette.muted),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _TimeCard(
                  title: 'Morning routine',
                  icon: Icons.wb_sunny_outlined,
                  time: _morning.format(context),
                  enabled: _enabled,
                  onTap: () => _pick(true),
                ),
                const SizedBox(height: 12),
                _TimeCard(
                  title: 'Evening routine',
                  icon: Icons.nightlight_outlined,
                  time: _evening.format(context),
                  enabled: _enabled,
                  onTap: () => _pick(false),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('save-reminders-button'),
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save reminders'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withValues(alpha: .35)),
      ),
      child: child,
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.title,
    required this.icon,
    required this.time,
    required this.enabled,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final String time;
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: _Card(
        child: ListTile(
          onTap: enabled ? onTap : null,
          leading: Icon(icon, color: p.accent),
          title: Text(
            title,
            style: AppFonts.manrope(weight: FontWeight.w700, color: p.text),
          ),
          trailing: Text(
            time,
            style: AppFonts.cormorant(
              size: 23,
              weight: FontWeight.w600,
              color: p.text,
            ),
          ),
        ),
      ),
    );
  }
}
