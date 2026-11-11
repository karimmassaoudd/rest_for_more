import 'package:app_blocker/app_blocker.dart';

import 'session_store.dart';

/// Returns the profile for the currently running focus session.
Future<BlockProfile?> loadActiveFocusProfile() async {
  final store = SessionStore();

  // Only navigate if there is an active session.
  if (!await store.isActive()) {
    return null;
  }

  // Retrieve the profile ID saved when the timer started.
  final profileId = await store.profileId();

  if (profileId == null || profileId.isEmpty) {
    return null;
  }

  // Load profiles from the same storage your app already uses.
  final profiles = await AppBlocker.instance.getProfiles();

  for (final profile in profiles) {
    if (profile.id == profileId) {
      return profile;
    }
  }

  return null;
}
