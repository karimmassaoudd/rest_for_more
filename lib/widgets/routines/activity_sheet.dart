import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/routines/activity.dart';
import '../../models/routines/routine_time.dart';
import '../../theme/app_palette.dart';

/// Bottom sheet to add a new evening activity, or edit [activity].
///
/// Closes with the new [Activity], or nothing when dismissed.
/// The activity has to start at or before [sleepTime].
class ActivitySheet extends StatefulWidget {
  const ActivitySheet({super.key, this.activity, required this.sleepTime});

  /// Null when adding a new activity.
  final Activity? activity;

  /// "HH:mm".
  final String sleepTime;

  @override
  State<ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<ActivitySheet> {
  static const _availableIcons = [
    Icons.self_improvement_outlined,
    Icons.menu_book_outlined,
    Icons.cleaning_services_outlined,
    Icons.shower_outlined,
    Icons.music_note_outlined,
    Icons.phone_disabled_outlined,
    Icons.directions_run_outlined,
    Icons.edit_outlined,
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late TimeOfDay _selectedTime;
  late IconData _selectedIcon;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _nameController = TextEditingController(text: activity?.name ?? '');
    // "15 min" → "15"; new activities start at 10 minutes.
    _durationController = TextEditingController(
      text: activity == null ? '10' : activity.duration.split(' ').first,
    );
    _selectedTime = activity == null
        ? const TimeOfDay(hour: 21, minute: 30)
        : parseTime24h(activity.time);
    _selectedIcon = activity?.icon ?? Icons.self_improvement_outlined;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  /// Checks the input and closes the sheet with the activity.
  void _submit() {
    final name = _nameController.text.trim();
    final minutes = int.tryParse(_durationController.text.trim());

    if (name.isEmpty || minutes == null || minutes <= 0) {
      _showError('Vul een naam en geldig aantal minuten in.');
      return;
    }
    if (minutesOfDay(_selectedTime) >
        minutesOfDay(parseTime24h(widget.sleepTime))) {
      _showError(
        'De activiteit moet om ${widget.sleepTime} of eerder eindigen.',
      );
      return;
    }

    Navigator.pop(
      context,
      Activity(
        time: formatTime24h(_selectedTime),
        name: name,
        duration: '$minutes min',
        icon: _selectedIcon,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      // Moves up with the keyboard.
      padding: EdgeInsets.fromLTRB(
        23,
        16,
        23,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle.
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              _isEditing ? 'Activiteit bewerken' : 'Nieuwe activiteit',
              style: TextStyle(
                color: palette.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Naam',
                hintText: 'Bijvoorbeeld: Kleding klaarleggen',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _chooseTime,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tijdstip'),
                      child: Text(formatTime24h(_selectedTime)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Minuten',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Icoon',
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _availableIcons)
                  IconButton(
                    onPressed: () => setState(() => _selectedIcon = icon),
                    icon: Icon(icon),
                    color: icon == _selectedIcon
                        ? palette.onAccent
                        : palette.accent,
                    style: IconButton.styleFrom(
                      backgroundColor: icon == _selectedIcon
                          ? palette.accent
                          : palette.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(
                  _isEditing ? 'Wijzigingen opslaan' : 'Activiteit toevoegen',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
