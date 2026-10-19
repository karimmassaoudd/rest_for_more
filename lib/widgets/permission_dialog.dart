import 'package:flutter/material.dart';

/// Plain Material dialog for permissions. Returns true if the user agrees.
Future<bool> showPermissionDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) async {
  final allowed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Don't Allow"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Allow'),
        ),
      ],
    ),
  );
  return allowed == true;
}
