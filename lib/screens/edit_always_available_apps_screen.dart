import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

import '../models/commonly_needed_apps.dart';
import '../services/always_available_apps_store.dart';
import '../models/hard_always_available_apps.dart';
import '../widgets/app_selection_screen.dart';

class EditAlwaysAvailableAppsScreen extends StatelessWidget {
  final BlockProfile profile;
  final store = AlwaysAvailableAppsStore();

  EditAlwaysAvailableAppsScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
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
