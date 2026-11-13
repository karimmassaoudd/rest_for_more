import 'package:flutter/material.dart';

/// App-side extras for a focus profile that the app_blocker plugin doesn't store:
/// its icon, and whether it's one of the built-in (core) profiles.
class FocusProfileMeta {
  const FocusProfileMeta({
    required this.id,
    required this.icon,
    this.isCore = false,
  });

  /// Same id as the plugin's BlockProfile.
  final String id;
  final IconData icon;

  /// Core profiles are created on first start and can't be renamed or deleted.
  final bool isCore;
}

/// Used for profiles the user created themselves.
const defaultProfileMeta = FocusProfileMeta(id: '', icon: Icons.notes);

/// The built-in profiles. profile_bootstrap.dart creates any that are missing,
/// using the id (capitalised) as the name.
const coreProfilesMeta = [
  FocusProfileMeta(id: 'focus', icon: Icons.work_outline, isCore: true),
  FocusProfileMeta(id: 'read', icon: Icons.menu_book_outlined, isCore: true),
  FocusProfileMeta(id: 'morning', icon: Icons.wb_twilight, isCore: true),
  FocusProfileMeta(
    id: 'evening',
    icon: Icons.nights_stay_outlined,
    isCore: true,
  ),
];

/// The meta for a profile id, or [defaultProfileMeta] if it isn't a core profile.
FocusProfileMeta metaFor(String id) => coreProfilesMeta.firstWhere(
  (m) => m.id == id,
  orElse: () => defaultProfileMeta,
);
