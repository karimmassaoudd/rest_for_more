import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/settings_tile.dart';
import '../services/session_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Settings',
              style: AppFonts.cormorant(size: 28, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage how Rest For More works for you',
              style: AppFonts.cormorant(size: 15, color: AppColors.lightbrown),
            ),
            const SizedBox(height: 24),
            SettingsTile(
              icon: Icons.layers_outlined,
              title: 'Focus profiles',
              subtitle: 'Create, rename and edit your profiles',
              onTap: () async {
                if (await SessionStore().isActive()) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Profiles can't be edited during a session. End the session first.",
                        ),
                      ),
                    );
                  return;
                }
                if (!context.mounted) return;
                context.push('/settings/focus-profiles');
              },
            ),
            SettingsTile(
              icon: Icons.nights_stay_outlined,
              title: 'Edit routines',
              subtitle: 'Set your bedtime and evening steps',
              onTap: () => context.push('/settings/routines'),
            ),
          ],
        ),
      ),
    );
  }
}
