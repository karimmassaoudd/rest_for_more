import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/focus_profile_meta.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_palette.dart';

/// One tappable row in the Home profile list:
/// profile icon, name, number of blocked apps and a chevron.
class FocusProfileTile extends StatelessWidget {
  const FocusProfileTile({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final BlockProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = metaFor(profile.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(meta.icon, size: 32, color: context.palette.accent),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: AppFonts.manrope(
                          size: 18,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${profile.appIdentifiers.length} apps blocked',
                        style: AppFonts.manrope(
                          size: 13,
                          color: context.palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.palette.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
