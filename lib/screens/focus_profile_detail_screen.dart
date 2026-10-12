import 'package:flutter/material.dart';
import 'package:app_blocker/app_blocker.dart';

import '../services/installed_apps_service.dart';

import '../models/focus_profile_meta.dart';
import '../services/always_available_apps_store.dart';
import '../models/hard_always_available_apps.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../widgets/confirm_dialog.dart';
import '../services/profile_events.dart';

import 'package:go_router/go_router.dart';

class FocusProfileDetailScreen extends StatefulWidget {
  final BlockProfile profile;

  const FocusProfileDetailScreen({super.key, required this.profile});

  @override
  State<FocusProfileDetailScreen> createState() =>
      _FocusProfileDetailScreenState();
}

class _FocusProfileDetailScreenState extends State<FocusProfileDetailScreen> {
  final blocker = AppBlocker.instance;
  final store = AlwaysAvailableAppsStore();
  List<AppInfo> allApps = [];
  Set<String> alwaysAvailableApps = {};
  late BlockProfile currentProfile;

  @override
  void initState() {
    super.initState();
    currentProfile = widget.profile;
    _loadData();
  }

  Future<void> _loadData() async {
    final apps = await InstalledAppsService.getApps();
    final alwaysAvailable = await store.getAlwaysAvailableApps(
      currentProfile.id,
    );

    if (!mounted) return;

    setState(() {
      allApps = apps;
      alwaysAvailableApps = getHardAlwaysAvailableApps(alwaysAvailable.toSet());
    });
  }

  List<AppInfo> _resolveApps(List<String> packageNames) {
    return allApps
        .where((app) => packageNames.contains(app.packageName))
        .toList();
  }

  Future<void> _refreshProfile() async {
    final all = await blocker.getProfiles();
    final updated = all.firstWhere(
      (p) => p.id == currentProfile.id,
      orElse: () => currentProfile,
    );

    if (!mounted) return;

    setState(() {
      currentProfile = updated;
    });
  }

  Future<void> _loadAlwaysAvailableApps() async {
    final alwaysAvailable = await store.getAlwaysAvailableApps(
      currentProfile.id,
    );

    if (!mounted) return;

    setState(() {
      alwaysAvailableApps = getHardAlwaysAvailableApps(alwaysAvailable.toSet());
    });
  }

  Future<void> _renameProfile() async {
    final meta = metaFor(currentProfile.id);

    if (meta.isCore) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Core profiles cannot be renamed')),
        );
      }
      return;
    }

    final controller = TextEditingController(text: currentProfile.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Profile'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    await blocker.updateProfile(
      BlockProfile(
        id: currentProfile.id,
        name: newName.trim(),
        appIdentifiers: currentProfile.appIdentifiers,
      ),
    );

    profilesChanged.value++;

    await _refreshProfile();
  }

  Future<void> _deleteProfile() async {
    final meta = metaFor(currentProfile.id);

    if (meta.isCore) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${currentProfile.name} is built into Rest For More and can\'t be deleted. You can still customize which apps it blocks.',
            ),
          ),
        );
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete profile?',
      message:
          'This will permanently delete the ${currentProfile.name} profile. '
          'Are you sure?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
    );
    if (!confirmed || !mounted) return;

    await blocker.deleteProfile(currentProfile.id);
    await store.removeProfile(currentProfile.id);

    profilesChanged.value++;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildAppCard(List<AppInfo> apps) {
    return Column(
      children: apps.map((app) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: app.icon != null
                ? Image.memory(app.icon!, width: 32, height: 32)
                : const Icon(Icons.apps),
            title: Text(app.appName),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blockedApps = _resolveApps(currentProfile.appIdentifiers);
    final resolvedAlwaysAvailableApps = _resolveApps(
      alwaysAvailableApps.toList(),
    );
    final meta = metaFor(currentProfile.id);

    return Scaffold(
      appBar: AppBar(title: Text(currentProfile.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Icon(meta.icon, size: 40, color: AppColors.mediumbrown),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentProfile.name,
                  style: AppFonts.cormorant(size: 24, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _renameProfile,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteProfile,
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Blocked apps · ${blockedApps.length} blocked',
                  style: AppFonts.manrope(size: 15, weight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final changed = await context.push<bool>(
                    '/settings/focus-profiles/detail/blocked-apps',
                    extra: currentProfile,
                  );
                  if (changed == true) {
                    await _refreshProfile();

                    profilesChanged.value++;

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Blocked apps updated successfully'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('edit'),
              ),
            ],
          ),
          _buildAppCard(blockedApps),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Always available apps · ${resolvedAlwaysAvailableApps.length} available',
                  style: AppFonts.manrope(size: 15, weight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final changed = await context.push<bool>(
                    '/settings/focus-profiles/detail/always-available',
                    extra: currentProfile,
                  );
                  if (changed == true) {
                    await _loadAlwaysAvailableApps();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Always available apps updated successfully',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text('edit'),
              ),
            ],
          ),
          _buildAppCard(resolvedAlwaysAvailableApps),
        ],
      ),
    );
  }
}
