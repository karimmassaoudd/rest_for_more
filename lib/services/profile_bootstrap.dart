import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/foundation.dart';

import '../models/focus_profile_meta.dart';

Future<void> ensureCoreProfiles() async {
  try {
    final blocker = AppBlocker.instance;
    final existingProfiles = await blocker.getProfiles();
    final existingProfileIds = existingProfiles
        .map((profile) => profile.id)
        .toSet();

    for (final meta in coreProfilesMeta) {
      if (!existingProfileIds.contains(meta.id)) {
        await blocker.createProfile(
          BlockProfile(
            id: meta.id,
            name: meta.id[0].toUpperCase() + meta.id.substring(1),
            appIdentifiers: [],
          ),
        );
      }
    }
  } catch (error) {
    debugPrint('Error ensuring core profiles: $error');
  }
}
