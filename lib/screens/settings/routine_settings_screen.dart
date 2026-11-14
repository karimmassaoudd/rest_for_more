import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The routines, opened from Settings → Edit routines; works like
/// Focus profiles.
///
/// Morning opens the morning routine, where steps are added and its
/// settings changed; Evening opens the evening editor (bedtime and
/// activities).
class RoutineSettingsScreen extends StatelessWidget {
  const RoutineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _RoutineTile(
            icon: Icons.wb_twilight_rounded,
            title: 'Morning routine',
            subtitle: 'Steps to start your day',
            onTap: () => context.push('/routine/morning'),
          ),
          _RoutineTile(
            icon: Icons.nights_stay_rounded,
            title: 'Evening routine',
            subtitle: 'Bedtime and evening activities',
            onTap: () => context.push('/settings/routines/evening'),
          ),
        ],
      ),
    );
  }
}

/// One row, styled like a profile on the Focus profiles page.
class _RoutineTile extends StatelessWidget {
  const _RoutineTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
