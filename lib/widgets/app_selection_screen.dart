import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

import '../services/installed_apps_service.dart';

import 'app_search_field.dart';
import 'suggested_apps_button.dart';

import 'package:go_router/go_router.dart';

class AppSelectionScreen extends StatefulWidget {
  final String title;
  final Future<Set<String>> Function() loadInitialSelection;
  final List<String> suggestedPackageNames;
  final String? Function(String packageName, bool wantsSelected) validateToggle;
  final Set<String> lockedPackageNames;
  final Future<void> Function(Set<String> finalSelection) onSave;
  final String? lockedReason;

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

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  List<AppInfo> allApps = [];
  List<String> installedPackageNames = [];
  Set<String> selectedApps = {};
  String searchQuery = '';
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
        allApps = apps;
        installedPackageNames = apps.map((app) => app.packageName).toList();
        selectedApps = {...initialSelection};
      });
    } catch (error) {
      debugPrint('Loading apps failed: $error');
    }
  }

  List<AppInfo> get filteredApps {
    if (searchQuery.isEmpty) {
      return allApps;
    }
    return allApps
        .where(
          (app) =>
              app.appName.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(selectedApps);
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

  void _toggleSelection(String packageName, bool wantsSelected) {
    final error = widget.validateToggle(packageName, wantsSelected);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() {
      if (wantsSelected) {
        selectedApps.add(packageName);
      } else {
        selectedApps.remove(packageName);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onSearchQueryChanged: (query) {
              setState(() {
                searchQuery = query;
              });
            },
          ),
          SuggestedAppsButton(
            installedPackageNames: installedPackageNames,
            suggestedPackageNames: widget.suggestedPackageNames,
            onSuggestionsSelected: (suggested) {
              setState(() {
                selectedApps.addAll(
                  suggested.where(
                    (id) => widget.validateToggle(id, true) == null,
                  ),
                );
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredApps.length,
              itemBuilder: (context, index) {
                final app = filteredApps[index];
                final isSelected = selectedApps.contains(app.packageName);
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
                  value: isSelected,
                  onChanged: isLocked
                      ? null
                      : (value) {
                          _toggleSelection(app.packageName, value ?? false);
                        },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
