import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/commonly_distracting_apps.dart';
import '../../models/focus/hard_always_available_apps.dart';
import '../../services/focus/always_available_apps_store.dart';
import 'app_selection_screen.dart'; // was '../../widgets/focus/app_selection_screen.dart'

/// Pick which apps this profile blocks during a session.
///
/// Apps that are always available in this profile (including phone and
/// messages) can't be blocked, so those are loaded first.
class EditBlockedAppsScreen extends StatefulWidget {
  const EditBlockedAppsScreen({super.key, required this.profile});

  final BlockProfile profile;

  @override
  State<EditBlockedAppsScreen> createState() => _EditBlockedAppsScreenState();
}

class _EditBlockedAppsScreenState extends State<EditBlockedAppsScreen> {
  final _blocker = AppBlocker.instance;
  final _store = AlwaysAvailableAppsStore();

  bool _loaded = false;
  Set<String> _alwaysAvailableApps = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final alwaysAvailable = await _store.getAlwaysAvailableApps(
      widget.profile.id,
    );
    if (!mounted) return;
    setState(() {
      _alwaysAvailableApps = getHardAlwaysAvailableApps(
        alwaysAvailable.toSet(),
      );
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return AppSelectionScreen(
      title: 'Edit Blocked Apps',
      loadInitialSelection: () async => widget.profile.appIdentifiers.toSet(),
      suggestedPackageNames: commonlyDistractingApps,
      validateToggle: (packageName, wantsSelected) {
        if (wantsSelected && _alwaysAvailableApps.contains(packageName)) {
          return 'This app is always available. Remove it from the always available apps first.';
        }
        return null;
      },
      lockedPackageNames: hardAlwaysAvailableApps,
      lockedReason: 'This app is always available.',
      onSave: (finalSelection) async {
        await _blocker.updateProfile(
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
