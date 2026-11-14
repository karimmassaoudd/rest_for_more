import 'package:flutter/material.dart';

/// Search box above the app list. Reports every change to the text.
class AppSearchField extends StatelessWidget {
  const AppSearchField({super.key, required this.onSearchQueryChanged});

  final ValueChanged<String> onSearchQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search apps',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: onSearchQueryChanged,
      ),
    );
  }
}
