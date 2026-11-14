import 'package:flutter/material.dart';

/// "Suggested Apps" button above the app list.
/// Hands back the suggested apps that are actually installed on this phone.
class SuggestedAppsButton extends StatelessWidget {
  const SuggestedAppsButton({
    super.key,
    required this.installedPackageNames,
    required this.suggestedPackageNames,
    required this.onSuggestionsSelected,
  });

  final List<String> installedPackageNames;
  final List<String> suggestedPackageNames;
  final ValueChanged<Set<String>> onSuggestionsSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          final installed = installedPackageNames.toSet();
          onSuggestionsSelected(
            suggestedPackageNames.where(installed.contains).toSet(),
          );
        },
        child: const Text('Suggested Apps'),
      ),
    );
  }
}
