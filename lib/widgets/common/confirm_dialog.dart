import 'package:flutter/material.dart';

/// Red used for destructive actions (same as the error red on the auth screens).
const _destructiveRed = Color(0xFFB0473A);

/// Shows a confirm / cancel dialog. Returns true only if the user confirms.
/// Styling comes from the app theme (dialogTheme and the button themes).
/// [destructive]: red confirm button, e.g. "Delete account".
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          style: destructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: _destructiveRed,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
