import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/focus/installed_apps_service.dart';
import '../../widgets/focus/app_search_field.dart';
import '../../widgets/focus/suggested_apps_button.dart';
import '../../widgets/common/rfm_app_bar.dart';
import '../../widgets/focus/timer_primary_button.dart';

/// Shared screen for picking apps from a searchable list of installed apps.
///
/// Used by both Edit Blocked Apps and Edit Always Available Apps; each one
/// passes in what is selected at first, which apps to suggest, which are
/// locked, and how to save. Closes with `true` after a successful save.
class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({
    super.key,
    required this.title,
    required this.loadInitialSelection,
    required this.suggestedPackageNames,
    required this.validateToggle,
    required this.lockedPackageNames,
    required this.onSave,
    required this.listName,
    this.lockedReason,
  });

  final String title;

  /// What the selection is called in messages: "blocked apps" or
  /// "always available apps" ("3 apps added to your blocked apps").
  final String listName;

  /// Package names that are ticked when the screen opens.
  final Future<Set<String>> Function() loadInitialSelection;

  /// Ticked by "Suggested Apps" (only the ones that are installed).
  final List<String> suggestedPackageNames;

  /// Returns an error message to show when a change isn't allowed,
  /// or null when it is.
  final String? Function(String packageName, bool wantsSelected) validateToggle;

  /// Apps whose checkbox can't be changed.
  final Set<String> lockedPackageNames;

  /// Shown under locked apps.
  final String? lockedReason;

  final Future<void> Function(Set<String> finalSelection) onSave;

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  List<AppInfo> _allApps = [];
  List<String> _installedPackageNames = [];
  Set<String> _selectedApps = {};
  String _searchQuery = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apps = await InstalledAppsService.getApps();
      final initialSelection = await widget.loadInitialSelection();
      if (!mounted) return;
      setState(() {
        _allApps = apps;
        _installedPackageNames = apps.map((app) => app.packageName).toList();
        _selectedApps = {...initialSelection};
      });
    } catch (error) {
      debugPrint('Loading apps failed: $error');
    }
  }

  /// Apps whose name contains the search text (case-insensitive).
  List<AppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) return _allApps;
    final query = _searchQuery.toLowerCase();
    return _allApps
        .where((app) => app.appName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_selectedApps);
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      debugPrint('Save failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save your changes. Try again.")),
      );
    }
  }

  /// Ticks or unticks an app, unless [AppSelectionScreen.validateToggle] says no.
  void _toggleSelection(String packageName, bool wantsSelected) {
    final error = widget.validateToggle(packageName, wantsSelected);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      if (wantsSelected) {
        _selectedApps.add(packageName);
      } else {
        _selectedApps.remove(packageName);
      }
    });
  }

  /// Ticks the suggested apps, skipping any that aren't allowed, and says
  /// how many were added (they're only kept after Save).
  void _addSuggestions(Set<String> suggested) {
    final toAdd = suggested
        .where((id) => !_selectedApps.contains(id))
        .where((id) => widget.validateToggle(id, true) == null)
        .toSet();
    setState(() => _selectedApps.addAll(toAdd));

    final count = toAdd.length;
    final String message;
    if (suggested.isEmpty) {
      message = 'None of the suggested apps are installed on this phone.';
    } else if (count == 0) {
      message = 'All suggested apps are already in your ${widget.listName}.';
    } else {
      message =
          '$count ${count == 1 ? 'app' : 'apps'} added to your '
          "${widget.listName}. Don't forget to save.";
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: count == 0
              ? null
              : SnackBarAction(label: 'Save', onPressed: _save),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Filtered once per build, not once per row.
    final apps = _filteredApps;

    // Hide the "Don't forget to save" toast when this screen closes
    // (Save, the toast's Save, or back).
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
      child: Scaffold(
        appBar: rfmScaffoldAppBar(title: widget.title),
        // Save at the bottom, like "Create Profile".
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TimerPrimaryButton(
              key: const Key('app-selection-save-button'),
              label: _saving ? 'Saving...' : 'Save',
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
        body: Column(
          children: [
            AppSearchField(
              onSearchQueryChanged: (query) =>
                  setState(() => _searchQuery = query),
            ),
            SuggestedAppsButton(
              installedPackageNames: _installedPackageNames,
              suggestedPackageNames: widget.suggestedPackageNames,
              onSuggestionsSelected: _addSuggestions,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  final isLocked = widget.lockedPackageNames.contains(
                    app.packageName,
                  );
                  return CheckboxListTile(
                    title: Text(app.appName),
                    subtitle: isLocked && widget.lockedReason != null
                        ? Text(widget.lockedReason!)
                        : null,
                    secondary: app.icon != null
                        ? Image.memory(app.icon!, width: 32, height: 32)
                        : const Icon(Icons.apps),
                    value: _selectedApps.contains(app.packageName),
                    // A null onChanged shows the checkbox as disabled.
                    onChanged: isLocked
                        ? null
                        : (value) =>
                              _toggleSelection(app.packageName, value ?? false),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
