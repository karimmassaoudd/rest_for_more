import 'package:app_blocker/app_blocker.dart';

import 'session_store.dart';

/// The profile of the running focus session, or null when no session runs.
///
/// Used by main.dart when the user taps the timer notification,
/// to open the countdown for that profile.
Future<BlockProfile?> loadActiveFocusProfile() async {
  final store = SessionStore();
  if (!await store.isActive()) return null;

  // Saved when the session started.
  final profileId = await store.profileId();
  if (profileId == null || profileId.isEmpty) return null;

  final profiles = await AppBlocker.instance.getProfiles();
  for (final profile in profiles) {
    if (profile.id == profileId) return profile;
  }
  return null;
}
