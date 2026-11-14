import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/focus/profile_edit_guard.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';
import '../../widgets/common/settings_tile.dart';

/// The "Settings" tab: entry points for editing focus profiles and routines.
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
              style: AppFonts.manrope(size: 15, color: context.palette.muted),
            ),
            const SizedBox(height: 24),
            SettingsTile(
              icon: Icons.layers_outlined,
              title: 'Edit profiles',
              subtitle: 'Create, rename and edit your focus profiles',
              onTap: () async {
                // Blocked while a focus session is running (shows a snackbar).
                if (!await profileEditingAllowed(context)) return;
                if (!context.mounted) return;
                context.push('/settings/focus-profiles');
              },
            ),
            SettingsTile(
              icon: Icons.nights_stay_outlined,
              title: 'Edit routines',
              subtitle: 'Manage your morning and evening routines',
              onTap: () => context.push('/settings/routines'),
            ),
          ],
        ),
      ),
    );
  }
}
