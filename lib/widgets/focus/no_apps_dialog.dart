import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/focus/blocking_service.dart';

/// Before a focus session or a routine starts: if its profile doesn't block
/// any apps yet, says so and offers to choose apps first.
///
/// Returns true to start now: the profile has apps, "Start anyway", or
/// "Choose apps" and the user saved at least one app. Closing the dialog,
/// or coming back from Edit blocked apps without apps, returns false.
Future<bool> confirmBlockedApps(
  BuildContext context,
  String profileId, {
  required String sessionName,
}) async {
  final profile = await BlockingService().latestProfile(profileId);
  if (profile == null || profile.appIdentifiers.isNotEmpty) return true;
  if (!context.mounted) return false;

  final choice = await showDialog<_NoAppsChoice>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.block_rounded),
      title: const Text('No apps blocked yet'),
      content: Text(
        "Your $sessionName doesn't block any apps yet, so nothing will be "
        'blocked. Choose the apps you want to put away first?',
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          key: const Key('no-apps-start-anyway'),
          onPressed: () => Navigator.of(context).pop(_NoAppsChoice.startAnyway),
          child: const Text('Start anyway'),
        ),
        ElevatedButton(
          key: const Key('no-apps-choose'),
          onPressed: () => Navigator.of(context).pop(_NoAppsChoice.chooseApps),
          child: const Text('Choose apps'),
        ),
      ],
    ),
  );

  switch (choice) {
    case _NoAppsChoice.startAnyway:
      return true;
    case _NoAppsChoice.chooseApps:
      if (!context.mounted) return false;
      await context.push<bool>(
        '/settings/focus-profiles/detail/blocked-apps',
        extra: profile,
      );
      // Back from Edit blocked apps: carry on if apps were chosen.
      final updated = await BlockingService().latestProfile(profileId);
      return updated != null && updated.appIdentifiers.isNotEmpty;
    case null:
      return false; // dialog closed: don't start
  }
}

enum _NoAppsChoice { chooseApps, startAnyway }
