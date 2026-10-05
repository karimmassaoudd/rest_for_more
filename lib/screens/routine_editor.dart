import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/Save_activities.dart';
import '../models/activity.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _Design.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _Design.accent,
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
      ),
      home: const EveningPage(),
    );
  }
}

class _Design {
  static const background = Color(0xFFF9F8F5);
  static const surface = Color(0xFFEDE8DC);
  static const ink = Color(0xFF55463E);
  static const muted = Color(0xFFA67D65);
  static const accent = Color(0xFF855B40);
  static const outline = Color(0xFFD2B095);
}

class EveningPage extends StatefulWidget {
  const EveningPage({super.key});

  @override
  State<EveningPage> createState() => _RoutinePage();
}

class _RoutinePage extends State<EveningPage> {
  final activities = getActivities();

  List<Activity> get displayedActivities {
    final sortedActivities = [...activities];
    sortedActivities.sort((a, b) {
      final aIsSleep = a.time == routineSleepTime;
      final bIsSleep = b.time == routineSleepTime;

      if (aIsSleep && !bIsSleep) return 1;
      if (!aIsSleep && bIsSleep) return -1;
      return a.time.compareTo(b.time);
    });
    return sortedActivities;
  }

  Future<void> _addActivity() async {
    final activity = await showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Design.background,
      builder: (_) => const _ActivitySheet(),
    );

    if (activity != null && mounted) {
      setState(() {
        activities.add(activity);
      });
    }
  }

  Future<void> _editActivity(Activity sourceActivity) async {
    final updatedActivity = await showModalBottomSheet<Activity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Design.background,
      builder: (_) => _ActivitySheet(activity: sourceActivity),
    );

    if (updatedActivity != null && mounted) {
      setState(() {
        final index = activities.indexOf(sourceActivity);
        if (index != -1) activities[index] = updatedActivity;
      });
    }
  }

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
                    const _SleepSummary(sleepTime: routineSleepTime),
                    const SizedBox(height: 21),
                    Text(
                      'JOUW AVOND',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color.fromARGB(133, 91, 64, 1),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...displayedActivities.map(
                      (activity) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: _ActivityTile(
                            time: activity.time,
                            title: activity.name,
                            duration: activity.duration,
                            icon: activity.icon,
                            onEdit: () => _editActivity(activity),
                            onDelete: () {
                              setState(() {
                                activities.remove(activity);
                              });
                            },
                          ),
                        );
                      },
                    )
                    // const _SleepTile(),
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
                  _FilledAction(label: 'Routine opslaan'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//top bar with back button and title
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.arrow_back, size: 19, color: _Design.ink),
        const SizedBox(width: 25),
        const Text(
          'Avond',
          style: TextStyle(
            color: Color.fromARGB(133, 91, 64, 1),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const Icon(Icons.more_vert, size: 21, color: _Design.ink),
      ],
    );
  }
}

//top bar with time
class _SleepSummary extends StatelessWidget {
  const _SleepSummary({required this.sleepTime});

  final String sleepTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
      decoration: BoxDecoration(
        color: _Design.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.nightlight_round, size: 14, color: _Design.muted),
              const SizedBox(width: 9),
              Text(
                'IK WIL SLAPEN OM',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _Design.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            sleepTime,
            style: TextStyle(
              color: _Design.ink,
              fontFamily: 'Georgia',
              fontSize: 20,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Je avond begint om 21:30 · 1 uur',
            style: TextStyle(color: _Design.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

//list of activities with time, title, duration and icon
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.onEdit,
    required this.onDelete,
    required this.time,
    required this.title,
    required this.duration,
    required this.icon,
  });

  final String time;
  final String title;
  final String duration;
  final IconData icon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 61,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _Design.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              time,
              style: const TextStyle(
                color: _Design.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(icon, size: 16, color: _Design.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _Design.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  duration,
                  style: const TextStyle(color: _Design.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: _Design.muted),
            padding: EdgeInsets.zero,
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 17),
                    SizedBox(width: 10),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 17),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivitySheet extends StatefulWidget {
  const _ActivitySheet({this.activity});

  final Activity? activity;

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  late final TextEditingController nameController;
  late final TextEditingController durationController;
  late TimeOfDay selectedTime;
  late IconData selectedIcon;

  bool get isEditing => widget.activity != null;

  static const availableIcons = [
    Icons.self_improvement_outlined,
    Icons.menu_book_outlined,
    Icons.cleaning_services_outlined,
    Icons.shower_outlined,
    Icons.music_note_outlined,
    Icons.phone_disabled_outlined,
    Icons.directions_run_outlined,
    Icons.edit_outlined,
  ];

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    nameController = TextEditingController(text: activity?.name ?? '');
    durationController = TextEditingController(
      text: activity == null ? '10' : activity.duration.split(' ').first,
    );
    selectedTime = activity == null
        ? const TimeOfDay(hour: 21, minute: 30)
        : _parseTime(activity.time);
    selectedIcon = activity?.icon ?? Icons.self_improvement_outlined;
  }

  Future<void> _chooseTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  void _add() {
    final name = nameController.text.trim();
    final minutes = int.tryParse(durationController.text.trim());

    if (name.isEmpty || minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul een naam en geldig aantal minuten in.')),
      );
      return;
    }

    if (_minutesFromTime(selectedTime) > _minutesFromTime(_parseTime(routineSleepTime))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('De activiteit moet om $routineSleepTime of eerder eindigen.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Activity(
        time: _formatMilitaryTime(selectedTime),
        name: name,
        duration: '$minutes min',
        icon: selectedIcon,
      ),
    );
  }

  String _formatMilitaryTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  int _minutesFromTime(TimeOfDay time) => time.hour * 60 + time.minute;

  @override
  void dispose() {
    nameController.dispose();
    durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _Design.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              isEditing ? 'Activiteit bewerken' : 'Nieuwe activiteit',
              style: const TextStyle(
                color: _Design.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Naam',
                hintText: 'Bijvoorbeeld: Kleding klaarleggen',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _chooseTime,
                    borderRadius: BorderRadius.circular(4),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tijdstip',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatMilitaryTime(selectedTime)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Minuten',
                      suffixText: 'min',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Icoon',
              style: TextStyle(
                color: _Design.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIcons.map((icon) {
                final isSelected = icon == selectedIcon;
                return IconButton(
                  onPressed: () => setState(() => selectedIcon = icon),
                  icon: Icon(icon),
                  color: isSelected ? Colors.white : _Design.accent,
                  style: IconButton.styleFrom(
                    backgroundColor: isSelected ? _Design.accent : _Design.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _add,
                style: FilledButton.styleFrom(
                  backgroundColor: _Design.accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text(isEditing ? 'Wijzigingen opslaan' : 'Activiteit toevoegen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//Add button
class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 39,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _Design.accent,
          side: const BorderSide(color: _Design.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
//start session button
class _FilledAction extends StatelessWidget {
  const _FilledAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 41,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _Design.accent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}