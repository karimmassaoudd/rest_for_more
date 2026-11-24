import 'dart:async';
import 'dart:io';

import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';

import '../../models/focus/hard_always_available_apps.dart';
import '../../theme/app_colors.dart';
import '../../widgets/focus/permission_dialog.dart';
import 'always_available_apps_store.dart';
import 'blocker_permissions.dart';
import 'session_store.dart';
import 'timer_notification_service.dart';

/// Talks to the app_blocker plugin: asks for permission, and starts and
/// stops blocking a profile's apps.
class BlockingService {
  final _blocker = AppBlocker.instance;
  final _session = SessionStore();
  final _alwaysAvailableStore = AlwaysAvailableAppsStore();

  /// Makes sure apps can be blocked, explaining each step first.
  /// Returns true when blocking is allowed.
  ///
  /// Android has two separate switches (accessibility, exact alarms), each
  /// on its own settings page; iOS has a single system prompt.
  Future<bool> ensurePermission(BuildContext context) async {
    if (await _blocker.checkPermission() == BlockerPermissionStatus.granted) {
      return true;
    }

    if (!Platform.isAndroid) {
      await _blocker.requestPermission();
      return await _blocker.checkPermission() ==
          BlockerPermissionStatus.granted;
    }

    if (!await BlockerPermissions.accessibilityOn()) {
      if (!context.mounted) return false;
      final ok = await showPermissionDialog(
        context,
        icon: Icons.security,
        title: 'Turn on app blocking',
        message:
            'Rest For More blocks distracting apps during your sessions. '
            'To turn this on:\n\n'
            '1. Tap Installed apps\n'
            '2. Tap Rest For More\n'
            '3. Turn the switch on',
        allowLabel: 'Open settings',
        denyLabel: 'Not now',
        messageAlign: TextAlign.start,
      );
      if (!ok) return false;
      await BlockerPermissions.openAccessibility();
      await _waitUntilBack();
      if (!await BlockerPermissions.accessibilityOn()) return false;
    }

    if (!await BlockerPermissions.exactAlarmOn()) {
      if (!context.mounted) return false;
      final ok = await showPermissionDialog(
        context,
        icon: Icons.alarm,
        title: 'Keep your timing exact',
        message:
            'So your breaks and sessions end right on time, '
            'Rest For More needs to set alarms.\n\n'
            'On the next screen, turn on the switch for Rest For More.',
        allowLabel: 'Open settings',
        denyLabel: 'Not now',
        messageAlign: TextAlign.start,
      );
      if (!ok) return false;
      await BlockerPermissions.openExactAlarm();
      await _waitUntilBack();
    }

    return await _blocker.checkPermission() == BlockerPermissionStatus.granted;
  }

  /// Asks for notifications: the time left in the notification shade and
  /// the time's-up sound. Starting still works when the user says no.
  Future<void> ensureNotifications(BuildContext context) async {
    final alerts = TimerNotificationService.instance;
    if (await alerts.hasPermission()) return;
    if (!context.mounted) return;
    final ok = await showPermissionDialog(
      context,
      icon: Icons.notifications_active_outlined,
      title: 'Show your timer',
      message:
          'Rest For More shows the time left in your notifications and '
          'lets you know when the time is up.',
      allowLabel: 'Allow',
      denyLabel: 'Not now',
    );
    if (ok) await alerts.requestPermission();
  }

  /// Waits until the user comes back to the app from the settings screen
  /// (gives up after 5 minutes).
  Future<void> _waitUntilBack() {
    final done = Completer<void>();
    late final AppLifecycleListener listener;
    listener = AppLifecycleListener(
      onResume: () {
        listener.dispose();
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(
      const Duration(minutes: 5),
      onTimeout: listener.dispose,
    );
  }

  /// The profile as it's saved now (e.g. right after its apps were edited),
  /// or null if it can't be found.
  Future<BlockProfile?> latestProfile(String id) async {
    try {
      for (final profile in await _blocker.getProfiles()) {
        if (profile.id == id) return profile;
      }
    } catch (error) {
      debugPrint('Loading profile $id failed: $error');
    }
    return null;
  }

  /// Blocks the profile's apps, except the always-available ones.
  /// Routines pass their own block-screen texts.
  Future<void> startBlocking(BlockProfile profile, {String? subtitle}) async {
    await _configureBlockScreen(
      subtitle: subtitle ?? '${profile.name} session in progress',
    );

    // The apps as saved now: they may have changed since the screen opened.
    final current = await latestProfile(profile.id) ?? profile;
    final stored = await _alwaysAvailableStore.getAlwaysAvailableApps(
      profile.id,
    );
    final protectedApps = getHardAlwaysAvailableApps(stored.toSet());
    final toBlock = current.appIdentifiers
        .where((id) => !protectedApps.contains(id))
        .toList();

    await _blocker.blockApps(toBlock);
  }

  /// Unblocks everything and forgets the session, even if unblocking fails.
  Future<void> stopBlocking() async {
    try {
      await _blocker.unblockAll();
    } finally {
      await _session.clear();
    }
  }

  /// Routines: unblocks everything but leaves the focus session alone.
  Future<void> unblockApps() => _blocker.unblockAll();

  /// Routines: changes the block-screen subtitle while blocking.
  Future<void> updateBlockScreen({required String subtitle}) =>
      _configureBlockScreen(subtitle: subtitle);

  /// The screen shown when the user opens a blocked app.
  /// {appName} and {timeLeft} are filled in by the plugin. The background
  /// stays dark brown in both themes: the plugin draws it natively.
  Future<void> _configureBlockScreen({required String subtitle}) async {
    await _blocker.setBlockScreenConfig(
      BlockScreenConfig(
        title: '{appName} app is blocked',
        subtitle: subtitle,
        timerLabel: 'Apps unlock in {timeLeft}',
        backgroundColor: AppColors.darkBrown,
        returnHomeButtonText: 'Return to home',
        emergencyButtonText: 'Emergency unlock',
      ),
    );
  }
}
