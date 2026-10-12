import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

import '../models/hard_always_available_apps.dart';
import 'always_available_apps_store.dart';
import 'session_store.dart';
import '../widgets/permission_dialog.dart';

class BlockingService {
  final blocker = AppBlocker.instance;
  final _session = SessionStore();
  final _alwaysAvailableStore = AlwaysAvailableAppsStore();

  Future<void> configureBlockScreen(String profileName) async {
    await blocker.setBlockScreenConfig(
      BlockScreenConfig(
        title: '{appName} app is blocked',
        subtitle: '$profileName session in progress',
        timerLabel: '{timeLeft} remaining',
        backgroundColor: const Color.fromARGB(255, 82, 33, 6),
        returnHomeButtonText: 'Return to Home',
        emergencyButtonText: 'Emergency Unlock',
      ),
    );
  }

  Future<bool> ensurePermission(BuildContext context) async {
    final status = await blocker.checkPermission();
    if (status == BlockerPermissionStatus.granted) return true;

    if (!context.mounted) return false;
    final allowed = await showPermissionDialog(
      context,
      icon: Icons.security,
      title: 'App blocking',
      message: 'Rest For More needs access to block distracting apps during your session.',
    );
    if (!allowed) return false;

    await blocker.requestPermission();
    final newStatus = await blocker.checkPermission();
    return newStatus == BlockerPermissionStatus.granted;
  }

  Future<void> startBlocking(BlockProfile profile) async {
    await configureBlockScreen(profile.name);

    final stored = await _alwaysAvailableStore.getAlwaysAvailableApps(
      profile.id,
    );
    final protectedApps = getHardAlwaysAvailableApps(stored.toSet());
    final toBlock = profile.appIdentifiers
        .where((id) => !protectedApps.contains(id))
        .toList();

    await blocker.blockApps(toBlock);
  }

  Future<void> stopBlocking() async {
    try {
      await blocker.unblockAll();
    } finally {
      await _session.clear();
    }
  }
}
