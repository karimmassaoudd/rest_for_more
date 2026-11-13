import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/commonly_needed_apps.dart';
import '../../models/focus/hard_always_available_apps.dart';
import '../../services/focus/always_available_apps_store.dart';
import 'app_selection_screen.dart'; // was '../../widgets/focus/app_selection_screen.dart'

/// Pick which apps stay usable while this profile's session is running.
///
/// The phone and messages apps are always included and can't be turned off.
/// An app can't be both blocked and always available in the same profile.
class EditAlwaysAvailableAppsScreen extends StatelessWidget {
  const EditAlwaysAvailableAppsScreen({super.key, required this.profile});

  final BlockProfile profile;

  @override
  Widget build(BuildContext context) {
    final store = AlwaysAvailableAppsStore();

    return AppSelectionScreen(
      title: 'Edit Always Available Apps',
      loadInitialSelection: () async {
        final alwaysAvailable = await store.getAlwaysAvailableApps(profile.id);
        return getHardAlwaysAvailableApps(alwaysAvailable.toSet());
      },
      suggestedPackageNames: commonlyNeededApps,
      validateToggle: (packageName, wantsSelected) {
        if (wantsSelected && profile.appIdentifiers.contains(packageName)) {
          return 'This app is blocked in this profile. Remove it from the blocked apps first.';
        }
        return null;
      },
      lockedPackageNames: hardAlwaysAvailableApps,
      lockedReason: 'Required: calls and messages stay available.',
      onSave: (finalSelection) async {
        await store.setAlwaysAvailableApps(profile.id, finalSelection.toList());
      },
    );
  }
}
