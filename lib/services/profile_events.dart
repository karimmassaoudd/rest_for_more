import 'package:flutter/foundation.dart';

/// Bumped whenever the profile list may have changed,
/// so other tabs know to reload it.
final ValueNotifier<int> profilesChanged = ValueNotifier<int>(0);
