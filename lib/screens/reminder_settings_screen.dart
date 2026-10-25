import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../services/routine_reminder_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

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
  bool _saving = false;
  RoutinePeriod _appearance = RoutinePeriod.morning;
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
    final isDark = _appearance == RoutinePeriod.evening;
    final selected = await showTimePicker(
      context: context,
      initialTime: morning ? _morning : _evening,
      builder: (context, child) =>
          Theme(data: isDark ? AppTheme.dark : AppTheme.light, child: child!),
    );
    if (selected == null || !mounted) return;
    setState(() => morning ? _morning = selected : _evening = selected);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    if (_enabled) {
      final granted = await _service.requestPermission();
      if (!granted && mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission was not granted.'),
          ),
        );
        return;
      }
    }
    try {
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
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _enabled ? 'Daily reminders saved.' : 'Reminders turned off.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save reminder settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoutinePalette.forPeriod(_appearance);
    final isDark = _appearance == RoutinePeriod.evening;
    return Theme(
      data: isDark ? AppTheme.dark : AppTheme.light,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          title: const Text(
            'Routine reminders',
            style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600),
          ),
          backgroundColor: palette.background,
          foregroundColor: palette.text,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              key: const Key('reminders-theme-toggle'),
              tooltip: isDark ? 'Use light mode' : 'Use dark mode',
              onPressed: () => setState(() {
                _appearance = isDark
                    ? RoutinePeriod.morning
                    : RoutinePeriod.evening;
              }),
              icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    'Choose when you want a gentle reminder to begin each routine.',
                    style: TextStyle(color: palette.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  _ReminderCard(
                    palette: palette,
                    child: SwitchListTile(
                      key: const Key('reminders-enabled'),
                      contentPadding: EdgeInsets.zero,
                      value: _enabled,
                      activeTrackColor: palette.button,
                      title: Text(
                        'Daily reminders',
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _enabled
                            ? 'On — notifications can appear while the app is closed.'
                            : 'Off — turn this on to schedule notifications.',
                        style: TextStyle(color: palette.muted, height: 1.35),
                      ),
                      secondary: Icon(
                        _enabled
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: palette.accent,
                      ),
                      onChanged: (value) => setState(() => _enabled = value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _TimeCard(
                    key: const Key('morning-reminder-time'),
                    title: 'Morning routine',
                    caption: '${widget.morningRemaining} tasks remaining',
                    time: _morning.format(context),
                    icon: Icons.wb_sunny_outlined,
                    enabled: _enabled,
                    palette: palette,
                    onTap: () => _pick(true),
                  ),
                  const SizedBox(height: 12),
                  _TimeCard(
                    key: const Key('evening-reminder-time'),
                    title: 'Evening routine',
                    caption: '${widget.eveningRemaining} tasks remaining',
                    time: _evening.format(context),
                    icon: Icons.nightlight_outlined,
                    enabled: _enabled,
                    palette: palette,
                    onTap: () => _pick(false),
                  ),
                  const SizedBox(height: 16),
                  _ReminderCard(
                    palette: palette,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: palette.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You will get a start reminder and another check-in one hour later. Android battery settings may occasionally delay delivery.',
                            style: TextStyle(
                              color: palette.muted,
                              height: 1.45,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                      backgroundColor: palette.button,
                      foregroundColor: palette.buttonText,
                      disabledBackgroundColor: palette.button.withValues(
                        alpha: 0.45,
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    super.key,
    required this.title,
    required this.caption,
    required this.time,
    required this.icon,
    required this.enabled,
    required this.palette,
    required this.onTap,
  });

  final String title;
  final String caption;
  final String time;
  final IconData icon;
  final bool enabled;
  final RoutinePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: _ReminderCard(
        palette: palette,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: palette.accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: palette.text,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          enabled ? caption : 'Enable reminders to edit',
                          style: TextStyle(color: palette.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      color: palette.text,
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: palette.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final RoutinePalette palette;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: palette.card,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: palette.border.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: palette.text.withValues(alpha: 0.055),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}
