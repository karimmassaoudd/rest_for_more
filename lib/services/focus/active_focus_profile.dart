import 'package:app_blocker/app_blocker.dart';

import 'blocking_service.dart';
import 'session_store.dart';

/// The profile of the running focus session, or null when no session runs.
///
/// Used by main.dart when the user taps the timer notification,
/// to open the countdown for that profile.
Future<BlockProfile?> loadActiveFocusProfile() async {
  final store = SessionStore();
  if (!await store.isActive()) return null;
  final profileId = await store.profileId();
  if (profileId == null || profileId.isEmpty) return null;
  return BlockingService().latestProfile(profileId);
}
