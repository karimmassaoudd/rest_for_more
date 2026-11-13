import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/foundation.dart';

import '../../models/focus/focus_profile_meta.dart';

/// Creates any built-in profile (Focus, Read, Morning, Evening) that doesn't
/// exist yet, with no blocked apps. Called on every start in main.dart;
/// existing profiles are left alone.
Future<void> ensureCoreProfiles() async {
  try {
    final blocker = AppBlocker.instance;
    final existingIds = (await blocker.getProfiles()).map((p) => p.id).toSet();

    for (final meta in coreProfilesMeta) {
      if (existingIds.contains(meta.id)) continue;
      await blocker.createProfile(
        BlockProfile(
          id: meta.id,
          // "focus" → "Focus"
          name: meta.id[0].toUpperCase() + meta.id.substring(1),
          appIdentifiers: [],
        ),
      );
    }
  } catch (error) {
    debugPrint('Error ensuring core profiles: $error');
  }
}
