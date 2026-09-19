import 'package:flutter/material.dart';

import '../models/routine_step.dart';
import '../theme/app_colors.dart';

class AddRoutineSheet extends StatefulWidget {
  const AddRoutineSheet({
    super.key,
    required this.period,
    required this.palette,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;

  @override
  State<AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<AddRoutineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _duration = 10;

  @override
  void initState() {
    super.initState();
    if (widget.period == RoutinePeriod.evening) {
      _time = const TimeOfDay(hour: 22, minute: 30);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      RoutineStep(
        title: _titleController.text.trim(),
        time: _formatTime(_time),
        duration: '$_duration min',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Add ${widget.period.name} routine',
              style: TextStyle(
                color: palette.text,
                fontFamily: 'serif',
                fontSize: 25,
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('routine-title-field'),
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: palette.text),
              decoration: _inputDecoration('Routine name', palette),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a routine name'
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('routine-time-button'),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(_formatTime(_time)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('routine-duration-field'),
                    initialValue: _duration,
                    dropdownColor: palette.card,
                    style: TextStyle(color: palette.text),
                    decoration: _inputDecoration('Duration', palette),
                    items: const [5, 10, 15, 20, 30]
                        .map(
                          (minutes) => DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _duration = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                key: const Key('save-routine-button'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.button,
                  foregroundColor: palette.buttonText,
                ),
                child: const Text('Add to routine'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, RoutinePalette palette) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: palette.muted),
      filled: true,
      fillColor: palette.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class RoutineSettingsResult {
  const RoutineSettingsResult({
    required this.autoAdvanceToEvening,
    this.resetProgress = false,
    this.switchToEvening = false,
  });

  final bool autoAdvanceToEvening;
  final bool resetProgress;
  final bool switchToEvening;
}

class RoutineSettingsSheet extends StatefulWidget {
  const RoutineSettingsSheet({
    super.key,
    required this.period,
    required this.palette,
    required this.autoAdvanceToEvening,
  });

  final RoutinePeriod period;
  final RoutinePalette palette;
  final bool autoAdvanceToEvening;

  @override
  State<RoutineSettingsSheet> createState() => _RoutineSettingsSheetState();
}

class _RoutineSettingsSheetState extends State<RoutineSettingsSheet> {
  late bool _autoAdvance;

  @override
  void initState() {
    super.initState();
    _autoAdvance = widget.autoAdvanceToEvening;
  }

  void _close({bool reset = false, bool switchToEvening = false}) {
    Navigator.pop(
      context,
      RoutineSettingsResult(
        autoAdvanceToEvening: _autoAdvance,
        resetProgress: reset,
        switchToEvening: switchToEvening,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: palette.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Routine settings',
              style: TextStyle(
                color: palette.text,
                fontFamily: 'serif',
                fontSize: 25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            key: const Key('auto-evening-setting'),
            value: _autoAdvance,
            activeThumbColor: palette.accent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            title: Text(
              'Automatically move to Evening',
              style: TextStyle(
                color: palette.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Switch after every morning step is complete',
              style: TextStyle(color: palette.muted, fontSize: 11.5),
            ),
            onChanged: (value) => setState(() => _autoAdvance = value),
          ),
          Divider(color: palette.border),
          ListTile(
            key: const Key('reset-routine-setting'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Icon(Icons.refresh_rounded, color: palette.muted),
            title: Text(
              'Reset ${widget.period.name} progress',
              style: TextStyle(color: palette.text, fontSize: 14),
            ),
            onTap: () => _close(reset: true),
          ),
          if (widget.period == RoutinePeriod.morning)
            ListTile(
              key: const Key('go-to-evening-setting'),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(Icons.nightlight_round, color: palette.accent),
              title: Text(
                'Go to Evening now',
                style: TextStyle(color: palette.text, fontSize: 14),
              ),
              onTap: () => _close(switchToEvening: true),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              key: const Key('save-settings-button'),
              onPressed: _close,
              style: FilledButton.styleFrom(
                backgroundColor: palette.button,
                foregroundColor: palette.buttonText,
              ),
              child: const Text('Save settings'),
            ),
          ),
        ],
      ),
    );
  }
}
