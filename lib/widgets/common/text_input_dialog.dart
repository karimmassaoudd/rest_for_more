import 'package:flutter/material.dart';

/// Shows a dialog with one text field and Cancel / [confirmLabel] buttons.
///
/// Returns the typed text (not trimmed), or null when cancelled.
/// Used for creating and renaming focus profiles.
Future<String?> showTextInputDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
  String? hint,
  bool autofocus = false,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: autofocus,
        decoration: InputDecoration(hintText: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
