import 'package:flutter/material.dart';

class SuggestedAppsButton extends StatelessWidget {
  final List<String> installedPackageNames;
  final List<String> suggestedPackageNames;
  final ValueChanged<Set<String>> onSuggestionsSelected;

  const SuggestedAppsButton({
    super.key,
    required this.installedPackageNames,
    required this.suggestedPackageNames,
    required this.onSuggestionsSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          final installed = installedPackageNames.toSet();
          final suggested = suggestedPackageNames
              .where((id) => installed.contains(id))
              .toSet();
          onSuggestionsSelected(suggested);
        },
        child: const Text('Suggested Apps'),
      ),
    );
  }
}
