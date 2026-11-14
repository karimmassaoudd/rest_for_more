import 'package:flutter/material.dart';

import 'session_store.dart';

/// Focus profiles can't be changed while a focus session is running,
/// because the blocker is using them at that moment.
///
/// Returns true when editing is allowed. Otherwise shows a snackbar
/// explaining why and returns false.
Future<bool> profileEditingAllowed(BuildContext context) async {
  if (!await SessionStore().isActive()) return true;
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            "Profiles can't be edited during a session. End the session first.",
          ),
        ),
      );
  }
  return false;
}
