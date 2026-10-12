import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

import '../widgets/app_selection_screen.dart';
import '../services/always_available_apps_store.dart';
import '../models/commonly_distracting_apps.dart';
import '../models/hard_always_available_apps.dart';

class EditBlockedAppsScreen extends StatefulWidget {
  final BlockProfile profile;

  const EditBlockedAppsScreen({super.key, required this.profile});

  @override
  State<EditBlockedAppsScreen> createState() => _EditBlockedAppsScreenState();
}

class _EditBlockedAppsScreenState extends State<EditBlockedAppsScreen> {
  final blocker = AppBlocker.instance;
  bool loaded = false;
  final store = AlwaysAvailableAppsStore();
  Set<String> alwaysAvailableApps = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final alwaysAvailable = await store.getAlwaysAvailableApps(
      widget.profile.id,
    );

    if (!mounted) return;

    setState(() {
      alwaysAvailableApps = getHardAlwaysAvailableApps(alwaysAvailable.toSet());
      loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppSelectionScreen(
      title: 'Edit Blocked Apps',
      loadInitialSelection: () async => widget.profile.appIdentifiers.toSet(),
      suggestedPackageNames: commonlyDistractingApps,
      validateToggle: (packageName, wantsSelected) {
        if (wantsSelected && alwaysAvailableApps.contains(packageName)) {
          return 'This app is always available. Remove it from the always available apps first.';
        }
        return null;
      },
      lockedPackageNames: hardAlwaysAvailableApps,
      lockedReason: 'This app is always available.',
      onSave: (finalSelection) async {
        await blocker.updateProfile(
          BlockProfile(
            id: widget.profile.id,
            name: widget.profile.name,
            appIdentifiers: finalSelection.toList(),
          ),
        );
      },
    );
  }
}
