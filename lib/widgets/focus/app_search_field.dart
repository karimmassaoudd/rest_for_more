import 'package:flutter/material.dart';

class AppSearchField extends StatelessWidget {
  final ValueChanged<String> onSearchQueryChanged;
  const AppSearchField({super.key, required this.onSearchQueryChanged});

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
