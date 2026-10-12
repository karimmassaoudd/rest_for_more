import 'package:flutter/material.dart';

class FocusProfileMeta {
  final String id;
  final IconData icon;
  final List<String> alwaysAvailableApps;
  final bool isCore;

  const FocusProfileMeta({
    required this.id,
    required this.icon,
    required this.alwaysAvailableApps,
    this.isCore = false,
  });
}

const FocusProfileMeta defaultProfileMeta = FocusProfileMeta(
  id: '',
  icon: Icons.notes,
  alwaysAvailableApps: [],
  isCore: false,
);

const List<FocusProfileMeta> coreProfilesMeta = [
  FocusProfileMeta(
    id: 'focus',
    icon: Icons.work_outline,
    alwaysAvailableApps: [],
    isCore: true,
  ),
  FocusProfileMeta(
    id: 'read',
    icon: Icons.menu_book_outlined,
    alwaysAvailableApps: [],
    isCore: true,
  ),
  FocusProfileMeta(
    id: 'morning',
    icon: Icons.wb_twilight,
    alwaysAvailableApps: [],
    isCore: true,
  ),
  FocusProfileMeta(
    id: 'evening',
    icon: Icons.nights_stay_outlined,
    alwaysAvailableApps: [],
    isCore: true,
  ),
];

/// The meta for a profile id, or the default one if it isn't a core profile.
FocusProfileMeta metaFor(String id) => coreProfilesMeta.firstWhere(
  (m) => m.id == id,
  orElse: () => defaultProfileMeta,
);
