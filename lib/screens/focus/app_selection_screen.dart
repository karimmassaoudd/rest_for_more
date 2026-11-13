import 'package:app_blocker/app_blocker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/focus/installed_apps_service.dart'; // unchanged
import '../../widgets/focus/app_search_field.dart'; // was 'app_search_field.dart'
import '../../widgets/focus/suggested_apps_button.dart'; // was 'suggested_apps_button.dart'

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
    this.lockedReason,
  });

  final String title;

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

  /// Ticks the suggested apps, skipping any that aren't allowed.
  void _addSuggestions(Set<String> suggested) {
    setState(() {
      _selectedApps.addAll(
        suggested.where((id) => widget.validateToggle(id, true) == null),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtered once per build, not once per row.
    final apps = _filteredApps;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _save,
          ),
        ],
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
    );
  }
}
