import 'package:flutter/material.dart';

/// Explains why a permission is needed before the system screen opens.
/// Returns true if the user taps [allowLabel].
///
/// [messageAlign]: use TextAlign.start for messages with numbered steps.
Future<bool> showPermissionDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  String allowLabel = 'Allow',
  String denyLabel = "Don't Allow",
  TextAlign messageAlign = TextAlign.center,
}) async {
  final allowed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(message, textAlign: messageAlign),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(denyLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(allowLabel),
        ),
      ],
    ),
  );
  return allowed == true;
}
